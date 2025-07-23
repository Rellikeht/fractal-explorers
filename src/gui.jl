#= env setup {{{=#

function figure(fractal::AbstractFractal)::Figure
    return Figure(
        size=size(fractal.img[]),
        figure_padding=0,
        viewmode=:fitzoom, # no margin around axis
    )
end

function clean_axis(ax::Axis)
    hidespines!(ax)
    hidedecorations!(ax)
    tight_ticklabel_spacing!(ax) # no idea if needed
end

function simple_setup(fractal::AbstractFractal)::Tuple{Figure,Axis}
    f = figure(fractal)
    ax = Axis(f[1, 1])
    clean_axis(ax)
    return (f, ax)
end

function advanced_setup(fractal::AbstractFractal)::Tuple{Figure,Axis}
    f = figure(fractal)
    ax = Axis(f[1, 1])
    # TODO reset button
    # TODO iters slider
    clean_axis(ax)
    return f, ax
end

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
    update!(fractal)
end

#= }}}=#

#= actions {{{=#

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

#= }}}=#
