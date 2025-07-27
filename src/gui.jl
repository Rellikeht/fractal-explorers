#= imports, settings {{{=#

using Observables

const DEFAULT_MIN_ITERS = 5
const DEFAULT_MAX_ITERS = 100000

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
    calc_maxiter::Function,
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
    fig = figure(fractal, figure_padding=0)
    ax = Axis(fig[1, 1])
    clean_axis!(ax)
    return (fig, ax)
end

function simple_gui(fractal::AbstractFractal)::Figure
    fig, ax = simple_setup(fractal)
    fractal!(ax, fractal)
    return fig
end

function advanced_setup(
    fractal::AbstractFractal;
    min_iters::Real=DEFAULT_MIN_ITERS,
    max_iters::Real=DEFAULT_MAX_ITERS,
    log_slider::Bool=true,
)::Tuple{Figure,Axis,ObserverFunction,ObserverFunction}
    fig = figure(fractal)
    ax = Axis(fig[1:2, 1])
    b = Button(
        fig[1, 2],
        label="Reset"
    )
    steps = fig.scene.viewport[].widths[2] - fig.scene.viewport[].origin[2]
    if log_slider
        start_value = log10(fractal.maxiter)
        min_iters = log10(min_iters)
        max_iters = log10(max_iters)
        calc_maxiter_base = n::Real -> 10^n
    else
        start_value = fractal.maxiter
        calc_maxiter_base = identity
    end
    calc_maxiter = n::Real -> n |> calc_maxiter_base |> round |> Int
    # TODO more vertical slider
    sl = SliderGrid(
        fig[2, 2],
        (
            label="maxiter",
            format=n -> string(calc_maxiter(n)),
            range=range(min_iters, max_iters, div(steps, 2) + 1),
            startvalue=start_value,
            horizontal=false,
            update_while_dragging=false,
            linewidth=size(fractal.img[])[1] / 100
        )
    )
    on_change = on(change_maxiter!(fractal, calc_maxiter), sl.sliders[1].value)
    on_reset = on(_ -> reset!(fractal), b.clicks)
    rowsize!(sl.layout, 1, Relative(0.95))
    clean_axis!(ax)
    return fig, ax, on_change, on_reset
end

function advanced_gui(fractal::AbstractFractal; kw_args...)::Figure
    elems = advanced_setup(fractal; kw_args...)
    fractal!(elems[2], fractal)
    return elems[1]
end

function fractal!(
    ax::Axis,
    fractal::AbstractFractal,
    refresh::Bool=true;
    static::Bool=false
)
    image!(ax, fractal.img)
    is = ax |> interactions |> keys
    for interaction in [
        :scrollzoom,
        :dragpan,
        :rectanglezoom,
        :limitreset,
        ZOOM_ACTION,
        DRAG_ACTION,
    ]
        if interaction in is
            deregister_interaction!(ax, interaction)
        end
    end
    if !static
        register_interaction!(zoom!(fractal), ax, ZOOM_ACTION)
        register_interaction!(move!(fractal), ax, DRAG_ACTION)
    end
    if refresh
        recalculate!(fractal)
    end
end

#= }}}=#
