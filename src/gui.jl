#= import/export, consts {{{=#

export fractal!,
    move!,
    zoom!,
    change_maxiter!,
    simple_setup,
    advanced_setup

const DEFAULT_MIN_ITERS = 50
const DEFAULT_MAX_ITERS = 100000
const DEFAULT_CALC_MAXITER = n::Real -> Int(round(10^n))

#= }}}=#

#= actions {{{=#

function zoom!(fractal::AbstractFractal)
    (event::ScrollEvent, axis::Axis) -> zoom!(fractal, event, axis)
end

function zoom!(
    fractal::AbstractFractal,
    event::ScrollEvent,
    _::Axis,
)
    if event.y == 0
        return
    end
    zoom!(fractal, fractal.zoom_factor^(-event.y))
end

function move!(fractal::AbstractFractal)
    (event::MouseEvent, axis::Axis) -> move!(fractal, event, axis)
end

function move!(
    fractal::AbstractFractal,
    event::MouseEvent,
    ax::Axis,
)
    if event.type == MouseEventTypes.leftdragstart ||
       event.type == MouseEventTypes.leftdrag ||
       event.type == MouseEventTypes.leftdragstop
        px_unit = fractal.plane_size ./ tuple(ax.scene.viewport[].widths...)
        dpx = event.prev_px .- event.px
        d = (dpx[1], dpx[2])
        fractal.drag_distance = fractal.drag_distance .- px_unit .* d
        if event.type == MouseEventTypes.leftdragstop
            move!(fractal, fractal.drag_distance)
            fractal.drag_distance = (0, 0)
        end
    end
end

function change_maxiter!(
    fractal::AbstractFractal,
    calc_maxiter::Function=DEFAULT_CALC_MAXITER
)
    return function (value::Real)
        change_maxiter!(fractal, calc_maxiter(value))
    end
end

#= }}}=#

#= gui setup {{{=#

function figure(
    fractal::AbstractFractal;
    figure_args...
)::Figure
    return Figure(
        size=size(fractal.img[]),
        viewmode=:fitzoom; # no margin around axis
        figure_args...
    )
end

function clean_axis!(ax::Axis)
    hidespines!(ax)
    hidedecorations!(ax)
    tight_ticklabel_spacing!(ax) # no idea if needed
end

function simple_setup(fractal::AbstractFractal)::Tuple{Figure,Axis}
    f = figure(fractal, figure_padding=0)
    ax = Axis(f[1, 1])
    clean_axis!(ax)
    return (f, ax)
end

function simple_gui(fractal::AbstractFractal)::Figure
    f, ax = simple_setup(fractal)
    fractal!(ax, fractal)
    f
end

function advanced_setup(
    fractal::AbstractFractal;
    min_iters::Real=log10(DEFAULT_MIN_ITERS),
    max_iters::Real=log10(DEFAULT_MAX_ITERS),
    calc_maxiter::Function=DEFAULT_CALC_MAXITER,
)::Tuple{Figure,Axis}
    f = figure(fractal)
    ax = Axis(f[1:2, 1])
    b = Button(
        f[1, 2],
        label="Reset"
    )
    # TODO more vertical slider
    sl = SliderGrid(
        f[2, 2],
        (
            label="maxiter",
            format=n -> string(calc_maxiter(n)),
            range=range(min_iters, max_iters, 100 + 1),
            startvalue=log10(fractal.maxiter),
            horizontal=false,
        )
    )
    on(change_maxiter!(fractal, calc_maxiter), sl.sliders[1].value)
    on(_ -> reset!(fractal), b.clicks)
    rowsize!(sl.layout, 1, Relative(0.95))
    clean_axis!(ax)
    return f, ax
end

function advanced_gui(fractal::AbstractFractal)::Figure
    f, ax = advanced_setup(fractal)
    fractal!(ax, fractal)
    f
end

function fractal!(
    ax::Axis,
    fractal::AbstractFractal,
    refresh::Bool=true;
    static::Bool=false
)
    image!(ax, fractal.img)
    try
        deregister_interaction!(ax, :scrollzoom)
        deregister_interaction!(ax, :dragpan)
        deregister_interaction!(ax, :rectanglezoom)
        deregister_interaction!(ax, :limitreset)
    catch
    end
    try
        deregister_interaction!(ax, ZOOM_ACTION)
    catch
    end
    try
        deregister_interaction!(ax, DRAG_ACTION)
    catch
    end
    if !static
        register_interaction!(zoom!(fractal), ax, ZOOM_ACTION)
        register_interaction!(move!(fractal), ax, DRAG_ACTION)
    end
    if refresh
        update!(fractal)
    end
end

#= }}}=#
