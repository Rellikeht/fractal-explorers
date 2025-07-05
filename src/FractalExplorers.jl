module FractalExplorers

using GLMakie
using Colors
GLMakie.activate!(; framerate=60)

include("Utils.jl")
include("MandelbrotExplorerCPU.jl")
include("MandelbrotExplorer.jl")

end
