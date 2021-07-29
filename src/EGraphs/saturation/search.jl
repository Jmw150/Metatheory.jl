struct Match
    rule::AbstractRule 
    # the rhs pattern to instantiate 
    pat_to_inst::Union{Nothing,Pattern}
    # the substitution
    sub::Sub 
    # the id the matched the lhs  
    id::EClassId
end

const MatchesBuf = Vector{Match}

function cached_ids(g::EGraph, p::Pattern)# ::Vector{Int64}
    keys(g.classes)
end

# FIXME 
function cached_ids(g::EGraph, p::PatTerm)
    # println("pattern $p, $(p.head)")
    # println("all ids")
    # keys(g.classes) |> println
    # println("cached symbols")
    # cached = get(g.symcache, p.head, Set{Int64}())
    # println("symbols where $(p.head) appears")
    # appears = Set{Int64}() 
    # for (id, class) ∈ g.classes 
    #     for n ∈ class 
    #         if n.head == p.head
    #             push!(appears, id) 
    #         end
    #     end
    # end
    # # println(appears)
    # if !(cached == appears)
    #     @show cached 
    #     @show appears
    # end

    keys(g.classes)
    # cached
    # get(g.symcache, p.head, [])
end

# function cached_ids(g::EGraph, p::PatLiteral)
#     get(g.symcache, p.val, [])
# end

function search_rule!(g::EGraph, r::SymbolicRule, id, buf)
    append!(buf, [Match(r, r.right, sub, id) for sub in ematch(g, r.ematch_program, id)])
end

function search_rule!(g::EGraph, r::DynamicRule, id, buf)
    append!(buf, [Match(r, nothing, sub, id) for sub in ematch(g, r.ematch_program, id)]) 
end

function search_rule!(g::EGraph, r::BidirRule, id, buf)
    append!(buf, [Match(r, r.right, sub, id) for sub in ematch(g, r.ematch_program_l, id)])
    append!(buf, [Match(r, r.left, sub, id) for sub in ematch(g, r.ematch_program_r, id)])
end


function eqsat_search_threaded!(egraph::EGraph, theory::Vector{<:AbstractRule},
        scheduler::AbstractScheduler)::MatchesBuf
    matches = MatchesBuf()
    mlock = ReentrantLock()

    inequalities = filter(theory) do rule 
        rule isa UnequalRule
    end
    # never skip contradiction checks
    Threads.@threads for rule ∈ inequalities
        ids = cached_ids(egraph, rule.left)

        for id ∈ ids
            lock(mlock) do 
                search_rule!(egraph, rule, id, matches)
            end 
        end
    end

    other_rules = filter(theory) do rule 
        !(rule isa UnequalRule)
    end
    Threads.@threads for rule ∈ other_rules
        # don't apply banned rules
        if !cansearch(scheduler, rule)
            # println("skipping banned rule $rule")
            continue
        end

        rule_matches = []
        ids = cached_ids(egraph, rule.left)

        for id ∈ ids
            search_rule!(egraph, rule, id, rule_matches)
        end
        can_yield = inform!(scheduler, rule, rule_matches)
        if can_yield 
            lock(mlock) do
                append!(matches, rule_matches)
            end
        end
    end
    return matches
end


function eqsat_search!(egraph::EGraph, theory::Vector{<:AbstractRule},
    scheduler::AbstractScheduler)::MatchesBuf
    matches = MatchesBuf()

    inequalities = filter(theory) do rule 
        rule isa UnequalRule
    end
# never skip contradiction checks
    for rule ∈ inequalities
        ids = cached_ids(egraph, rule.left)

        for id ∈ ids
            search_rule!(egraph, rule, id, matches)
        end
    end

    other_rules = filter(theory) do rule 
        !(rule isa UnequalRule)
    end
    for rule ∈ other_rules
    # don't apply banned rules
        if !cansearch(scheduler, rule)
        # println("skipping banned rule $rule")
            continue
        end

        rule_matches = Match[]

        ids = cached_ids(egraph, rule.left)

        for id ∈ ids
            search_rule!(egraph, rule, id, rule_matches)
        end

        can_yield = inform!(scheduler, rule, rule_matches)
        if can_yield
            append!(matches, rule_matches)
        end
    end
    return matches
end
