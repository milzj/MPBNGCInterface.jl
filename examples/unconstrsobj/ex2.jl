# min .5dot(x, x) + dot(h, x) s.t. x in IR^n,
# where h in IR^n and n = 10.000


using MPBNGCInterface 
using LinearAlgebra 
using Random

opt = BundleOptions("convex-quadratic", 
		OPT_RL => .25)

n = 10000
x = ones(n)
Random.seed!(1234)
h = randn(n)

function fasg(n, x, mm, f, g)

	f[1] = .5dot(x, x)+dot(h, x)
	g[:, 1] = x+h

end


prob = BundleProblem(n, fasg, x)

(x, fval, ierr, stats) = solveProblem(prob, opt)

println("opt. error norm(grad)=$(norm(x+h)).")
@assert norm(x+h) <= 1e-4

# vim:syn=julia:cc=79:fdm=indent:
