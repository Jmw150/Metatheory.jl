include("prop_logic_theory.jl")
include("prover.jl")

Metatheory.options.verbose = true
Metatheory.options.printiter = true

ex = rewrite(:(((p => q) ∧ (r => s) ∧ (p ∨ r)) => (q ∨ s)), impl)
prove(t, ex, 3, 25)
@profview prove(t, ex, 3, 25)

