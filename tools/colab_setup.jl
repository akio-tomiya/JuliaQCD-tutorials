# Install LatticeQCD.jl and PlotlyLight.jl on Google Colab, using a precompiled cache when possible.
#
# The notebooks run this in their first cell on Colab:
#   include(download("https://raw.githubusercontent.com/akio-tomiya/JuliaQCD-tutorials/main/tools/colab_setup.jl"))
#
# The cache (built by tools/build_colab_cache.jl on Colab itself) is used only when Colab's default
# environment is exactly the one the cache was built on; this is checked with the SHA-256 of Colab's
# Manifest.toml and the Julia version. Otherwise the packages are installed normally: the packages the
# kernel has already loaded (IJulia, Preferences, JLLWrappers, ...) are pinned, and only what is loaded
# gets precompiled.
using Pkg, SHA

const PKGS = ["LatticeQCD", "PlotlyLight"]
const CACHE_URL = "https://github.com/akio-tomiya/JuliaQCD-tutorials/releases/download/colab-cache-20261019/lqcd_colab_cache.tar.gz"
const CACHE_KEY = "8b07570a49c0d65311d891d9fafc1992331d9be9faa4e9611631d68c8d174518"
const CACHE_JULIA = v"1.12.6"

let
    depot = DEPOT_PATH[1]
    envdir = dirname(Base.active_project())
    manifest = joinpath(envdir, "Manifest.toml")
    key = isfile(manifest) ? bytes2hex(sha256(read(manifest))) : ""
    used_cache = false
    if key == CACHE_KEY && VERSION == CACHE_JULIA
        try
            t = @elapsed begin
                tarball = download(CACHE_URL)
                run(`tar -xzf $tarball -C $depot`)
                stage = joinpath(depot, "lqcd_colab_env")
                cp(joinpath(stage, "Project.toml"), joinpath(envdir, "Project.toml"); force=true)
                cp(joinpath(stage, "Manifest.toml"), manifest; force=true)
                rm(tarball)
            end
            println("Installed from the precompiled cache in ", round(Int, t), " s.")
            used_cache = true
        catch err
            println("The precompiled cache could not be used (", sprint(showerror, err), "); installing normally.")
        end
    else
        println("Colab has changed since the cache was built; installing normally (a few minutes).")
    end
    if !used_cache
        ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "0"
        loaded = Set(Base.PkgId(m) for m in values(Base.loaded_modules))
        Pkg.pin([PackageSpec(name=info.name, uuid=uuid) for (uuid, info) in Pkg.dependencies()
                 if info.is_tracking_registry && !info.is_pinned && Base.PkgId(uuid, info.name) in loaded])
        Pkg.add(PKGS)
    end
end
