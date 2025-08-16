module FractalExplorers

using GLMakie
export Observable, RGBf

export
    AbstractFractal,
    default_hsv,
    reverse_hsv,
    simple_hsv,
    reverse_simple_hsv,
    black_white,
    white_black,
    trippy,
    blue_hsv,
    blue_white,
    blue_total_white,
    DEFAULT_COLOR_MAP,
    DEFAULT_CALCULATION,
    DEFAULT_MAXITER,
    DEFAULT_CENTER,
    DEFAULT_PLANE_SIZE,
    DEFAULT_VIEW_SIZE,
    DEFAULT_ZOOM_FACTOR

export
    fractal!,
    move!,
    zoom!,
    reset!,
    change_maxiter!,
    transform_float_type,
    transform_float_type!,
    simple_setup,
    advanced_setup,
    simple_gui,
    advanced_gui

export
    DEFAULT_CALCULATION,
    mandelbrot_calculation,
    drunkenbrot_calculation,
    test1_mandelbrot_calculation,
    test2_mandelbrot_calculation,
    test3_mandelbrot_calculation,
    test4_mandelbrot_calculation

export
    ICFractal,
    ICFractalCPU,
    transform_float_type,
    recalculate!,
    prepare!,
    color!,
    change_maxiter!

include("utils.jl")
include("gui.jl")
include("calculations.jl")
include("icfractal_cpu.jl")
include("icfractal.jl")

end # module FractalExplorers
