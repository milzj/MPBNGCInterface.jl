using Libdl

if isfile(joinpath(dirname(@__FILE__), "..", "deps", "deps.jl"))
	include("../deps/deps.jl")
else
	error("MPBNGC is not properly installed.")
end

"""
	function getAllMethodPtrs(libmpbngc::String)
		-> method_ptr

Load the shared library and the method `mpbngc`.
Its pointer is stored in `method_ptr`.

We use Julia's dynamic linker package
`Libdl` to load the shared library as well
as the optimization method. 
"""
function getAllMethodPtrs(dlname::AbstractString)

	global libmpbngc

	libhandle = Libdl.dlopen(libmpbngc)
	method_ptr = Libdl.dlsym(libhandle, "mpbngc_")

	@assert method_ptr != C_NULL "method_ptr = $method_ptr"*
			" is not of Ptr{Nothing} type."

	return method_ptr

end

# vim:syn=julia:cc=79:fdm=indent:
