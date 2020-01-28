# Example taken from [^Makela2003].

# [^Makela2003]: Mäkelä, M.M.: Multiobjective proximal bundle method for
# nonconvex nonsmooth optimization: Fortran subroutine MPBNGC 2.0. 
# Reports of the Department of Mathematical Information Technology, Series
# B. Scientific Computing B 13/2003, University of Jyväskylä, Jyväskylä (2003)
# [url](http://napsu.karmitsa.fi/publications/pbncgc_report.pdf).



using MPBNGCInterface


n = 2
mm = 3
x = [1.; 0.]

opt = BundleOptions( 
		OPT_GAM => [.3; .6; 0.0], 
		OPT_RL => .01, 
		OPT_EPS => 1e-5,
		OPT_FEAS => 1e-9,
		OPT_IPRINT => 4, 
		OPT_JMAX => 5,
		OPT_NOUT => 6,
		OPT_NITER => 100, 
		OPT_NFASG => 100, 
		OPT_LMAX => 100)


# Reference values
xref = [0.4752283; 0.1487644]
fref = [0.8694808; 0.1983203]

lb = zeros(n)
ub = ones(n)

ubc = ones(1)
lbc = -Inf*ones(1)
C = ones(2, 1)


function fasg(n, x, mm, f, g)

	# Rosenbrock
	f[1] = 100.0*(x[2]-x[1]^2)^2+(1. -x[1])^2
	g[1, 1] = -400.0*x[1]*(x[2]-x[1]^2)-2.0*(1. -x[1])
	g[2, 1] = 200.0*(x[2]-x[1]^2)

	# Crescent
	f1 = x[1]^2+(x[2]-1.)^2+x[2]-1.
	f2 = -x[1]^2-(x[2]-1.)^2+x[2]+1.
	f[2] = max(f1,f2)

	if f1 > f2
		g[1, 2] = 2x[1]
		g[2, 2] = 2x[2]-1.
	else
		g[1, 2] = -2x[1]
		g[2, 2] = -2x[2]+3.
	end

	# Constraint
	f[3] = (x[1]-1.)^2+(x[2]-1.)^2-1.
	g[1, 3] = 2x[1]-2.
	g[2, 3] = 2x[2]-2.

end

prob = BundleProblem(n, 2, 1, 1, fasg, x, lb, ub, lbc, ubc, C)

(x, fval, ierr, stats) = solveProblem(prob, opt)

@show fval[n+1]
@show dot(C, x)
@show x
@show xref
@show fval[1:n]
@show fref


# vim:syn=julia:cc=79:fdm=indent:
