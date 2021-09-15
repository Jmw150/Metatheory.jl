using Metatheory
using Metatheory.SUSyntax 

@testset "Reduction Basics" begin
	t = @theory begin
	    ~a + ~a --> 2*(~a)
	    ~x / ~x --> 1
	    ~x * 1 --> ~x
	end

    # basic theory to check that everything works
    @test rewrite(:(a + a), t) == :(2a)
    @test rewrite(:(a + (x * 1)), t) == :(a + x)
	@test rewrite(:(a + (a * 1)), t; order=:inner) == :(2a)
end


import Base.(+)
@testset "Extending Algebra Operators" begin
    t = @theory begin
        ~a + ~a --> 2(~a)
    end
	
    # Let's extend an operator from base, for sake of example
    function +(x::Symbol, y)
        rewrite(:($x + $y), t)
    end
	
    @test (:x + :x) == :(2x)
end

## Free Monoid

@testset "Free Monoid - Overriding identity" begin
    # support symbol literals
	symbol_monoid = @theory begin
		~a ⋅ :ε --> ~a
		:ε ⋅ ~a --> ~a
		~a::Symbol --> ~a
		~a::Symbol ⋅ ~b::Symbol => Symbol(String(a) * String(b))
		# i |> error("unsupported ", i)
	end;

    @test rewrite(:(ε ⋅ a ⋅ ε ⋅ b ⋅ c ⋅ (ε ⋅ ε ⋅ d) ⋅ e), symbol_monoid; order=:inner) == :abcde
end

## Interpolation should be possible at runtime


@testset "Calculator" begin
	calculator = @theory begin
		~x::Number ⊕ ~y::Number => ~x + ~y
		~x::Number ⊗ ~y::Number => ~x * ~y
		~x::Number ⊖ ~y::Number => ~x ÷ ~y
		~x::Symbol --> ~x
		~x::Number --> ~x
	end;
	a = 10

	@test rewrite(:(3 ⊕ 1 ⊕ $a), calculator; order=:inner) == 14
end


## Direct rules
@testset "Direct Rules" begin
    t = @theory begin
        # maps
        ~a * ~b => ((~a isa Number && ~b isa Number) ? ~a * ~b : _lhs_expr)
    end
    @test rewrite(:(3 * 1), t) == 3

    t = @theory begin
        # maps
        ~a::Number * ~b::Number => ~a * ~b
    end
    @test rewrite(:(3 * 1), t) == 3
end



## Take advantage of subtyping.
# Subtyping in Julia has been formalized in this paper
# [Julia Subtyping: A Rational Reconstruction](https://benchung.github.io/papers/jlsub.pdf)

abstract type Vehicle end
abstract type GroundVehicle <: Vehicle end
abstract type AirVehicle <: Vehicle end
struct Airplane <: AirVehicle end
struct Car <: GroundVehicle end

airpl = Airplane()
car = Car()

@testset "Subtyping" begin
	t = @theory begin
		~a::AirVehicle * ~b => "flies"
		~a::GroundVehicle * ~b => "doesnt_fly"
	end

	sf = rewrite(:($airpl * c), t)
	df = rewrite(:($car * c), t)

    @test sf == "flies"
    @test df == "doesnt_fly"
end

airpl = Airplane()
car = Car()

@testset "Interpolation" begin
	t = @theory begin
		airpl * ~b => "flies"
		car * ~b => "doesnt_fly"
	end

	sf = rewrite(:(airpl * c), t)
	df = rewrite(:(car * c), t)

    @test sf == "flies"
    @test df == "doesnt_fly"
end

@testset "Segment Variables" begin
	t = @theory begin
		f(~x, ~~y) => Expr(:call, :ok, (~~y)...)
	end

	sf = rewrite(:(f(1,2,3,4)), t)

    @test sf == :(ok(2,3,4))
end


module NonCall 
using Metatheory 
using Metatheory.NewSyntax
t = @theory begin
	(a, b) => ok(a,b)
end

test() = rewrite(:(x,y), t)
end

@testset "Non-Call expressions" begin
	@test NonCall.test() == :(ok(x,y))
end


## Multiplicative Monoid

# TODO consider autocompiling from src/Library. This is very ugly.

# FIXME TYPE VARIABLES IN CLASSICAL MATCHCORE ALGORITHM
# macro red_commutative_monoid(t, op, id, func)
# 	zop = Meta.quot(op)
#    quote
# 	   @theory begin
# 			($op)($id, a) => a
# 			($op)(a, $id) => a
# 			# closure
# 			($op)(a::$t, b::$t) |> ($func)(a,b)
# 			# associativity reductions implying commutativity
# 			($op)(a::$t, ($op)(b::$t, c)) |>
# 				(z = ($func)(a, b); Expr(:call, ($zop), z, c))

# 			($op)(($op)(a::$t, c), b::$t) |>
# 				(z = ($func)(a, b); Expr(:call, ($zop), z, c))

# 			($op)(a::$t, ($op)(c, b::$t)) |>
# 				(z = ($func)(a, b); Expr(:call, ($zop), z, c))

# 			($op)(($op)(c, a::$t), b::$t) |>
# 				(z = ($func)(a, b); Expr(:call, ($zop), z, c))
# 	   end
#    end
# end

