# Main functionality of the MPBNGC interface

# The file is based on the files
# [Dopri5.jl](https://github.com/luchr/ODEInterface.jl/blob/master/src/Dopri5.jl), 
# and
# [HWcommon.jl]https://github.com/luchr/ODEInterface.jl/blob/master/src/HWcommon.jl

"""Name for loading mpbngc solver (64bit integers)."""
const DL_MPBNGC = "mpbngc"
"""
	mutable struct CallInfos{FInt <: FortranInt, FASG_F}

Type storing all required data for MPGNGC callbacks.
"""
mutable struct CallInfos{FInt <: FortranInt}

	# log
	logio 		:: IO 			# where to log
	loglevel 	:: UInt64		# log level

	# FASG
	fasg 					# objectives and subgradients
	fasg_lprefix 	:: AbstractString	# saved log-prefix for fasg

end


"""
	mutable struct MPBGNCArugments{Fint <: FortranInt}

Stores arguments for the MPBNGC solver.
"""
mutable struct MPBNGCArguments{FInt <: FortranInt}
	"The number of variables (1 <= N)."
    	N	:: Vector{FInt}		
	"The vector of dimension N."	
    	X	:: Vector{Float64}	
	"Types of box constraints for individual variables."
    	IX	:: Vector{FInt}
	"Lower bounds on X."
    	BL	:: Vector{Float64}
	"Upper bounds on X."       
	BU	:: Vector{Float64}
	"The number of objective functions. (1 <= M)."
	M	:: Vector{FInt}
	"The number of general constraint functions. (0 <= MG)"
    	MG	:: Vector{FInt}
	"The number of linear constraints. (0 <= MC)."
	MC	:: Vector{FInt}
	"Types of individual linear constraints."
   	IC	:: Vector{FInt}
	"Lower bounds on CG(.,I)*X."
   	CL	:: Vector{Float64}
	"Upper bounds on CG(.,I)*X."
	CU	:: Vector{Float64}
	"Coefficients of linear constraints: i-th column of CG"*
	" corresponds to i-th linear constraint."
	CG	:: Array{Float64}
	"Vector of length MM (= M + MG) function values."
	F	:: Vector{Float64}
	"Objective(s) and constraint(s) callback"
	FASG	:: Ptr{Cvoid}
	"Line search parameter (0 < RL < 0.5)."
	RL	:: Vector{Float64}
	"The maximum number of FASG calls in line search (0 < LMAX)."
	LMAX	:: Vector{FInt}
	"The MP1 vector of distance measure parameters (0 <=GAM(I))."
    	GAM	:: Vector{Float64}
	"The final objective function accuracy parameter (0 < EPS)."
	EPS	:: Vector{Float64}
	"The tolerance for constraint feasibility (0 < FEAS)."
	FEAS	:: Vector{Float64}
	"The maximum number of stored subgradients (2 <=JMAX)."
	JMAX	:: Vector{FInt}
	"The maximum number of iterations (0 < NITER)."
	NITER	:: Vector{FInt}
	"The maximum number of FASG calls (1 < NFASG)."
	NFASG	:: Vector{FInt}
	"The output file number."
	NOUT	:: Vector{FInt}
	"Printout control parameter."
	IPRINT	:: Vector{FInt}
	"Failure parameter."
	IERR	:: Vector{FInt}
	"Working array."
	IWORK	:: Vector{FInt}
	"Dimension of IWORK (LIWORK >= 2*(MP1*(JMAX+1)+MC+N))"
	LIWORK	:: Vector{FInt}
	"Working array of dimension LWORK."
	WORK	:: Vector{Float64}
	"Dimension of WORK"
	LWORK	:: Vector{FInt}
	"Working array of the user."
	IUSER	:: Ref{CallInfos}
	"Working array of the user."
	USER	:: Vector{Float64}

	# Allow unintialized construction
	function MPBNGCArguments{FInt}(dummy::FInt) where FInt
		return new{FInt}()
	end

end


"""
	function fasg_(n::FInt, x::Array{Float64}, mm::FInt, 
			f::Array{Float64}, g::Array{Float64}, 
			cbi::CI) where {FInt, CI}
		-> nothing

Performs calls to `fasg` and supports logging.
The function is based on the function `hwrhs` implemented in 
[url](https://github.com/luchr/ODEInterface.jl/blob/master/src/HWcommon.jl)
"""
function fasg_(n::FInt, x::Array{Float64}, mm::FInt, 
		f::Array{Float64}, g::Array{Float64}, 
		cbi::CI) where {FInt, CI}

	# logging and debugging
	lprefix = cbi.fasg_lprefix

	(lio, l) = (cbi.logio, cbi.loglevel)
	l_fasg = l & LOG_FASG > 0

	l_fasg && println(lio, lprefix, " called with n=", n, " mm=", mm, " x=", x)

	# Call fasg
	cbi.fasg(n, x, mm, f, g)

	l_fasg && println(lio, lprefix, " f=", f, " g=", g)

	return nothing

end 


"""
	function unsafe_FASGCallback(n_::Ptr{FInt}, x_::Ptr{Float64},
			mm_::Ptr{FInt}, f_::Ptr{Float64},
			g_::Ptr{Float64}, ierr_::Ptr{FInt},	
			cbi::CI, user_::Ptr{Float64},
			) where {FInt <: FortranInt, CI <: CallInfos}
		-> nothing

This is the FASG function
(objectives, general constraints and their subgradients)
given as callback to the MPBNGC solver.

The `unsafe` prefix indicates that no validations of any kind are 
performed on the `Ptr` arguments.

We abuse the working array `IUSER` to pass the CallInfos `CI`.

The working array (more precisely the reference to `user_`)
is not used.
"""
function unsafe_FASGCallback(
		n_	::Ptr{FInt}, 	# number of variables
		x_	::Ptr{Float64},	# current iterate
		mm_	::Ptr{FInt},	# total number of objectives and	
					# general constraints (MM = MF + MG)
		f_	::Ptr{Float64},	# objective and general constraints
					# function values
		g_	::Ptr{Float64},	# vector of subgradients
		ierr_	::Ptr{FInt},	# failure parameter
		cbi	::CI,		# call infos
		user_	::Ptr{Float64},	# working array for the user
		) where {FInt <: FortranInt, CI <: CallInfos}

	n = unsafe_load(n_)
	x = unsafe_wrap(Array, x_, (n, ), own=false)
	mm = unsafe_load(mm_)
	f = unsafe_wrap(Array, f_, (mm, ), own=false)
	g = unsafe_wrap(Array, g_, (n, mm, ), own=false)
	ierr = unsafe_load(ierr_)	

	fasg_(n, x, mm, f, g, cbi)

	return nothing
end


"""
	function unsafe_FASGCallback_c(cbi::CI, 
			fint_flag::FInt) where {FInt, CI}
		-> C-callable function pointer

The method generates a pointer to a C-callable instruction.

In order to pass `FASGCallback' to Fortran, we first obtain
its address by calling this function.
"""
function unsafe_FASGCallback_c(cbi::CI, fint_flag::FInt) where {FInt, CI}

	return @cfunction(unsafe_FASGCallback, Cvoid, 
			(Ptr{FInt}, 	# N
			Ptr{Float64},	# X
			Ptr{FInt}, 	# MM
			Ptr{Float64}, 	# F
			Ptr{Float64}, 	# G
			Ptr{FInt}, 	# IERR		
			Ref{CI}, 	# misuse of IUSER
			Ptr{Float64}))	# USER
end



"""
	function mpbgnc_impl(fasg::Function,x::Vector{Float64},opt::OptionsNLP, 
			gs::MPBNGCArguments{FInt}) where FInt <: FortranInt

	-> (x, fval, ierr, stats)

Implements MPBGNC for FInt.

The function is based on the function `dopri5_impl` (see 
[url](https://github.com/luchr/ODEInterface.jl/blob/master/src/Dopri5.jl#L113))
"""
function mpbngc_impl(N::FInt, M::FInt, MC::FInt, MG::FInt, 
			x::Vector{Float64}, fasg::Function,
			IX::Vector{Int64}, BL::Vector{Float64}, 
			BU::Vector{Float64}, IC::Vector{Int64}, 
			CL::Vector{Float64}, CU::Vector{Float64}, 
			CG::Matrix{Float64}, opt::AbstractBundleOptions,
			args::MPBNGCArguments{FInt}) where FInt <: FortranInt

	(lio,l,l_g,l_solver,lprefix) = solver_start("MPBNGC", fasg, x, opt)

	@assert FInt == Int64 "Current implemenation requires"* 
					" FInt (=$FInt) to be `Int64`."

	method_mpbngc = getAllMethodPtrs((FInt == Int64) ? DL_MPBNGC : 
				error("Supporting only `Int64` integers."))
		
	# Rule for MP1 according to mpbngc.f (see lines 78--79).
	MG == 0 ? MP1 = M : MP1 = M + 1

	args.IX = convert(Vector{FInt}, IX)
	args.BL = BL
	args.BU = BU

	args.M = [convert(FInt, M)]
	args.MG = [convert(FInt, MG)]
	args.MC = [convert(FInt, MC)]

	args.IC = convert(Vector{FInt}, IC)
	args.CL = CL
	args.CU = CU
	args.CG = CG
	
	# Integers need to be passed as FInt-array of length one
	args.N = [ convert(FInt, N) ]

	args.X = copy(x)

	args.F = zeros(Float64, M+MG)

	# CallInfos
	fasg_lprefix = "unsafe_FASGCallback:"
	cbi = CallInfos{FInt}(lio, l, fasg, fasg_lprefix)

	# FASG
	args.FASG = unsafe_FASGCallback_c(cbi, FInt(0))

	# check and apply options
	OPT = nothing
	dopt = DefaultBundleOptions()

	try
		OPT=OPT_RL; DOPT = getOption(dopt, OPT)
		args.RL = [convert(Float64, getOption(opt, OPT, DOPT))]
		@assert 0.0 < args.RL[1] < 0.5 "The line search parameter RL"*
					" (=$(args.RL)) is not in (0.0, 0.5)."

		OPT=OPT_LMAX; DOPT = getOption(dopt, OPT)
		args.LMAX = [convert(FInt, getOption(opt, OPT, DOPT))]
		@assert args.LMAX[1] > 0 "The max. number of FASG calls in"*
		    " line search parameter LMAX (=$(args.LMAX)) is not > 0."

		OPT=OPT_EPS;  DOPT = getOption(dopt, OPT)
		args.EPS = [convert(Float64, getOption(opt, OPT, DOPT))]
		@assert args.EPS[1] > 0. "Final objective function accuracy"*
				" parameter (=$(args.EPS)) is not > 0."

		OPT=OPT_FEAS; DOPT = getOption(dopt, OPT)
		args.FEAS = [convert(Float64, getOption(opt, OPT, DOPT))]
		@assert args.FEAS[1] > 0. "Tolerance for constraint"*
				" feasibility (=$(args.FEAS)) is not > 0."

		OPT=OPT_JMAX; DOPT = getOption(dopt, OPT)
		args.JMAX = [convert(FInt, getOption(opt, OPT, DOPT))]
		@assert args.JMAX[1] >= 2 "Maximum number of stored"*
				" subgradients (=$(args.JMAX)) is not > 2."

		OPT=OPT_GAM; DOPT = getOption(dopt, OPT)
		GAM = getOption(opt, OPT, DOPT)
		if length(GAM) == 1 && MP1 > 1
			args.GAM  = GAM[1]*ones(Float64, MP1)
		else
			args.GAM = GAM
		end

		@assert length(args.GAM) == MP1 "The length of GAM,"*
					" `the MP1 vector of distance"*
					" measure parameters`"*
					" is $(length(args.GAM))"*
					" but supposed to be $MP1."

		@assert all(args.GAM .>= 0.0) "The vector GAM = $GAM,"*
					" `the MP1 vector of distance"*
					" measure parameters`"*
					" is supposed to be non-negative."

		OPT=OPT_NITER; DOPT = getOption(dopt, OPT)
		args.NITER = [convert(FInt, getOption(opt, OPT, DOPT))]
		@assert args.NITER[1] > 0 "Maximum number of iterations"*
					"  (=$(args.NITER)) is not > 0."

		OPT=OPT_NFASG; DOPT = getOption(dopt, OPT)
		args.NFASG = [convert(FInt, getOption(opt, OPT, DOPT))]
		@assert args.NFASG[1] > 0 "Maximum number of FASG calls"*
					"  (=$(args.FASG)) is not > 0."

		OPT=OPT_NOUT; DOPT = getOption(dopt, OPT)
		args.NOUT = [convert(FInt, getOption(opt, OPT, DOPT))]
		@assert args.NOUT[1] >= 0 "Maximum number of FASG calls"*
					"  (=$(args.NOUT)) is not >= 0."

		OPT=OPT_IPRINT; DOPT = getOption(dopt, OPT)
		args.IPRINT = [convert(FInt, getOption(opt, OPT, DOPT))]
		@assert 4 >= args.IPRINT[1] >= -1 "Printout control"*
		" parameter IPRINT=$(args.IPRINT[1]) is not in (-1, 4)"

	catch e
		throw(ArgumentErrorBundle("Option $OPT not valid", :opt, e))
	end

	JMAX = args.JMAX[1] 
	# Failure parameter
	args.IERR = zeros(FInt, 1)		

	# IWORK memory (cf. line 108 of mpbgnc.f)
	args.LIWORK = [convert(FInt, 2*(MP1*(JMAX+1)+MC+N))]
	args.IWORK = zeros(FInt, args.LIWORK[1])

	# WORK memory (cf. line 111 of mpbngc.f)
	args.LWORK = [convert(FInt, N*(N+2*MP1*JMAX+2*MP1+2*MC+2*MG+2*M+31)÷2+
					MP1*(6*JMAX+10)+JMAX+5*MC+MG+M+18)]

	args.WORK = zeros(Float64, args.LWORK[1])

	# USER memory
	args.USER = zeros(Float64, 0)

	# IUSER memory
	args.IUSER = cbi

	# IERR
	args.IERR = zeros(FInt, 1)

	# Preform ccall for mpbngc.f
	args.IPRINT[1] >= 0 ?
		println("Running Proximal Bundle Method MPBNGC.") : nothing

	# Check if working space is sufficiently large
	check(args.N[1],args.M[1],MP1,args.MG[1],args.MC[1],args.RL[1],
	       	args.LMAX[1],args.GAM, args.EPS[1],args.FEAS[1],args.JMAX[1],
		args.NITER[1],args.NFASG,args.IPRINT[1],args.LIWORK[1],
		args.LWORK[1],args.IERR)

	ccall(method_mpbngc, Cvoid,
		(Ptr{FInt}, 	# N
		Ptr{Float64}, 	# X
		Ptr{FInt},  	# IX
		Ptr{Float64}, 	# BL
		Ptr{Float64}, 	# BU
		Ptr{FInt}, 	# M
		Ptr{FInt}, 	# MG
		Ptr{FInt},	# MC
		Ptr{FInt},	# IC
		Ptr{Float64}, 	# CL
		Ptr{Float64}, 	# CU
		Ptr{Float64}, 	# CG
		Ptr{Float64},	# F
		Ptr{Cvoid}, 	# FASG
		Ptr{Float64}, 	# RL
		Ptr{FInt}, 	# LMAX
		Ptr{Float64}, 	# GAM
		Ptr{Float64}, 	# EPS
		Ptr{Float64}, 	# FEAS
		Ptr{FInt}, 	# JMAX
		Ptr{FInt}, 	# NITER
		Ptr{FInt}, 	# NFASG
		Ptr{FInt}, 	# NOUT
		Ptr{FInt}, 	# IPRINT
		Ptr{FInt}, 	# IERR
		Ptr{FInt},	# IWORK
		Ptr{FInt},	# LIWORK
		Ptr{Float64},	# WORK
		Ptr{FInt}, 	# LWORK
		Ref{CallInfos}, # IUSER
		Ptr{Float64} 	# USER
		), 
		args.N, args.X, 
		args.IX, args.BL,
		args.BU, args.M,
		args.MG, args.MC,
		args.IC, args.CL,
		args.CU, args.CG,
		args.F, args.FASG,
		args.RL, args.LMAX,
		args.GAM, args.EPS,
		args.FEAS, args.JMAX,
		args.NITER, args.NFASG,
		args.NOUT, args.IPRINT,
		args.IERR, args.IWORK,
		args.LIWORK, args.WORK,
		args.LWORK, args.IUSER,
		args.USER
	)

	# Define statistics
	stats = Dict{AbstractString, Any}(
		"NITER"		=> args.NITER[1],
		"NFASG"		=> args.NFASG[1],
		"IERR"		=> args.IERR[1])

	IERR = args.IERR[1]
	retmessage = FailureParameter[IERR]
	args.IPRINT[1] >= 0 ? println("MPBNGC terminated"*
				      " with `$retmessage`") : nothing

	return (args.X, args.F, IERR, stats)
end



"""
A light version of the Fortran subroutine
`CHECK` implemented in `mpbngc.f`.
"""
function check(N::Int,M::Int,MP1::Int,MG::Int,MC::Int,RL::Float64,LMAX::Int,
	GAM::Vector,EPS,FEAS,JMAX,NITER,NFASG,IPRINT,LIWORK,LWORK,IERR)

	LIW = 2*(MP1*(JMAX+1)+MC+N)
    	LW = N*(N+2*MP1*JMAX+2*MP1+2*MC+2*MG+2*M+31)÷2+
    		MP1*(6*JMAX+10)+JMAX+5*MC+MG+M+18

	@assert LIWORK <= LIW "LIWORK=$LIWORK greater than LIW=$LIW."
	@assert LWORK <= LW "LWORK=$LWORK greater than LW=$LW."

end

# vim:syn=julia:cc=79:fdm=indent:
