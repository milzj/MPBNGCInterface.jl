# Check if LD_LIB... has to be updated

using Libdl

windows_flag = Sys.iswindows()
apple_flag = Sys.isapple()
file_extension = apple_flag ? ".dylib" : windows_flag ? ".dll" : ".so" 

const libmpbngc = joinpath(dirname(@__FILE__), "usr", "mpbngc"*file_extension)

function check_deps()
    global libmpbngc
    if !isfile(libmpbngc)
        error("The file $(libmpbngc) does not exist.")
    end

	# The method dlopen_e is depricated.
    if Libdl.dlopen(libmpbngc) in (C_NULL, nothing)
        error("The file $(libmpbngc) cannot be opened.")
    end

end

check_deps()

# vim:syn=julia:cc=79:fdm=indent:
