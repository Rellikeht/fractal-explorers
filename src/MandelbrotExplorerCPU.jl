# module MandelbrotExplorerCPU

#= basics {{{=#

mutable struct MandelbrotCPU{
    F<:Function,
    C<:Color,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    # S<:Integer,
}
    color_map::F
    img::Observable{Matrix{C}}
    # view_size::Tuple{S,S}
    maxiter::I
    center::Complex{R1}
    plane_size::Tuple{R1,R1}
    drag_distance::Tuple{R2,R2}
    zoom_factor::R2
end

function MandelbrotCPU(;
    view_size::Tuple{S,S}=DEFAULT_VIEW_SIZE,
    maxiter::I=DEFAULT_MAXITER,
    center::Complex{R1}=DEFAULT_CENTER,
    plane_size::Tuple{R3,R3}=DEFAULT_PLANE_SIZE,
    color_map::F=DEFAULT_COLOR_MAP,
    zoom_factor::R2=DEFAULT_ZOOM_FACTOR,
)::MandelbrotCPU where {
    F<:Function,
    S<:Integer,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    R3<:Real,
}
    img = Observable(fill(RGBf(0, 0, 0), view_size))
    println(typeof(img))
    return MandelbrotCPU(
        color_map,
        img,
        # view_size,
        maxiter,
        center,
        Tuple{R1,R1}(plane_size),
        (R2(0.0), R2(0.0)),
        R2(zoom_factor),
    )
end

function mandelbrot!(
    ax::Axis,
    m::MandelbrotCPU,
    static::Bool=false
)
    image!(ax, m.img)
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
        register_interaction!(zoom!(m), ax, ZOOM_ACTION)
        register_interaction!(move!(m), ax, DRAG_ACTION)
    end
    update!(m)
end

# changes mandelbrot object given as first parameter in function given 
# as argument from ::Mandelbrot to ::Mandelbrot{F,C,I,R1,R2} with
# proper type parametrization
macro par_m(func)
    result = esc(:(
        function $(func.args[1].args[1])(
            $(func.args[1].args[2].args[1])::$MandelbrotCPU{F,C,I,R1,R2}
        ) where {
            F<:Function,
            C<:Color,
            I<:Integer,
            R1<:Real,
            R2<:Real,
        }
            $(func.args[2])
        end
    ))
    return result
end

#= }}}=#

#= env setup {{{=#

function simple_setup(m::MandelbrotCPU)::Tuple{Figure,Axis}
    f = Figure(
        size=size(m.img[]),
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

function reset!(m::MandelbrotCPU)
    m.center = DEFAULT_CENTER
    m.plane_size = DEFAULT_PLANE_SIZE
    update!(m)
end

function zoom!(m::MandelbrotCPU)
    (event::ScrollEvent, axis::Axis) -> zoom!(m, event, axis)
end

function zoom!(
    m::MandelbrotCPU,
    event::ScrollEvent,
    _::Axis,
)
    if event.y == 0
        return
    end
    m.plane_size = m.plane_size .* m.zoom_factor^(-event.y)
    update!(m)
end

function move!(m::MandelbrotCPU)
    (event::MouseEvent, axis::Axis) -> move!(m, event, axis)
end

function move!(
    m::MandelbrotCPU,
    event::MouseEvent,
    _::Axis,
)
    if event.type == MouseEventTypes.leftdragstart ||
       event.type == MouseEventTypes.leftdrag ||
       event.type == MouseEventTypes.leftdragstop
        # TODO size of axis, not image
        px_unit = m.plane_size ./ size(m.img[])
        dpx = event.prev_px .- event.px
        d = (dpx[1], dpx[2])
        m.drag_distance = m.drag_distance .- px_unit .* d
        if event.type == MouseEventTypes.leftdragstop
            m.center =
                (m.center.re + m.drag_distance[1]) +
                (m.center.im + m.drag_distance[2])im
            m.drag_distance = (0, 0)
            update!(m)
        end
    end
end

#= }}}=#

#= calculation {{{=#

# z = z^2 + c
# x+yi = x^2 - y^2 +2xyi + cx + cyi
# x = x^2 - y^2 + cx
# y = (2xy + cy)i
# |z| >= 4
# x^2 + y+2 >= 4

# doesn't help
# xs, ys = point.re * point.re, point.im * point.im
# if xs + ys >= 4
#     return i
# end
# point = Complex(
#     xs - ys + start_point.re,
#     2 * point.re * point.im + start_point.im
# )

function calc_point(
    start_point::Complex{R},
    maxiter::I
)::I where {R<:Real,I<:Integer}
    point = start_point
    for i in 0:maxiter-1
        if point.re * point.re + point.im * point.im >= 4
            return i
        end
        point = point * point + start_point
    end
    return maxiter
end

@par_m function update!(m::MandelbrotCPU)
    asize = R1.(size(m.img[]))
    @time @threads for i in axes(m.img[], 2)
        # @time for i in axes(m.img[], 2)
        for j in axes(m.img[], 1)
            point = Complex{R1}(
                -m.center.re + m.plane_size[1] * (j / asize[1] - R1(1 / 2)),
                m.center.im + m.plane_size[2] * (-i / asize[2] + R1(1 / 2))
            )
            @inbounds m.img[][j, i] =
                m.color_map(calc_point(point, m.maxiter), m.maxiter)
        end
    end
    # this triggers update
    m.img[] = m.img[]
    nothing
end

#= }}}=#

# end
