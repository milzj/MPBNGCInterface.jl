# Example taken from [^Haarala2004]
#
# min max_i x_i^2	s.t.	x in IR^20
#
# [^Haarala2004]: M. Haarala, K. Miettinen, M. M. Mäkelä (2004) 
# New limited memory bundle method for large-scale 
# nonsmooth optimization, Optimization Methods and 
# Software, 19:6, 673-692, DOI: 10.1080/10556780410001689225 


using MPBNGCInterface

opt = BundleOptions("convex-quadratic", 
		OPT_RL => .25)

n = 20

# initial point
x = ones(n)
idx = n÷2+1:n
x[n÷2+1:n] = -ones(length(idx))

# objective and gradient
function maxq(n, x, mm, f, g)

	(f_, idx) = findmax(x.^2)
	f[1] = f_
	g[:, 1] = zeros(n)
	g[idx, 1] = 2x[idx]

	return nothing

end

prob = BundleProblem(n, maxq, x)

(x, fval, ierr, stats) = solveProblem(prob, opt)


@assert isapprox(fval[1], 0.0, atol=1e-4, rtol=0) "fval=$(fval[1])"*
				" should be close to 0.0."

# vim:syn=julia:cc=79:fdm=indent:
