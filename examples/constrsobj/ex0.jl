# min .5x[1]^2 + .5x[2]^2 s.t.  x in IR^2 and 1 <= x <= 2.

using MPBNGCInterface


n = 2
x = 3.0*ones(n)
lb = 1.0*ones(n)
ub = 2.0*ones(n)

function fasg(n, x, mm, f, g)

	f[1] = .5x[1]^2+.5x[2]^2
	g[1, 1] = x[1]
	g[2, 1] = x[2]

end

prob = BundleProblem(n, fasg, x)

(x, fval, ierr, stats) = solveProblem(prob)

display(x); println()
display(stats); println()


# vim:syn=julia:cc=79:fdm=indent:
