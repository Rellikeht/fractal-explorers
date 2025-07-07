module FractalExplorers

using GLMakie
export Observable, RGBf, prepare!, update!

include("Utils.jl")
include("MandelbrotExplorerCPU.jl")
include("MandelbrotExplorer.jl")

end # module FractalExplorers
