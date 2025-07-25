module FractalExplorers

using GLMakie
export Observable, RGBf, prepare!, update!

include("utils.jl")
include("gui.jl")
include("calculations.jl")
include("icfractal_cpu.jl")
include("icfractal.jl")

end # module FractalExplorers
