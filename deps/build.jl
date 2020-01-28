# File is based in 
# [url](https://github.com/luchr/ODEInterface.jl/blob/master/deps/build.jl).
# Just a few changes have been made.

# Download source code
"""
	function get_mpbngc(dir_of_deps::String)
		-> nothing

Download and untar source code
to `/usr`.  If the subdirectory `usr`
does not exist, it will be made. 
"""
function get_mpbngc(dir_of_deps::String)

	if Sys.iswindows()
		# Use Julia's build in functions 
		FILEN="mpbngc"
		URL = "http://napsu.karmitsa.fi/proxbundle/pb/"
		if !isdir("$dir_of_deps/usr") 
			mkdir("$dir_of_deps/usr")
		end
		download(URL*"$FILEN"*".f", "$dir_of_deps/usr/$FILEN.f")
		download(URL*"pllpb2"*".f", "$dir_of_deps/usr/pllpb2.f")
		download(URL*"plqdf1"*".f", "$dir_of_deps/usr/plqdf1.f")

		# run(`"wget" "-P" "$dir_of_deps\usr" "$URL"`)
		# run(`"tar" "xvzf" "$dir_of_deps\usr\$FILEN.tar.gz" -C "$dir_of_deps\usr"`)

		# if !isdir("$dir_of_deps\usr\downloads")
		# 	mkdir("$dir_of_deps\usr\downloads")
		# end 
		# run(`"mv" "$dir_of_deps\usr\$FILEN.tar.gz" "$dir_of_dep\usr\downloads"`)
	else 
		FILEN="mpbngc"
		URL = "http://napsu.karmitsa.fi/proxbundle/pb/"*"$FILEN"*".tar.gz"
		run(`"$mkdir" "-p" "$dir_of_deps/usr"`)
		run(`"wget" "-P" "$dir_of_deps/usr" "$URL"`)
		run(`"tar" "xvzf" "$dir_of_deps/usr/$FILEN.tar.gz" -C "$dir_of_deps/usr"`)

		run(`"mkdir" "-p" "$dir_of_deps/usr/downloads"`)
		run(`"mv" "$dir_of_deps/usr/$FILEN.tar.gz" "$dir_of_deps/usr/downloads"`)
	end
	
	return nothing

end

dir_of_this_file = dirname(@__FILE__) 
dir_of_deps = normpath(dir_of_this_file) 
if !isdir(dir_of_deps)
  error(string("Cannot find deps directory. I tried: ", dir_of_deps)) 
end

get_mpbngc(dir_of_deps)

try
  using Unicode
catch e
end

windows_flag = Sys.iswindows()
apple_flag = Sys.isapple()
file_extension = apple_flag ? ".dylib" : windows_flag ? ".dll" : ".so" 

obj_files = []

verbose = true

gfortran = nothing

function search_prog(progname::AbstractString)
  output = ""
  env_key = string("MPBNGCINTERFACE_",uppercase(progname))
  if haskey(ENV,env_key)
    output = ENV[env_key]
  else
    search_cmd = windows_flag ? `where "$progname"` : `which $progname`
    try
      output = rstrip(read(search_cmd, String))
    catch e
    end
  end
  return output
end

gfortran = search_prog("gfortran")
if isempty(gfortran)
  error("Currently only gfortran is supported.")
end


function compile_gfortran(path::AbstractString, basename::AbstractString,
         options::Dict=Dict())

  fext = get(options, "file_extension", ".f")
  ffile = joinpath(path,string(basename, fext))
  flags_i64 = get(options, "flags_i64",
              [ "-fdefault-integer-8", "-fdefault-real-8",
                "-fdefault-double-8" ])
  append!(flags_i64, get(options, "add_flags_i64", []))
  flags_i32 = get(options, "flags_i32",
              [ "-fdefault-real-8", "-fdefault-double-8" ])
  append!(flags_i32, get(options, "add_flags_i32", []))
  comp_flags = windows_flag ? [ "-c" ] : [ "-c", "-fPIC" ]

  if get(options, "build_i64", true)
    ofile = joinpath(path,string(basename,".o"))
    if windows_flag
      cmd_i64 = `"$gfortran"  $comp_flags $flags_i64 -o "$ofile"  "$ffile"`
    else
      cmd_i64 = `"$gfortran"  $comp_flags $flags_i64 -o $ofile  $ffile` 
    end
    verbose && println(cmd_i64)
    run(cmd_i64)
    push!(obj_files,ofile)
  end

  if get(options, "build_i32", true)
    ofile = joinpath(path,string(basename,"_i32.o"))
    if windows_flag
      cmd_i32 = `"$gfortran"  $comp_flags $flags_i32 -o "$ofile"  "$ffile"`
    else
      cmd_i32 = `"$gfortran"  $comp_flags $flags_i32 -o $ofile  $ffile`
    end
    verbose && println(cmd_i32)
    run(cmd_i32)
    push!(obj_files,ofile)
  end

  return nothing
end

function link_gfortran(path::AbstractString, basenames, options::Dict=Dict())
  link_flags = windows_flag ? [ "-shared" ] : [ "-shared", "-fPIC" ]
  
  if get(options, "build_i64", true)
    i64_obj = map( name -> joinpath(path,string(name,".o")), basenames )
    sofile = joinpath(path,string(basenames[1],file_extension))
    if windows_flag
      cmd_i64 = `"$gfortran" $link_flags -o "$sofile" "$i64_obj"`
    else
      cmd_i64 = `"$gfortran" $link_flags -o $sofile $i64_obj`
    end
    verbose && println(cmd_i64)
    run(cmd_i64)
  end

  if get(options, "build_i32", true)
    i32_obj = map( name -> joinpath(path,string(name,"_i32.o")), basenames )
    sofile = joinpath(path,string(basenames[1],"_i32",file_extension))
    if windows_flag
      cmd_i32 = `"$gfortran" $link_flags -o "$sofile" "$i32_obj"`
    else
      cmd_i32 = `"$gfortran" $link_flags -o $sofile $i32_obj`
    end
    verbose && println(cmd_i32)
    run(cmd_i32)
  end
  return nothing
end

function del_obj_files()
  for name in obj_files
    rm(name)
  end
  return nothing
end

function compile_plqdf1(path::AbstractString, options::Dict=Dict())
  compile_gfortran(path,"plqdf1", options)
  return nothing
end

function compile_pllpb2(path::AbstractString, options::Dict=Dict())
  compile_gfortran(path,"pllpb2", options)
  return nothing
end

function compile_mpbngc(path::AbstractString, options::Dict=Dict())
  compile_gfortran(path,"mpbngc", options)
  return nothing
end

function build_mpbngc(path::AbstractString, options::Dict=Dict())
  compile_gfortran(path,"mpbngc", options)
  link_gfortran(path,["mpbngc","plqdf1","pllpb2"], options)
  return nothing
end


# Supporting only `Int64` integers with `gfortran`
options = Dict("build_i64" => true, "build_i32" => false)

dir_of_src = normpath(joinpath(dir_of_this_file,"usr")) 
if !isdir(dir_of_src)
  error(string("Cannot find deps/dir directory. I tried: ", dir_of_src)) 
end


compile_plqdf1(dir_of_src, options) 
compile_pllpb2(dir_of_src, options) 
build_mpbngc(dir_of_src, options)

del_obj_files()


# vim:syn=julia:cc=79:fdm=indent:

