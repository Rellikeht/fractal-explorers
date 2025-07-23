module FractalExplorers

using GLMakie
export Observable, RGBf, prepare!, update!

include("utils.jl")
include("gui.jl")
include("mandelbrot_cpu.jl")
include("mandelbrot.jl")

end # module FractalExplorers
