
"""
Dictonariy for failure parameter `IERR` (see mpbngc.f lines 95--105).
"""
FailureParameter = Dict{Int64, String}(
0 => "Everything is OK.",
1 => "Number of calls of FASG = NFASG.",
2 => "Number of iterations = NITER.",
3 => "Invalid input parameters.",
4 => "Not enough working space.",
5 => "Failure in quadratic program.",
6 => "The starting point is not feasible.",
7 => "Failure in attaining the demanded accuracy.",
8 => "Failure in function or subgradient calculations"*
		" (assigned by the user).")


# The remaining lines are based on the file
# [url](https://github.com/luchr/ODEInterface.jl/blob/master/src/Error.jl)

"""
  The ancestor for all wrapped exceptions in NLPInterface.
  
  Required fields: msg, error
""" 
abstract type WrappedBundleException <: Base.WrappedException end

function showerror(io::IO,e::WrappedBundleException)
  println(io,e.msg)
  if e.error !== nothing
    println(io,"Wrapped exception:")
    showerror(io,e.error)
  end
end

"""
  This error indicates that one input argument is invalid.
  
  This is a WrappedException: If the invalidity of the argument
  was detected by some error/exception then, this initial
  error/exception can be found in the `error` field.
  """
mutable struct ArgumentErrorBundle <: WrappedBundleException
  msg      :: AbstractString
  argname  :: Symbol
  error
end

function ArgumentErrorBundle(msg,argname)
  ArgumentErrorBundle(msg,argname,nothing)
end

function showerror(io::IO,e::ArgumentErrorBundle)
  println(io,e.msg)
  e.argname !== nothing && println(io,string("in argument ",e.argname)) 
  if e.error !== nothing
    println(io,"Wrapped exception:")
    showerror(io,e.error)
  end
end

# vim:syn=julia:cc=79:fdm=indent:
