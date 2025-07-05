module MandelbrotExplorer

using ..Utils
using GLMakie
using Colors
import Base.Threads: @threads
GLMakie.activate!(; framerate=60)

#= basics {{{=#

mutable struct Mandelbrot{
    F<:Function,
    C<:Color,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    # S<:Integer,
} <: AbstractFractal
    color_map::F
    img::Observable{Matrix{C}}
    # view_size::Tuple{S,S}
    maxiter::I
    center::Complex{R1}
    plane_size::Tuple{R1,R1}
    drag_distance::Tuple{R2,R2}
    zoom_factor::R2
end

function Mandelbrot(;
    view_size::Tuple{S,S}=DEFAULT_VIEW_SIZE,
    maxiter::I=DEFAULT_MAXITER,
    center::Complex{R1}=DEFAULT_CENTER,
    plane_size::Tuple{R3,R3}=DEFAULT_PLANE_SIZE,
    color_map::F=DEFAULT_COLOR_MAP,
    zoom_factor::R2=DEFAULT_ZOOM_FACTOR,
)::Mandelbrot where {
    F<:Function,
    S<:Integer,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    R3<:Real,
}
    img = Observable(fill(RGBf(0, 0, 0), view_size))
    println(typeof(img))
    return Mandelbrot(
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

# changes mandelbrot object given as first parameter in function given 
# as argument from ::Mandelbrot to ::Mandelbrot{F,C,I,R1,R2} with
# proper type parametrization
macro par_m(func)
    result = esc(:(
        function $(func.args[1].args[1])(
            $(func.args[1].args[2].args[1])::$Mandelbrot{F,C,I,R1,R2}
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

@par_m function update!(m::Mandelbrot)
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

end
