"""
	function classify_bounds(lb::Vector{Float64}, ub::Vector{Float64})
	
		-> ib

	ib (a Int64 vector)  `classifies' bounds lb and ub according to

	ib[i] == 0	if	lb[i] = -Inf and ub[i] = Inf
	ib[i] == 1	if	lb[i] > -Inf and ub[i] = Inf
	ib[i] == 2	if	lb[i] == -Inf and ub[i] < Inf
	ib[i] == 3	if	lb[i] > -Inf and ub[i] < Inf
	ib[i] == 5	if 	lb[i] == ub[i] and ub[i] is finite
	
	In all other cases (hopefully), an error is thrown.

	The classification corresponds to the one required by
	mpbngc.f for both lower and upper bounds on the optimization
	variables and linear constraints (cf. ll. 46--51 and ll. 57--62).
"""
function classify_bounds(lb::Vector{Float64}, ub::Vector{Float64})

	n = length(lb)
	m = length(ub)
	ib = zeros(Int64, n)

	@assert n == m "Length of the lower bound lb=$n differs from"*
		" the length of the upper bound ub=$m."

	idx = lb .> ub

	@assert !any(idx) "Bounds define an empty feasible set."*
		" Lower bounds cannot exceed upper bounds:"*
		" lb[idx]  = $(lb[idx]) .> ub[idx] =  $(ub[idx]), where" *
		" idx = $idx."

	for i = 1:n
		if isfinite(lb[i]) && isinf(ub[i])
			ib[i] = 1
		elseif isinf(lb[i]) && isfinite(ub[i])
			ib[i] = 2
		elseif isfinite(lb[i]) && isfinite(ub[i])
			if lb[i] == ub[i]
				ib[i] = 5
			else
				ib[i] = 3
			end
		elseif lb[i] == ub[i] && isinf(lb[i])
			ib[i] = -1
		end
	end

	idx = ib .< 0
	
	@assert !any(idx) "Bounds define an empty feasible set."* 
		" Bounds cannot be simultaneously be equal and infinite:"*
		" lb[idx] = ub[idx] = $(lb[idx]) = $(ub[idx]), where" *
		" idx = $idx."

	return ib

end

# vim:syn=julia:cc=79:fdm=indent:
