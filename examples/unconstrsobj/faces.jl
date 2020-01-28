# Example taken from [^Haarala2004]
#
#
# [^Haarala2004]: M. Haarala, K. Miettinen, M. M. Mäkelä (2004) 
# New limited memory bundle method for large-scale 
# nonsmooth optimization, Optimization Methods and 
# Software, 19:6, 673-692, DOI: 10.1080/10556780410001689225 


using MPBNGCInterface

n = 100

# initial point
x = ones(n)

# objective and gradient

logabs(y::Float64) = log(abs(y)+1.)
logabs(y::Vector{Float64}) = log.(abs.(y).+1.)

function faces(n, x, mm, f, g)

	sumx = sum(x)
	fvec = [logabs(-sumx)]
	append!(fvec, logabs(x))
	(f_, idx) = findmax(fvec)

	f[1] = f_
	g[:, 1] = zeros(n)

	if idx == 1
		temp = sumx[1]/(abs(sumx[1])+sumx[1]^2)
		[g[j, 1] = temp for j = 1:n]
	else
		g[idx, 1] = x[idx]/(abs(x[idx])+x[idx]^2)
	end

end

prob = BundleProblem(n, faces, x)

(x, fval, ierr, stats) = solveProblem(prob)

@assert isapprox(fval[1], 0.0, atol=1e-4, rtol=0) "fval=$(fval[1])"*
				" should be close to 0.0."

# vim:syn=julia:cc=79:fdm=indent:
