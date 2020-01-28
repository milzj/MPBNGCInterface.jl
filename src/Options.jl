# Options for InterfaceMPBNGC.jl

# The file is basically a copy and paste of
# [url](https://github.com/luchr/ODEInterface.jl/blob/master/src/Options.jl.
# The main difference is that `Options*` has been changed to `BundleOptions`.

import Base: show

using Dates

abstract type AbstractBundleOptions end

"""
Stores options for the bundle method together with a name.
  Additionally the time of the last change is saved.
  
  Options can be set at construction time, e.g.
  
       opt=BundleOptions("test",
                      "loglevel" => MPBNGCInterface.LOG_ALL,
                      "logio"    => stderr)
  
  or later. For changing single options 
  
       oldValue = setOption!(opt,"myopt","new value")
       oldValue = setOption!(opt,"myopt" => "new value")
  
  and for changing many options at once:
  
       oldValues = setOption!(opt,
                   "myopt" => "new value",
                   "oldopt" => 56)
  
  see also: `setOption!`, `setOptions!`
"""
mutable struct BundleOptions <: AbstractBundleOptions
  name        :: AbstractString
  lastchanged :: DateTime
  options     :: Dict{AbstractString,Any}

  function BundleOptions(name::AbstractString="")
    obj = new(name,now(),Dict{AbstractString,Any}())
    return obj
  end
end

"""
Default options for MPBNGC.

Used if the user 
does not specify options.

The default values for `RL`, `JMAX` are taken from [^Makela2003].
All other parameter values are based on the ones used in
[url](http://napsu.karmitsa.fi/proxbundle/pb/tmpbngc.f).


[^Makela2003]: 
Mäkelä, M.M.: Multiobjective proximal bundle method for
nonconvex nonsmooth optimization: Fortran
subroutine MPBNGC 2.0. Reports of the Department of
Mathematical Information Technology, Series
B. Scientific Computing B 13/2003, University of Jyväskylä, Jyväskylä (2003)
[url](http://napsu.karmitsa.fi/publications/pbncgc_report.pdf).
"""
mutable struct DefaultBundleOptions <: AbstractBundleOptions
	name 		:: AbstractString
	lastchanged 	:: DateTime
	options 	:: Dict{AbstractString,Any}

	function DefaultBundleOptions()
		name = "DefaultOptions"
		lastchanged = DateTime(2019,10,7,12,00,00)
		options = Dict(
			OPT_RL		=> 0.01,
			OPT_LMAX	=> 100,
			OPT_EPS		=> 1e-5,
			OPT_FEAS 	=> 1e-9,
			OPT_JMAX 	=> 5,
			OPT_NITER	=> 1000,
			OPT_NFASG	=> 1000,
			OPT_NOUT	=> 6,
			OPT_IPRINT	=> 3,
			OPT_LOGLEVEL	 => 0,
			OPT_GAM 	=> [.5])
		obj = new(name, lastchanged, options)
		return obj
	end

end


function BundleOptions(name::AbstractString,copyOptionsFrom::AbstractBundleOptions) 
  opt = BundleOptions(name)
  copyOptions!(opt,copyOptionsFrom)
  return opt
end

function BundleOptions(copyOptionsFrom::AbstractBundleOptions) 
  return BundleOptions("",copyOptionsFrom)
end

function BundleOptions(name::AbstractString,pairs::Pair...)
  opt = BundleOptions(name)
  setOptions!(opt,pairs...)
  return opt
end

function BundleOptions(pairs::Pair...)
  return BundleOptions("",pairs...)
end


function getOption(opt::AbstractBundleOptions,name::AbstractString,
                   default::Any=nothing)
  return haskey(opt.options,name) ? opt.options[name] : default
end

"""
	function setOption!(opt::AbstractBundleOptions,
			name::AbstractString,value::Any)

  set Bundle-Option with given `name` and return old value 
  (or `nothing` if there was no old value).
"""

function setOption!(opt::AbstractBundleOptions,name::AbstractString,value::Any)
  oldValue = getOption(opt,name)
  opt.options[name]=value
  opt.lastchanged=now()
  return oldValue
end

"""
	function setOption!(opt::AbstractBundleOptions,pair::Pair)

  set Bundle-Option with given (`name`,`value`) pair and return old value 
  (or `nothing` if there was no old value).
"""
function setOption!(opt::AbstractBundleOptions,pair::Pair)
  return setOption!(opt,pair.first,pair.second)
end

"""
	function setOptions!(opt::AbstractBundleOptions,pairs::Pair...)

  set many Bundle-Options and return an array with the old option values.
  """
function setOptions!(opt::AbstractBundleOptions,pairs::Pair...)
  oldValues=Any[]
  for (name,value) in pairs
    push!(oldValues, setOption!(opt,name,value))
  end
  return oldValues
end

"""
	function copyOptions!(dest::AbstractBundleOptions,source::AbstractBundleOptions)

  copy all options from other Bundle-Option object.
  """
function copyOptions!(dest::AbstractBundleOptions,source::AbstractBundleOptions)
  merge!(dest.options,source.options)
  dest.lastchanged=now()
  return dest
end

function show(io::IO, opt::AbstractBundleOptions)
	print(io,typeof(opt)," ")
	isempty(opt.name) || print(io,"'",opt.name,"' ")
	len=length(opt.options)
	print(io,"with ",len," option",len!=1 ? "s" : "", len>0 ? ":" : "."); println(io)
	if len>0
	maxLen = 2 + max(0, Set(length(k) for k = keys(opt.options))...)
	for key in sort(collect(keys(opt.options)))
	  print(io,lpad(key,maxLen),": ")
	  show(io,opt.options[key]); println(io)
	end
	end
	print(io,"lasted changed "); show(io,opt.lastchanged); 
end

# vim:syn=julia:cc=79:fdm=indent:

