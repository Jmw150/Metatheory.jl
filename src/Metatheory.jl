module Metatheory

using RuntimeGeneratedFunctions
using Base.Meta
using Reexport

include("docstrings.jl")

RuntimeGeneratedFunctions.init(@__MODULE__)

include("options.jl")

macro log(args...)
    quote options.verbose && @info($(args...)) end |> esc
end

export options

include("Util/Util.jl")
using .Util
export Util


include("rgf.jl")
export @metatheory_init

include("Patterns/Patterns.jl")
@reexport using .Patterns 

include("ematch_compiler.jl")
@reexport using .EMatchCompiler

include("Rules/Rules.jl")
@reexport using .Rules

include("match.jl")
export iscall

include("EGraphs/EGraphs.jl")
@reexport using .EGraphs

include("Library/Library.jl")
export Library


# TODO REMOVE DEPENDENCY TO SymbolicUtils
using SymbolicUtils.Rewriters
function rewrite(expr, theory; order=:outer)
   if order == :inner 
      Fixpoint(Prewalk(Fixpoint(Chain(theory))))(expr)
   elseif order == :outer 
      Fixpoint(Postwalk(Fixpoint(Chain(theory))))(expr)
   end
end
export rewrite


end # module
