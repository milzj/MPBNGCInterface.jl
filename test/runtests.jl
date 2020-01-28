"""	
Module for testing MPBNGCInterface.jl
"""

module TestMPBNGCTest

using Test
using LinearAlgebra

using MPBNGCInterface

"""Test problem taken from tmpbngc.jl"""
function test_tmpbngc()

	@testset "tmpbngc" begin
		# Options are the same as used in tmpbngc.f
		# except of IPRINT
		opt = BundleOptions("tmpbngc.f", 
				OPT_NITER => 1000,
				OPT_NFASG => 1000,
				OPT_JMAX => 10,
				OPT_RL => .01,
				OPT_LMAX => 100,
				OPT_GAM => [.5], 
				OPT_EPS => 1e-5,
				OPT_FEAS => 1e-9,
				OPT_IPRINT => -1,
				OPT_NOUT => 6,
				OPT_LOGLEVEL => 0)

		n = 2
		# Same initial value as in tmpbngc.f
		x = [-1.2, 1.0]

		function fasg(n, x, mm, f, g)

			f[1]=100.0*(x[2]-x[1]^2)^2+(1-x[1])^2
			g[1,1]=-400.0*x[1]*(x[2]-x[1]^2)-2.0*(1-x[1])
			g[2,1]=200.0*(x[2]-x[1]^2)

		end
		prob = BundleProblem(n, fasg, x)
		(x, fval, ierr, stats) = solveProblem(prob, opt)
		@test ierr == 0
		@test stats["NITER"] == 49
		@test stats["NFASG"] == 83
		# Compare with reference solution computed by Fortran code
		@test isapprox(x[1], 0.99989298920047021, rtol=1e-8, atol=1e-8)
		@test isapprox(x[2], 0.99989410878695095, rtol=1e-8, atol=1e-8)
		@test isapprox(fval[1], 1.1804217152673359e-6, rtol=1e-8, atol=1e-8)
	end

	return nothing

end

function test_convex_quadratic()

	@testset "Convex-Quadratic" begin

		opt = BundleOptions("convex-quadratic", 
				OPT_RL => .25,
				OPT_IPRINT => -1)

		n = 2
		x0 = ones(n)

		function fasg(n, x, mm, f, g)

			f[1] = .5x[1]^2+.5x[2]^2
			g[1, 1] = x[1]
			g[2, 1] = x[2]

		end
		prob = BundleProblem(n, fasg, x0)
		(x, fval_, ierr, stats) = solveProblem(prob, opt)
		@test ierr == 0
		@test isapprox(norm(x), 0.0, atol=1e-5, rtol=0.)
		@test isapprox(fval_[1], 0.0, atol=1e-5, rtol=0.)
	end

	return nothing

end
"""
Test problem from [^Makela2003].
"""
function test_rosenbrock_crescent()

	@testset "Rosenbrock-Crescent" begin

		n = 2
		mm = 3
		x = [1.; 0.]

		opt = BundleOptions( 
				OPT_GAM => [.3; .6; 0.0], 
				OPT_RL => .01, 
				OPT_EPS => 1e-5,
				OPT_FEAS => 1e-9,
				OPT_IPRINT => -1, 
				OPT_JMAX => 5,
				OPT_NOUT => 6,
				OPT_NITER => 100, 
				OPT_NFASG => 100, 
				OPT_LMAX => 100)


		# Reference values
		xref = [0.47522830981318487; 0.14876436017636541]
		fref = [0.86948075736605746; 0.19832029922251637; 0.0]

		lb = zeros(n)
		ub = ones(n)

		ubc = ones(1)
		lbc = -Inf*ones(1)
		C = ones(2, 1)


		function fasg(n, x, mm, f, g)

			# Rosenbrock
			f[1] = 100.0*(x[2]-x[1]^2)^2+(1. -x[1])^2
			g[1, 1] = -400.0*x[1]*(x[2]-x[1]^2)-2.0*(1. -x[1])
			g[2, 1] = 200.0*(x[2]-x[1]^2)

			# Crescent
			f1 = x[1]^2+(x[2]-1.)^2+x[2]-1.
			f2 = -x[1]^2-(x[2]-1.)^2+x[2]+1.
			f[2] = max(f1,f2)

			if f1 > f2
				g[1, 2] = 2x[1]
				g[2, 2] = 2x[2]-1.
			else
				g[1, 2] = -2x[1]
				g[2, 2] = -2x[2]+3.
			end

			# Constraint
			f[3] = (x[1]-1.)^2+(x[2]-1.)^2-1.
			g[1, 3] = 2x[1]-2.
			g[2, 3] = 2x[2]-2.

		end

		prob = BundleProblem(n, 2, 1, 1, fasg, x, lb, ub, lbc, ubc, C)

		(x,f,  ierr, stats) = solveProblem(prob, opt)
	
		i = 0; 
		i += 1; @test isapprox(x[i], xref[i], rtol=1e-8, atol=1e-8)
		i += 1; @test isapprox(x[i], xref[i], rtol=1e-8, atol=1e-8)

		i = 0; 
		i += 1; @test isapprox(f[i], fref[i], rtol=1e-8, atol=1e-8)
		i += 1; @test isapprox(f[i], fref[i], rtol=1e-8, atol=1e-8)
		i += 1; @test isapprox(f[i], fref[i], rtol=1e-8, atol=1e-8)

		@test 15 == stats["NITER"]
		@test 16 == stats["NFASG"]
	end
end

function test_bounds()

	@testset "Classify bounds" begin

		lb = [-Inf; 0.0; .5]
		ub = [Inf; Inf; 1.0]

		cb = MPBNGCInterface.classify_bounds(lb, ub)
		@test cb == [0; 1;  3]
		
		lb = [-Inf; 0.0; -Inf; 0.; 1.0]
		ub = [Inf; Inf ; 0.; 3.0; 1.0]

		cb = MPBNGCInterface.classify_bounds(lb, ub)

		@test cb == [0; 1; 2;  3; 5]

	end
end


# The following function is adapted from
# [url](https://github.com/luchr/ODEInterface.jl/blob/master/test/runtests.jl)
function test_Options()

  @testset "Options" begin

    opt1 = BundleOptions("test1");
    @test isa(opt1, BundleOptions)
    @test isa(opt1, MPBNGCInterface.AbstractBundleOptions)
    @test setOption!(opt1,"test_key",56) === nothing
    @test setOption!(opt1,"test_key",82) == 56
    @test getOption(opt1,"test_key",0) == 82
    @test getOption(opt1,"nokey",nothing) === nothing
    @test getOption(opt1,"nokey","none") == "none"
    @test setOptions!(opt1, "test_key" => 100, "new_key" => "bla") ==
          [82,nothing]

    opt2 = BundleOptions("test2",opt1)
    @test getOption(opt1,"test_key",0) == 100
  end

	return nothing

end


function test_all()

	test_tmpbngc()
	test_convex_quadratic()
	test_rosenbrock_crescent()
	test_bounds()
	test_Options()

end

test_all()

end


# vim:syn=julia:cc=79:fdm=indent:
