struct ACRule{F,R} <: AbstractRule
    sets::F
    rule::R
    arity::Int
end

rule(acr::ACRule)   = acr.rule
getdepth(r::ACRule) = getdepth(r.rule)

macro acrule(expr)
    lhs = arguments(expr)[1]
    arity = length(arguments(lhs)[1:end])
    quote
        ACRule(permutations, $(esc(:(@rule($(expr))))), $arity)
    end
end

macro ordered_acrule(expr)
    lhs = arguments(expr)[1]
    arity = length(arguments(lhs)[1:end])
    quote
        ACRule(combinations, $(esc(:(@rule($(expr))))), $arity)
    end
end

Base.show(io::IO, acr::ACRule) = print(io, "ACRule(", acr.rule, ")")

function (acr::ACRule)(term::Y) where {Y}
    r = rule(acr)
    if !istree(term)
        r(term)
    else
        head = exprhead(term)
        f = operation(term)
        # Assume that the matcher was formed by closing over a term
        if f != operation(r.left) # Maybe offer a fallback if m.term errors. 
            return nothing
        end

        T = symtype(term)
        args = unsorted_arguments(term)

        itr = acr.sets(eachindex(args), acr.arity)

        for inds in itr
            tt = similarterm(Y, f, (@views args[inds]), symtype(T); exprhead=head)
            result = r(tt) # FIXME ??
            if result !== nothing
                # Assumption: inds are unique
                length(args) == length(inds) && return result
                return similarterm(Y, f, [result, (args[i] for i in eachindex(args) if i ∉ inds)...], symtype(term); exprhead = head)
            end
        end
    end
end
