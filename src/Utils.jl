module Utils

export AbstractFractal,
    def_hsv,
    black_white,
    DEFAULT_COLOR_MAP,
    DEFAULT_VIEW_SIZE,
    DEFAULT_MAXITER,
    DEFAULT_CENTER,
    DEFAULT_PLANE_SIZE,
    DEFAULT_ZOOM_FACTOR,
    fractal!
    # move!,
    # zoom!,
    # reset!,

using Colors
using GLMakie

abstract type AbstractFractal end

function def_hsv(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    return HSV(360 * iters / maxiter, 0.8, 1.0)
end

function black_white(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    v = 1.0 - iters / maxiter
    return RGBf(v, v, v)
end

const DEFAULT_COLOR_MAP = def_hsv
const DEFAULT_VIEW_SIZE = (1920, 1080)
const DEFAULT_MAXITER = 100
const DEFAULT_CENTER = 0.0 + 0im
const DEFAULT_PLANE_SIZE = (1.6, 0.9) .* 2
const DEFAULT_ZOOM_FACTOR = 1.1

const ZOOM_ACTION = :scrollzoom
const DRAG_ACTION = :dragmove
const RESET_ACTION = :reset

function fractal!(
    ax::Axis,
    fractal::AbstractFractal,
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
        deregister_interaction!(ax, DRAG_ACTION)
    catch
    end
    if !static
        register_interaction!(zoom!(fractal), ax, ZOOM_ACTION)
        register_interaction!(move!(fractal), ax, DRAG_ACTION)
    end
    update!(fractal)
end

#= env setup {{{=#

function simple_setup(fractal::AbstractFractal)::Tuple{Figure,Axis}
    f = Figure(
        size=size(fractal.img[]),
        figure_padding=0,
        viewmode=:fitzoom, # no margin around axis
    )
    ax = Axis(f[1, 1])
    hidespines!(ax)
    hidedecorations!(ax)
    tight_ticklabel_spacing!(ax) # no idea if needed
    return (f, ax)
end

#= }}}=#

#= actions {{{=#

function reset!(fractal::AbstractFractal)
    fractal.center = DEFAULT_CENTER
    fractal.plane_size = DEFAULT_PLANE_SIZE
    update!(fractal)
end

function zoom!(m::AbstractFractal)
    (event::ScrollEvent, axis::Axis) -> zoom!(m, event, axis)
end

function zoom!(
    fractal::AbstractFractal,
    event::ScrollEvent,
    _::Axis,
)
    if event.y == 0
        return
    end
    fractal.plane_size = fractal.plane_size .* fractal.zoom_factor^(-event.y)
    update!(fractal)
end

function move!(fractal::AbstractFractal)
    (event::MouseEvent, axis::Axis) -> move!(fractal, event, axis)
end

function move!(
    fractal::AbstractFractal,
    event::MouseEvent,
    _::Axis,
)
    if event.type == MouseEventTypes.leftdragstart ||
       event.type == MouseEventTypes.leftdrag ||
       event.type == MouseEventTypes.leftdragstop
        # TODO size of axis, not image
        px_unit = fractal.plane_size ./ size(fractal.img[])
        dpx = event.prev_px .- event.px
        d = (dpx[1], dpx[2])
        fractal.drag_distance = fractal.drag_distance .- px_unit .* d
        if event.type == MouseEventTypes.leftdragstop
            fractal.center =
                (fractal.center.re + fractal.drag_distance[1]) +
                (fractal.center.im + fractal.drag_distance[2])im
            fractal.drag_distance = (0, 0)
            update!(fractal)
        end
    end
end

#= }}}=#

end
