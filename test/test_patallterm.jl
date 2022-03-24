using Metatheory
using Test
using Metatheory.Library
using Metatheory.EGraphs
using Metatheory.EGraphs.Schedulers

t = [RewriteRule(PatTerm(:call, PatVar(:f), [PatVar(:a), PatVar(:b)], @__MODULE__), PatLiteral(:matched))]

g = EGraph(:(foo(bar)))
saturate!(g, t)

@test !areequal(g, RewriteRule[], :(foo(bar)), :matched)

addexpr!(g, :(foo(bar, baz)))
saturate!(g, t)

display(g.classes);
println();

@test areequal(g, RewriteRule[], :(foo(bar, baz)), :matched)
