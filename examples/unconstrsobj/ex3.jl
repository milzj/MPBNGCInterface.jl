# Example taken from tmpbngc.f

using MPBNGCInterface

opt = BundleOptions("tmpbngc.f", 
		OPT_NITER => 1000,
		OPT_NFASG => 1000,
		OPT_JMAX => 10,
		OPT_RL => .01,
		OPT_LMAX => 100,
		OPT_GAM => [.5], 
		OPT_EPS => 1e-5,
		OPT_FEAS => 1e-9,
		OPT_IPRINT => 3,
		OPT_NOUT => 6,
		OPT_LOGLEVEL => 0)

n = 2
# Same initial value as in tmpbngc.f
x = [-1.2, 1.0]

function fasg(n, x, mm, f, g)

	f[1]=100.0*(x[2]-x[1]^2)^2+(1-x[1])^2
	g[1,1]=-400.0*x[1]*(x[2]-x[1]^2)-2.0*(1-x[1])
	g[2,1]=200.0*(x[2]-x[1]^2)

end


prob = BundleProblem(n, fasg, x)

(x, fval, ierr, stats) = solveProblem(prob, opt)

@assert ierr == 0
@assert isapprox(x[1], 0.99989298920047021, rtol=1e-8, atol=1e-8)
@assert isapprox(x[2], 0.99989410878695095, rtol=1e-8, atol=1e-8)
@assert isapprox(fval[1], 1.1804217152673359e-6, rtol=1e-8, atol=1e-8)

# vim:syn=julia:cc=79:fdm=indent:
