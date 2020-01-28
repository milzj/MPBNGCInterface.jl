__precompile__(false) 


module MPBNGCInterface

using LinearAlgebra

export OPT_LOGIO, OPT_LOGLEVEL

export OPT_RL, OPT_LMAX, OPT_EPS,
	OPT_FEAS, OPT_JMAX, OPT_GAM, OPT_NITER,
	OPT_NFASG, OPT_NOUT, OPT_IPRINT

export BundleOptions, getOption,
	setOptions, setOptions!,
	setOption!, BundleProblem, 
	solveProblem

include("./Base.jl")
include("./Error.jl")
include("./DLSolver.jl")
include("./Bounds.jl")

const OPT_LOGIO				= "logio"
const OPT_LOGLEVEL			= "loglevel"

const OPT_RL				= "LineSearchParameter"
const OPT_LMAX				= "MaxFASGCalls"
const OPT_EPS				= "FinalObjectiveAccurary"
const OPT_FEAS				= "ConstraintTolerance"
const OPT_JMAX				= "MaxStoredSubgradients"
const OPT_GAM				= "DistanceMeasureParameters"
const OPT_NITER				= "MaxNumIterations"
const OPT_NFASG				= "MaxNumFASG"
const OPT_NOUT				= "OutputFileNumber"
const OPT_IPRINT			= "PrintLevel"

include("./Options.jl")
include("./Problem.jl")
"""
  function extractLogOptions(opt::AbstractBundleOptions) -> (lio, lev)
  
  Extract options for logging.
  
  throws ArgumentErrorBundle if logio is not an IO or
  if loglevel is not convertable to UInt64.
  reads options: `OPT_LOGIO`, `OPT_LOGLEVEL`

  The function is a copy and paste implementation
  of `extractLogOptions` (see [^luchr]).

  [^luchr]: C. Ludwig : ODEInterface.jl, Technical University of
  Munich, Munich, [url](https://github.com/luchr/ODEInterface.jl/blob/master/src/ODEInterface.jl#L416)

"""
function extractLogOptions(opt::AbstractBundleOptions)
  lio=getOption(opt, OPT_LOGIO, stderr)
  if !isa(lio,IO)
    throw(ArgumentErrorBundle("option '$OPT_LOGIO' was not an Base.IO",:opt))
  end
  lev=nothing
  try
    lev=convert(UInt64,getOption(opt,OPT_LOGLEVEL,0))
  catch e
    throw(ArgumentErrorBundle(
      "option '$OPT_LOGLEVEL' cannot be converted to UInt64",:opt,e))
  end
  return (lio,lev)
end

"""function solver_init(solver_name::AbstractString, 
                            opt::AbstractBundleOptions)
          ->  (lio,l,l_g,l_solver,lprefix)
  reads options: `OPT_LOGIO`, `OPT_LOGLEVEL`

  The function is a copy and paste implementation
  of `extractLogOptions` (see [^luchr]).

  [^luchr]: C. Ludwig : ODEInterface.jl, Technical University of
  Munich, Munich, [url](https://github.com/luchr/ODEInterface.jl)
  """
function solver_init(solver_name::AbstractString, opt::AbstractBundleOptions)
  (lio,l) = extractLogOptions(opt);
  (l_g,l_solver)=( l & LOG_GENERAL>0, l & LOG_SOLVERARGS>0 )
  lprefix = string(solver_name,": ")
  return (lio,l,l_g,l_solver,lprefix)
end

"""function solver_start(solver_name::AbstractString, rhs, 
                   t0::Real, T::Real, x0::Vector, opt::AbstractBundleOptions)
          ->  (lio,l,l_g,l_solver,lprefix)
  
  initialization for a (typical) solver call/start.
  reads options: `OPT_LOGIO`, `OPT_LOGLEVEL`

  The function is a copy and paste implementation
  of `solver_start` (see [^luchr]).

  [^luchr]: C. Ludwig : ODEInterface.jl, Technical University of
  Munich, Munich, [url](https://github.com/luchr/ODEInterface.jl)
  """

function solver_start(solver_name::AbstractString, fasg::Function, 
            x::Vector{Float64}, opt::AbstractBundleOptions)
  
  (lio,l,l_g,l_solver,lprefix) = solver_init(solver_name, opt)

  if l_g
    println(lio,lprefix,
      "called with fasg=", fasg, " x=", x, " and opt")
    show(lio,opt); println(lio)
  end
  
  return (lio,l,l_g,l_solver,lprefix)
end

include("./Mpbngc.jl")
end

# vim:syn=julia:cc=79:fdm=indent:
