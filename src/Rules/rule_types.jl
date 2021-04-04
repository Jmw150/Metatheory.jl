# TODO place this doc 
# """
# Type assertions are supported in the left hand of rules
# to match and access literal values both when using classic
# rewriting and EGraph based rewriting.
# To use a type assertion pattern, add `::T` after
# a pattern variable in the `left_hand` of a rule.
# """
using Parameters

import Base.==

abstract type Rule end
# Must override
==(a::Rule, b::Rule) = false
canprune(r::Type{<:Rule}) = false
canprune(r::T) where {T<:Rule}= canprune(T)


abstract type SymbolicRule <: Rule end

"""
Rules defined as `left_hand => right_hand` are
called *symbolic rewrite* rules. Application of a *rewrite* Rule
is a replacement of the `left_hand` pattern with
the `right_hand` substitution, with the correct instantiation
of pattern variables. Function call symbols are not treated as pattern
variables, all other identifiers are treated as pattern variables.
Literals such as `5, :e, "hello"` are not treated as pattern
variables.


```julia
Rule(:(a * b => b * a))
```
"""
struct RewriteRule <: SymbolicRule 
    left::Pattern
    right::Pattern
    prune::Bool
    patvars::Vector{Symbol}
    RewriteRule(l, r) = RewriteRule(l,r,false)
    function RewriteRule(l,r,p)
        pvars = patvars(l) ∪ patvars(r)
        setindex!(l, pvars)
        setindex!(r, pvars)
        new(l,r,p,pvars)
    end
end

canprune(t::Type{RewriteRule}) = true

# =============================================================================

# Only the last LHS is rewritten
struct MultiPatRewriteRule <: SymbolicRule 
    left::Pattern
    right::Pattern
    # additional lhs patterns
    pats::Vector{Pattern}
    patvars::Vector{Symbol}
    function MultiPatRewriteRule(l,r,pats)
        pvars = patvars(l) ∪ patvars(r)

        for p ∈ pats
            union!(pvars, patvars(p))
            setindex!(p, pvars)
        end
        setindex!(l, pvars)
        setindex!(r, pvars)
        
        new(l,r,pats,pvars)
    end
end
==(a::MultiPatRewriteRule, b::MultiPatRewriteRule) = a.left == b.left && 
    all(a.pats .== b.pats) && (a.right == b.right)


abstract type BidirRule <: SymbolicRule end
==(a::BidirRule, b::BidirRule) = (a.left == b.left) && (a.right == b.right)


"""
This type of *anti*-rules is used for checking contradictions in the EGraph
backend. If two terms, corresponding to the left and right hand side of an
*anti-rule* are found in an [`EGraph`], saturation is halted immediately. 
"""
struct UnequalRule <: BidirRule 
    left::Pattern
    right::Pattern
    patvars::Vector{Symbol}
    function UnequalRule(l,r)
        pvars = patvars(l) ∪ patvars(r)
        setindex!(l, pvars)
        setindex!(r, pvars)
        new(l,r,pvars)
    end
end

"""
```julia
Rule(:(a * b == b * a))
```
"""
struct EqualityRule <: BidirRule 
    left::Pattern
    right::Pattern
    patvars::Vector{Symbol}
    function EqualityRule(l,r)
        pvars = patvars(l) ∪ patvars(r)
        setindex!(l, pvars)
        setindex!(r, pvars)
        new(l,r,pvars)
    end
end

"""
Rules defined as `left_hand |> right_hand` are
called `dynamic` rules. Dynamic rules behave like anonymous functions.
Instead of a symbolic substitution, the right hand of
a dynamic `|>` rule is evaluated during rewriting:
matched values are bound to pattern variables as in a
regular function call. This allows for dynamic computation
of right hand sides.

Dynamic rule
```julia
Rule(:(a::Number * b::Number |> a*b))
```
"""
struct DynamicRule <: Rule 
    left::Pattern
    right::Any
    patvars::Vector{Symbol} # useful set of pattern variables
    prune::Bool
    function DynamicRule(l::Pattern, r, prune) 
        pvars = unique(patvars(l))
        setindex!(l, pvars)
        new(l, r, pvars, prune)
    end
    DynamicRule(l, r) = new(l,r,false)
end
canprune(t::Type{DynamicRule}) = true

==(a::DynamicRule, b::DynamicRule) = (a.left == b.left) && (a.right == b.right)

