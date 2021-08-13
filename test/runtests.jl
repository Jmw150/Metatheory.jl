using Metatheory
using Metatheory.EGraphs
using Metatheory.Library
using Metatheory.Util

using SymbolicUtils
using SymbolicUtils.Rewriters

function rewrite(expr, theory; order=:outer)
   if order == :inner 
      Fixpoint(Prewalk(Fixpoint(Chain(theory))))(expr)
   elseif order == :outer 
      Fixpoint(Postwalk(Fixpoint(Chain(theory))))(expr)
   end
end

# using DataStructures
using Test

Metatheory.options.verbose = false
Metatheory.options.printiter = false
Metatheory.options.multithreading = false

@metatheory_init ()

Test.FallbackTestSet(desc) = Test.FallbackTestSet()

ts = Test.FallbackTestSet

falseormissing(x) = 
    x === missing || !x


@testset ts "Metatheory Tests" begin
   @timev begin
      include("test_egraphs.jl")
      include("test_ematch.jl")
      include("test_ematch_assertions.jl")
      include("test_analysis.jl")
      include("test_extraction.jl")
      include("test_dynamic_ematch.jl")
      include("test_mu.jl")
      include("test_boson.jl")
      include("test_while_interpreter.jl")
      include("test_reductions.jl")
      include("test_taylor.jl")
      include("test_while_superinterpreter.jl")
      include("test_inequality.jl")
      include("test_patequiv.jl")
      # TODO
      include("test_custom_types.jl")
      # include("test_multipat.jl")
      # include("test_patallterm.jl")
      # use cases
      include("fib/test_fibonacci.jl")
      include("logic/test_calculational_logic.jl")
      include("logic/test_logic.jl")
      include("cas/test_infer.jl")
      # TODO n-ary splatvar
      # include("cas/test_cas.jl")
      include("category/test_cat.jl")
      include("group/test_kb_benchmark.jl")
      # include("proof/test_proof.jl")
      

      # exported consistency test
      for m ∈ [Metatheory, Metatheory.Util, Metatheory.EGraphs, Metatheory.EGraphs.Schedulers]
         for i ∈ propertynames(m)
            xxx = getproperty(m, i)
         end
      end
   end
end
