"""
	BundleProblem

Model an optimization problem to be passed to 
the proximal bundle method MPBNGC.

----------------------------------------------------------------------------

	function BundleProblem(n::Int64, fasg::Function, x::Vector{Float64})

	-> problem

Define an unconstrained optimization problem with `n` variables, 
a single objective function and the initial point `x`

----------------------------------------------------------------------------

	function BundleProblem(n::Int64, fasg::Function, x::Vector{Float64}, 
				lb::Vector{Float64}, ub::Vector{Float64})

	-> problem

Define an optimization problem with `n` variables, 
a single objective function, lower `lb` and upper bounds `ub`, and
the initial point `x`

----------------------------------------------------------------------------

	function BundleProblem(n::Int64, fasg::Function, x::Vector{Float64},
				lb::Vector{Float64}, ub::Vector{Float64},
				lbc::Vector{Float64}, ubc::Vector{Float64}, 
				c::Matrix{Float64})

	-> problem
	
Define an optimization problem with `n` variables, 
a single objective function, lower `lb` and upper bounds `ub`, 
linear constraints, and the initial point `x`

----------------------------------------------------------------------------

	function BundleProblem(n::Int64, nobj::Int64, ngcon::Int64, 
			       fasg::Function, x::Vector{Float64})

	-> problem

Define an optimization problem with `n` variables, 
`nobj` objective and `ngcon` general constraint functions, and
initial point `x`.

----------------------------------------------------------------------------

	function BundleProblem(n::Int64, nobj::Int64, nlin::Int64, ngcon::Int64, 
				fasg::Function, x::Vector{Float64}, 
				lb::Vector{Float64}, ub::Vector{Float64},
				lbc::Vector{Float64}, ubc::Vector{Float64}, 
				C::Matrix{Float64})

	-> problem

Define an optimization problem with `n` variables, 
`nobj` objective and `ngcon` general constraint functions, 
lower and upper bounds on `x`, linear constraints, and
initial point `x`.


"""
mutable struct BundleProblem
	"Number of optimization variables."
	n::Int64
	"Number of objective functions."
	nobj::Int64
	"Number of linear constraints."
	nlin::Int64
	"Number of general (nonlinear) constraints."
	ngcon::Int64
	"Objective and general constraint function(s)"
	fasg::Function
	"Initial values."
	x::Vector{Float64}
	"Types of bound constraints."
	ib::Vector{Int64}
	"Lower bounds."
	lb::Vector{Float64}
	"Upper bounds."
	ub::Vector{Float64}
	"Types of linear constraints."
	ic::Vector{Int64}
	"Lower bounds of linear constraints."
	lbc::Vector{Float64}
	"Upper bounds on linear constraints."
	ubc::Vector{Float64} 
	"Linear constraint matrix."
	C::Matrix{Float64}

	function BundleProblem(n::Int64, nobj::Int64, nlin::Int64, ngcon::Int64, 
			fasg::Function, x::Vector{Float64}, 
			lb::Vector{Float64}, ub::Vector{Float64},
			lbc::Vector{Float64}, ubc::Vector{Float64}, 
			C::Matrix{Float64})
		
		check_initial_point(n, x)

		ib = classify_bounds(lb, ub)

		ic = classify_bounds(lbc, ubc)
		check_linear_cons(n, nlin, lb, ub, lbc, ubc, C)

		return new(n, nobj, nlin, ngcon, fasg, x, ib, lb, ub, ic, lbc, ubc, C)

	end

	function check_initial_point(n::Int64, x::Vector{Float64})

		m = length(x)

		@assert n > 0 "Initial point x=$x has length n = $n."
		@assert n == m "Length of initial point x = $m"* 
			" differs from the number of optimization variables (n=$n.)"

	end

	function check_linear_cons(n::Int64, nlin::Int64, 
			lb::Vector{Float64}, ub::Vector{Float64},
			lbc::Vector{Float64}, ubc::Vector{Float64}, 
			C::Matrix{Float64})

		nrows, ncols = size(C)
		nlbc = length(lbc)
		nubc = length(ubc)
		
		@assert nlin == nlbc "Number of linear constraints (nlin = $nlin)"*
			" differs from the length of lower bounds (nlbc = $nlbc)."
		@assert nlbc == nubc "Length of lower bounds (nlbc = $nlbc)"*
			" differs from the length of upper bounds (nubc = $nubc)."
		@assert n == nrows "Number of rows of C = $nrows"*
			" differs from the number of optimization variables n = $n."
		@assert nlbc == ncols "Number of columns of C = $ncols"*
			" differs from the number of columns of lbc (nlbc = $nlbc)."

	end

end

function BundleProblem(n::Int64, fasg::Function, x::Vector{Float64})
	
	nobj = 1
	nlin = 0
	ngcon = 0

	lb = -Inf*ones(Float64, n)
	ub = Inf*ones(Float64, n)

	lbc = -Inf*ones(Float64, nlin)
	ubc = Inf*ones(Float64, nlin)
	C = zeros(Float64, n, nlin)

	return BundleProblem(n, nobj, nlin, ngcon, fasg, x, lb, ub, lbc, ubc, C)

end

function BundleProblem(n::Int64, fasg::Function, x::Vector{Float64}, 
		lb::Vector{Float64}, ub::Vector{Float64})
	
	nobj = 1
	nlin = 0
	ngcon = 0

	lbc = -Inf*ones(Float64, nlin)
	ubc = Inf*ones(Float64, nlin)
	C = zeros(Float64, n, nlin)

	return BundleProblem(n, nobj, nlin, ngcon, fasg, x, lb, ub, lbc, ubc, C)


end

function BundleProblem(n::Int64, fasg::Function, x::Vector{Float64},
			lb::Vector{Float64}, ub::Vector{Float64},
			lbc::Vector{Float64}, ubc::Vector{Float64}, 
			C::Matrix{Float64})
	
	check_initial_point(n, x)

	nobj = 1
	nlin = length(lbc)
	ngcon = 0

	return BundleProblem(n, nobj, nlin, ngcon, fasg, x, lb, ub, lbc, ubc, C)


end

function BundleProblem(n::Int64, nobj::Int64, ngcon::Int64, 
	       fasg::Function, x::Vector{Float64}) 

	nlin = 0

	lb = -Inf*ones(Float64, n)
	ub = Inf*ones(Float64, n)

	lbc = -Inf*ones(Float64, nlin)
	ubc = Inf*ones(Float64, nlin)
	C = zeros(Float64, n, nlin)

	return BundleProblem(n, nobj, nlin, ngcon, fasg, x, lb, ub, lbc, ubc, C)

end

"""
	function solveProblem(prob::BundleProblem, 
		      opt::AbstractBundleOptions=DefaultBundleOptions())

	-> (x, fval, ierr, stats)

Call proximal bundle method and return final iterate `x`,
final objective and general constraint function values
(if any) `fval`, the failure parameter `ierr` and
statistcs `stats`, such as number of iterations and
number of objective function evaluations.

"""
function solveProblem(prob::BundleProblem, 
		      opt::AbstractBundleOptions=DefaultBundleOptions())

	return mpbngc_impl(prob.n, prob.nobj, prob.nlin, prob.ngcon, 
			prob.x, prob.fasg, 
			prob.ib, prob.lb, prob.ub, 
			prob.ic, prob.lbc, prob.ubc, prob.C, 
			opt, 
			MPBNGCArguments{Int64}(Int64(0)))
end

# vim:syn=julia:cc=79:fdm=indent:
