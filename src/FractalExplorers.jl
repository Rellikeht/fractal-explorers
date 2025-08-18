module FractalExplorers

using GLMakie
export Observable, RGBf

export
    AbstractFractal,
    DEFAULT_CALCULATION,
    DEFAULT_MAXITER,
    DEFAULT_CENTER,
    DEFAULT_PLANE_SIZE,
    DEFAULT_VIEW_SIZE,
    DEFAULT_ZOOM_FACTOR

export
    default_hsv,
    reverse_hsv,
    simple_hsv,
    reverse_simple_hsv,
    hsv_square,
    hsv_square_dark,
    holy_moly,
    holier_moly,
    pink_storm,
    blue_yellow_white,
    byrw,
    showcase,
    dark_showcase,
    black_white,
    white_black,
    trippy,
    blue_hsv,
    blue_white,
    blue_white_faded,
    blue_total_white,
    blue_white_sqrt,
    blue_white_log,
    DEFAULT_COLOR_MAP

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
include("color_maps.jl")
include("gui.jl")
include("calculations.jl")
include("icfractal_cpu.jl")
include("icfractal.jl")

end # module FractalExplorers
