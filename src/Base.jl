# The file is based on 
# [ODEInterface.jl](https://github.com/luchr/ODEInterface.jl/blob/master/src/Base.jl)

"""
   supported (signed) Integer types for Fortran codes.
   """
FortranInt = Union{Int32,Int64}

"""Bitmask: log nothing."""
const LOG_NOTHING    = UInt64(0)

"""Bitmask: log some general info (esp. for main call)."""
const LOG_GENERAL = UInt64(1)<<0

"""Bitmask: log calls to `fasg`."""
const LOG_FASG = UInt64(1)<<1

"""Bitmask: log arguments passed to Fortran solvers."""
const LOG_SOLVERARGS = UInt64(1)<<2

"""Bitmask: log everything."""
const LOG_ALL = UInt64(0xFFFFFFFFFFFFFFFF)

# vim:syn=julia:cc=79:fdm=indent:
