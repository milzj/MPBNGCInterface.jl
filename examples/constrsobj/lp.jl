# Example taken from [url](https://cvxopt.org/examples/tutorial/lp.html)

using MPBNGCInterface


n = 2
x = ones(n)
lb = -Inf*ones(n)
lb[2] = 0.0
ub = Inf*ones(n)

lbc = -Inf*ones(3)
ubc = Inf*ones(3)
ubc[1] = 1.
lbc[2] = 2.
ubc[3] = 4.


# C needs to be an Array{Float64,2} = Matrix{Float64}
C = Matrix(transpose([-1. 1.;  1. 1.; 1. -2.]))

function fasg(n, x, mm, f, g)

	f[1] = 2x[1]+x[2]
	g[1, 1] = 2.
	g[2, 1] = 1.

end


prob = BundleProblem(n, fasg, x, lb, ub, lbc, ubc, C)

(x, fval, ierr, stats) = solveProblem(prob)
display(x); println()
display(stats); println()


# vim:syn=julia:cc=79:fdm=indent:
