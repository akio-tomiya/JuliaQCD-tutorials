# Build a precompiled cache of LatticeQCD.jl and PlotlyLight.jl for Google Colab.
#
# Run this in a fresh Colab Julia runtime:
#   include(download("https://raw.githubusercontent.com/akio-tomiya/JuliaQCD-tutorials/main/tools/build_colab_cache.jl"))
#
# Colab's IJulia loads some packages (Preferences, JLLWrappers, PrecompileTools, ZMQ, ...) at startup,
# and precompiled files are checked against the exact builds of their dependencies. Colab's own
# precompiled files of these packages do not match the CPU of the runtime, so every new runtime
# precompiles them again at startup, with new build IDs. The cache therefore also contains the
# precompiled files of every package the kernel has loaded, and tools/colab_setup.jl restarts the
# kernel once after unpacking, so that the kernel loads exactly the builds the cache was made with.
#
# Many of Colab's own precompiled files (Plots, for example) are built for a different CPU than the
# machine a runtime gets ("cache misses: target mismatch"), which is a large part of why Colab is slow.
# The cache is built for the CPU of the runtime (native). It cannot be built for generic CPU targets:
# the packages that the kernel loads at startup (PrecompileTools, Preferences, ...) are precompiled for
# one CPU only, and a generic build of their dependents is then skipped. The packages that the kernel
# has already loaded are pinned so that their versions do not change; other versions may move. Only
# what is loaded gets precompiled, and the files that were added to the depot are packed together with
# the resulting environment.
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
loaded = Set(Base.PkgId(m) for m in values(Base.loaded_modules))
pins = [PackageSpec(name=info.name, uuid=uuid) for (uuid, info) in Pkg.dependencies()
        if info.is_tracking_registry && !info.is_pinned && Base.PkgId(uuid, info.name) in loaded]
println("pinned: ", join(sort([p.name for p in pins]), ", "))
Pkg.pin(pins)
t_add = @elapsed Pkg.add(PKGS)
t_using = @elapsed @eval using LatticeQCD, PlotlyLight
println("Pkg.add: ", round(t_add), " s, using: ", round(t_using), " s")

new = sort!(collect(union((setdiff(files_under(depot, s), before[s]) for s in subs)...)))
# the precompiled files of every package loaded in this kernel, including those loaded at startup
for id in keys(Base.loaded_modules)
    origin = get(Base.pkgorigins, id, nothing)
    (origin === nothing || origin.cachepath === nothing) && continue
    startswith(origin.cachepath, depot) || continue
    for f in (origin.cachepath, splitext(origin.cachepath)[1] * ".so")
        isfile(f) && push!(new, relpath(f, depot))
    end
end
unique!(sort!(new))
println(length(new), " files to pack")

stage = joinpath(depot, "lqcd_colab_env")
mkpath(stage)
cp(joinpath(envdir, "Project.toml"), joinpath(stage, "Project.toml"); force=true)
cp(manifest, joinpath(stage, "Manifest.toml"); force=true)
write(joinpath(stage, "key.txt"), key * "\n")
write(joinpath(stage, "julia_version.txt"), string(VERSION, "\n", Sys.CPU_NAME, "\n", Sys.cpu_info()[1].model, "\n"))
push!(new, relpath(joinpath(stage, "Project.toml"), depot), relpath(joinpath(stage, "Manifest.toml"), depot),
      relpath(joinpath(stage, "key.txt"), depot), relpath(joinpath(stage, "julia_version.txt"), depot))

list = "/content/lqcd_colab_cache_files.txt"
write(list, join(new, "\n") * "\n")
tarball = "/content/lqcd_colab_cache.tar.gz"
run(`tar -czf $tarball -C $depot -T $list`)
println("key = ", key)
println("julia = ", VERSION, ", cpu = ", Sys.CPU_NAME, " (", Sys.cpu_info()[1].model, ")")
println(tarball, ": ", round(filesize(tarball) / 2^20, digits=1), " MiB")