# mult_monoid = @red_commutative_monoid Int (*) 1 (*)

# @testset "Multiplication Monoid" begin
# 	res_macro = rewrite(:(3 * (1 * 2)), mult_monoid)
# 	res_sym = rewrite(:(3 * (1 * 2)), mult_monoid; order=:inner)
# 	res_macro_2 = rewrite(:(3 * (1 * 2)), mult_monoid; order=:inner)
# 	res_macro_3 = rewrite(:(2a * (3 * 2)), mult_monoid; order=:inner)

# 	@test res_macro == 6
# 	@test res_macro_2 == 6
# 	@test res_sym == 6
# 	@test res_macro_3 == :(12a)
# end

# constructs a semantic theory about a an abelian group
# The definition of a group does not require that a ⋅ b = b ⋅ a
# for all elements a and b in G. If this additional condition holds,
# then the operation is said to be commutative, and the group is called an abelian group.
# macro red_abelian_group(t, op, id, invop, func)
# 	zop = Meta.quot(op)
#    quote
# 	   @theory begin
# 			# identity element
# 			($op)($id, a) => a
# 			($op)(a, $id) => a
# 			# inversibility
# 			($op)(a, ($invop)(a)) => $id
# 			($op)(($invop)(a), a) => $id
# 			# closure
# 			($op)(a::$t, b::$t) |> ($func)(a,b)
# 			# inverse
# 			# associativity reductions
# 			($op)(a::$t, ($op)(b::$t, c)) |> (z = ($func)(a, b); Expr(:call, ($zop), z, c))
# 			($op)(($op)(a::$t, c), b::$t) |> (z = ($func)(a, b); Expr(:call, ($zop), z, c))
# 			($op)(a::$t, ($op)(c, b::$t)) |> (z = ($func)(a, b); Expr(:call, ($zop), z, c))
# 			($op)(($op)(c, a::$t), b::$t) |> (z = ($func)(a, b); Expr(:call, ($zop), z, c))
# 	   end
#    end
# end

# addition_group = @red_abelian_group Int (+) 0 (-) (+) ;
# @testset "Addition Abelian Group" begin
# 	zero = rewrite(:((x+y) +  -(x+y)), addition_group)
# 	@test zero == 0
# end



# # distributivity of two operations
# # example: `@distrib (⋅) (⊕)`
# macro red_distrib(outop, inop)
# 	@assert Base.isbinaryoperator(outop)
# 	@assert Base.isbinaryoperator(inop)
# 	quote
# 		@theory begin
# 			($outop)(a, ($inop)(b,c)) => ($inop)(($outop)(a,b),($outop)(a,c))
# 			($outop)(($inop)(a,b), c) => ($inop)(($outop)(a,c),($outop)(b,c))
# 		end
# 	end
# end
# distr = @red_distrib (*) (+)
# Z = mult_monoid ∪ addition_group ∪ distr;
# @testset "Composing Theories, distributivity" begin
# 	res_1 = rewrite(:(((2 + (b + -b)) * 3) * (a + b)), Z; order=:inner)
# 	e = rewrite(:((2 * (3 + b + (4 * 2)))), Z; order=:inner)

# 	@test_skip res_1 == :(6a+6b)
# 	@test_skip e == :(22+2b)
# end

# logids = @theory begin
# 	x * x => x^2
# 	x^n * x |> :($x^($(n+1)))
# 	x * x^n |> :($x^($(n+1)))
# 	a * (a * b) => a^2 * b
# 	a * (b * a) => a^2 * b
# 	(a * b) * a => a^2 * b
# 	(b * a) * a => a^2 * b
# 	# catch e as ℯ
# 	:e => ℯ
# 	log(a^n) => n * log(a)
# 	log(x * y) => log(x) * log(y)
# 	log(1) => 0
# 	log(:ℯ) => 1
# 	:ℯ^(log(x)) => x
# end;

# t = logids ∪ Z;
# @testset "Symbolic Logarithmic Identities, Composing Theories" begin
#     @test rewrite(:(log(ℯ)), t) == 1
#     @test rewrite(:(log(x)), t) == :(log(x))
#     @test rewrite(:(log(ℯ^3)), t) == 3
#     @test rewrite(:(log(a^3)), t) == :(3 * log(a))
#     # Reduce.jl wtf u doing? log(:x^-2 * ℯ^3) = :(log(5021384230796917 / (250000000000000 * x ^ 2)))

#     @test rewrite(:(log(x^2 * ℯ^3)), t) == :((6 * log(x)))
#     @test_skip rewrite(:(log(x^2 * ℯ^(log(x)))), t; order=:inner) == :(3 * log(x))
# end


# using Calculus: differentiate
# diff = @theory begin
# 	∂(y)/∂(x) |> differentiate(y, x)
# 	a * (1/x) => a/x
# 	a * 0 => 0
# 	0 * a => 0
# end
# finalt = t ∪ diff
# @testset "Symbolic Differentiation, Accessing Outer Variables" begin
# 	@test rewrite(:(∂( log(x^2 * ℯ^(log(x))) )/∂(x)), finalt) == :(3/x)
# end;
