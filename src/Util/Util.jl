"""Definitions of various utility functions for metaprogramming"""
module Util

include("../docstrings.jl")

using Base.Meta
## AST manipulation utility functions

# useful shortcuts for nested macros
"""Add a dollar expression"""
dollar(v) = Expr(:$, v)
"Make a block expression from an array of exprs"
block(vs...) = Expr(:block, vs...)
"Add a & expression"
amp(v) = Expr(:&, v)

export dollar
export block
export amp

include("cleaning.jl")
export rmlines
export cleanast

end
