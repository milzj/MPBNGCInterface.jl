[![MPBNGCInterface.jl Tests](https://github.com/milzj/MPBNGCInterface.jl/actions/workflows/test.yml/badge.svg)](https://github.com/milzj/MPBNGCInterface.jl/actions)

# MPBNGCInterface.jl

MPBNGCInterface.jl is a Julia module that interfaces
the Fortran77 code 
[Multiobjective Proximal Bundle Method `MPBNGC`](http://napsu.karmitsa.fi/proxbundle/).


The [Multiobjective Proximal Bundle Method `MPBNGC`](http://napsu.karmitsa.fi/proxbundle/)
can be applied to the nonsmooth, nonconvex multiobjective optimization problem
   
		min f₁(x), ..., fₘ(x) 
		s.t. 	x ∈  Rⁿ, 
		 	lb ≤ x ≤  ub,
			lbc ≤ C' x ≤ ubc, 
			fᵢ(x) ≤ 0,		i = m+1, ..., m+ngcon,

where 
`n`, `m`, `nlin`, `ngcon` is the number of 
optimization variables, 
objective functions,
linear constraints,
general constraints, respectively.
`lb` and `ub` are lower and upper bounds on `x`,
`lbc` and `ubc` are lower and upper bounds on `C' x`,
`C` is a `n x nlin`-matrix,
`fᵢ` are objective and general constraint functions,
and `C'` is the transposed of `C`.



## Installation

You can install `MPBNGCInterface.jl` through the 
[Julia Package Manager](https://docs.julialang.org/en/v1/stdlib/Pkg/index.html)
by executing the following command in the Pkg REPL:

```julia
add https://github.com/milzj/MPBNGCInterface.jl.git#dev
```

The command should download the module and compile
the Bundle method if you have `gfortran` installed. 

The code `build.jl` located in `deps`
when executed attempts to download the
[source code](http://napsu.karmitsa.fi/proxbundle/pb/mpbngc.tar.gz)
of the 
[Proximal Bundle Method `MPBNGC`](http://napsu.karmitsa.fi/proxbundle/)
and tries to compile it together with its dependencies.

For `Julia` version above `1.3`, `MPBNGCInterface.jl` cannot be installed using the
[Julia Package Manager](https://docs.julialang.org/en/v1/stdlib/Pkg/index.html).

To download `MPBNGCInterface.jl`, compile `MPBNGC`, and add
`MPBNGCInterface` to Julia's path, the following commands can be executed in a terminal:

```
git clone -b dev https://github.com/milzj/MPBNGCInterface.jl.git
cd MPBNGCInterface.jl
cd deps
julia build.jl
cd ..
julia -e "import Pkg; path = pwd(); Pkg.add(path=path)"
```

These commands should download the module and compile
the Bundle method *if* you have `gfortran` installed. 

The code `build.jl` located in `deps`
when executed attempts to download the
[source code](http://napsu.karmitsa.fi/proxbundle/pb/mpbngc.tar.gz)
of the 
[Proximal Bundle Method `MPBNGC`](http://napsu.karmitsa.fi/proxbundle/)
and tries to compile it together with its dependencies.


To run the tests, we can then execute in the Pkg REPL,
```julia
test MPBNGCInterface
```


The module is an unregistered Julia package. It has successfully been tested
on Linux and Mac OS using [Travics CI](https://travis-ci.com/)
with `julia version 1.0.5, 1.1.1, 1.2.0 and 1.3.1`.
Moreover, it has been tested on Windows 10 Education (version 10.0.16299) (64bit) with
`julia version 1.3.1` and `gfortran` of `mingw-w64 (x86_64)`.

### Compilation with gfortan

This code uses `gfortran` to compile the 
[Proximal Bundle Method `MPBNGC`](http://napsu.karmitsa.fi/proxbundle/).

The interface does not support compilers other than `gfortan`.

## Custom Installation

You can download the
[Proximal Bundle Method `MPBNGC`](http://napsu.karmitsa.fi/proxbundle/)
manually and use your favourite compiler flags to compile
and build `mpbngc.f` together with its dependences. 

You would need to create a 
[shared library](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)
and place it in the subdirectory `deps/usr`. 

## Manual

There is no user manual or help file available for the module.
I recommend to have a look at the examples and
tests to figure out how to use the module. 

The objective and constraint functions `fᵢ` need to implemented
in a single function having the following signature: 
	
```julia

function fasg!(n::Int64, x::Vector{Float64}, mm::Int64, 
		f::Vector{Float64}, g::Matrix{Float64})

```
even if you consider a single objective optimization problem. 
Function and subgradient evaluations are stored in 
`f` (a vector of length `mm`) and
`g` (a matrix of size `n x mm`), respectively. 
`f[1:m]` are the objective function values and
`f[m+1:mm]` the general constraint function values. 
("!" is optional.)

If you consider a bound-constrained optimization problem,
the "types" of the bounds `lb` and `ub` are stored in `ib`. Meaning, 
the components of `ib` indicate whether the corresponding
component of `x` is unconstrained, fixed, bounded from below and/or
bounded from above. 
The "classification" is performed by the function `classify_bounds`
called by the inner constructor
of the mutable struct `BundleProblem` according to
the rules indicated in the documentation of the function `classify_bounds`
(see [src/Bounds.jl](./src/Bounds.jl)). The variable `ib` matches 
the input variable `IX` of the Fortran code of the bundle method.

You can modify `ib` before calling `solveProblem`, which
calls the Fortran implemenation of the 
[Proximal Bundle Method `MPBNGC`](http://napsu.karmitsa.fi/proxbundle/). 

The bounds `lbc` and `ubc` (if present) get "classified" similarly
via the same function. The types are stored in `ic` corresponding to 
the input variable `IC` of the Fortran code. 

## References 

A user manual for the 
[Proximal Bundle Method `MPBNGC`](http://napsu.karmitsa.fi/proxbundle/)
is provided in

M.M. Mäkelä: [Multiobjective proximal bundle method for
nonconvex nonsmooth optimization: Fortran
subroutine MPBNGC 2.0](http://napsu.karmitsa.fi/publications/pbncgc_report.pdf). 
Reports of the Department of
Mathematical Information Technology, Series
B. Scientific Computing B 13/2003, University of Jyväskylä, Jyväskylä (2003)
 
Further details are provided in 

M.M. Mäkelä, N. Karmitsa, O. Wilppu: [Proximal Bundle Method for Nonsmooth
and Nonconvex Multiobjective Optimization](http://napsu.karmitsa.fi/publications/pbm.pdf)
in [Mathematical Modeling and Optimization of Complex Structures](http://link.springer.com/book/10.1007/978-3-319-23564-6). 
T. Tuovinen, S. Repin and P. Neittaanmäki (eds.), 
Vol. 40 of 
[Computational Methods in Applied Sciences](https://link.springer.com/bookseries/6899), 
pp. 191--204, Springer, 2016.

## Acknowledgments

I would like to thank [Professor Marko M. Mäkelä](https://www.utu.fi/en/people/marko-makela)
for making the source code of the
[Proximal Bundle Method `MPBNGC`](http://napsu.karmitsa.fi/proxbundle/)
available online. I would like to acknowledge
[Prof. Dr. Michael Ulbrich](https://www-m1.ma.tum.de/bin/view/Lehrstuhl/MichaelUlbrich)
and [Dr. Christian Ludwig](https://github.com/luchr)
for explaining me how to interface Fortran code. 
I appreciate very much that Christian took time to meet with me and to answer questions
I had about interfacing Fortran(77) code, and that he has allowed me to reuse 
large parts of his [ODEInterface.jl](https://github.com/luchr/ODEInterface.jl) code. 

## Author

The module has been implemented by Johannes Milz.
