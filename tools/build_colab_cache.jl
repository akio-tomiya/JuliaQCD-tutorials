# Build a precompiled cache of LatticeQCD.jl and PlotlyLight.jl for Google Colab.
#
# Run this in a fresh Colab Julia runtime:
#   include(download("https://raw.githubusercontent.com/akio-tomiya/JuliaQCD-tutorials/main/tools/build_colab_cache.jl"))
#
# Colab's IJulia loads some packages (Preferences, JLLWrappers, ...) from Colab's own depot at startup,
# and precompiled files are checked against the exact builds of their dependencies. A cache built
# anywhere else is therefore rejected on Colab, so the cache must be built on Colab itself.
#
# The script keeps Colab's preinstalled package versions (PRESERVE_ALL), precompiles only what is
# loaded, and packs the files that were added to the depot together with the resulting environment.
# The notebooks check `key` (the SHA-256 of Colab's default Manifest.toml before installing) and fall
# back to a normal installation when Colab has changed.
using Pkg, SHA

const PKGS = ["LatticeQCD", "PlotlyLight"]
depot = DEPOT_PATH[1]
envdir = dirname(Base.active_project())
manifest = joinpath(envdir, "Manifest.toml")
key = bytes2hex(sha256(read(manifest)))
compiled = joinpath("compiled", "v$(VERSION.major).$(VERSION.minor)")

function files_under(root, sub)
    dir = joinpath(root, sub)
    isdir(dir) || return Set{String}()
    out = Set{String}()
    for (path, _, files) in walkdir(dir), f in files
        push!(out, relpath(joinpath(path, f), root))
    end
    return out
end

subs = ["packages", "artifacts", compiled]
before = Dict(s => files_under(depot, s) for s in subs)

ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "0"
t_add = @elapsed Pkg.add(PKGS; preserve=Pkg.PRESERVE_ALL)
t_using = @elapsed @eval using LatticeQCD, PlotlyLight
println("Pkg.add: ", round(t_add), " s, using: ", round(t_using), " s")

new = sort!(collect(union((setdiff(files_under(depot, s), before[s]) for s in subs)...)))
println(length(new), " new files in the depot")

stage = joinpath(depot, "lqcd_colab_env")
mkpath(stage)
cp(joinpath(envdir, "Project.toml"), joinpath(stage, "Project.toml"); force=true)
cp(manifest, joinpath(stage, "Manifest.toml"); force=true)
write(joinpath(stage, "key.txt"), key * "\n")
write(joinpath(stage, "julia_version.txt"), string(VERSION) * "\n")
push!(new, relpath(joinpath(stage, "Project.toml"), depot), relpath(joinpath(stage, "Manifest.toml"), depot),
      relpath(joinpath(stage, "key.txt"), depot), relpath(joinpath(stage, "julia_version.txt"), depot))

list = "/content/lqcd_colab_cache_files.txt"
write(list, join(new, "\n") * "\n")
tarball = "/content/lqcd_colab_cache.tar.gz"
run(`tar -czf $tarball -C $depot -T $list`)
println("key = ", key)
println("julia = ", VERSION)
println(tarball, ": ", round(filesize(tarball) / 2^20, digits=1), " MiB")
