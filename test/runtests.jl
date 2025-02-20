using Flux
using Flux: OneHotArray, OneHotMatrix, OneHotVector
using Test
using Random, Statistics, LinearAlgebra
using IterTools: ncycle

using Zygote
const gradient = Flux.gradient  # both Flux & Zygote export this on 0.15
const withgradient = Flux.withgradient

using Pkg
using FiniteDifferences: FiniteDifferences
using Functors: fmapstructure_with_path

## Uncomment below to change the default test settings
# ENV["FLUX_TEST_AMDGPU"] = "true"
# ENV["FLUX_TEST_CUDA"] = "true"
# ENV["FLUX_TEST_METAL"] = "true"
# ENV["FLUX_TEST_CPU"] = "false"
# ENV["FLUX_TEST_DISTRIBUTED_MPI"] = "true"
# ENV["FLUX_TEST_DISTRIBUTED_NCCL"] = "true"
# ENV["FLUX_TEST_ENZYME"] = "false"

include("test_utils.jl") # for test_gradients

Random.seed!(0)

@testset verbose=true "Flux.jl" begin
  if get(ENV, "FLUX_TEST_CPU", "true") == "true"
    @testset "Utils" begin
      include("utils.jl")
    end

    @testset "Loading" begin
      include("loading.jl")
    end

    @testset "Train" begin
      include("train.jl")
      include("tracker.jl")
    end

    @testset "Data" begin
      include("data.jl")
    end

    @testset "Losses" begin
      include("losses.jl")
      include("ctc.jl")
    end

    @testset "Layers" begin
      include("layers/attention.jl")
      include("layers/basic.jl")
      include("layers/normalisation.jl")
      include("layers/stateless.jl")
      include("layers/recurrent.jl")
      include("layers/conv.jl")
      include("layers/upsample.jl")
      include("layers/show.jl")
      include("layers/macro.jl")
    end

    @testset "outputsize" begin
      using Flux: outputsize
      include("outputsize.jl")
    end

    @testset "functors" begin
      include("functors.jl")
    end

    @testset "deprecations" begin
      include("deprecations.jl")
    end
  else
      @info "Skipping CPU tests."
  end

  if get(ENV, "FLUX_TEST_CUDA", "false") == "true"
    Pkg.add(["CUDA", "cuDNN"])
    using CUDA, cuDNN

    if CUDA.functional()
      @testset "CUDA" begin
        include("ext_cuda/runtests.jl")
      end
    else
      @warn "CUDA.jl package is not functional. Skipping CUDA tests."
    end
  else
    @info "Skipping CUDA tests, set FLUX_TEST_CUDA=true to run them."
  end

  if get(ENV, "FLUX_TEST_AMDGPU", "false") == "true"
    Pkg.add("AMDGPU")
    using AMDGPU

    if AMDGPU.functional() && AMDGPU.functional(:MIOpen)
      @testset "AMDGPU" begin
        include("ext_amdgpu/runtests.jl")
      end
    else
      @info "AMDGPU.jl package is not functional. Skipping AMDGPU tests."
    end
  else
    @info "Skipping AMDGPU tests, set FLUX_TEST_AMDGPU=true to run them."
  end

  if get(ENV, "FLUX_TEST_METAL", "false") == "true"
    Pkg.add("Metal")
    using Metal

    if Metal.functional()
      @testset "Metal" begin
        include("ext_metal/runtests.jl")
      end
    else
      @info "Metal.jl package is not functional. Skipping Metal tests."
    end
  else
    @info "Skipping Metal tests, set FLUX_TEST_METAL=true to run them."
  end

  if get(ENV, "FLUX_TEST_DISTRIBUTED_MPI", "false") == "true" || get(ENV, "FLUX_TEST_DISTRIBUTED_NCCL", "false") == true
    Pkg.add(["MPI"])
    using MPI

    if get(ENV, "FLUX_TEST_DISTRIBUTED_NCCL", "false") == "true"
      Pkg.add(["NCCL"])
      using NCCL
    end

    @testset "Distributed" begin
      include("ext_distributed/runtests.jl")
    end

  else
    @info "Skipping Distributed tests, set FLUX_TEST_DISTRIBUTED_MPI or FLUX_TEST_DISTRIBUTED_NCCL=true to run them."
  end

  if get(ENV, "FLUX_TEST_ENZYME", "true") == "true"
    @testset "Enzyme" begin
      import Enzyme
      include("ext_enzyme/enzyme.jl")
    end
  else
    @info "Skipping Enzyme tests, set FLUX_TEST_ENZYME=true to run them."
  end

end
