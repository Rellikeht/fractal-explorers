#= import/export {{{=#

using GLMakie
using Colors
import Base.Threads: @threads
GLMakie.activate!(; framerate=60)

export MandelbrotCPU,
    update!,
    calc_point

#= }}}=#

#= setup {{{=#

mutable struct MandelbrotCPU{
    C<:Color,
    I<:Integer,
    R1<:Real,
    R2<:Real,
} <: AbstractFractal
    color_map::F where {F<:Function}
    img::Observable{Matrix{C}}
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
    color_map::F where {F<:Function}=DEFAULT_COLOR_MAP,
    zoom_factor::R2=DEFAULT_ZOOM_FACTOR,
)::MandelbrotCPU where {
    S<:Integer,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    R3<:Real,
}
    img = Observable(fill(RGBf(0, 0, 0), view_size))
    return MandelbrotCPU(
        color_map,
        img,
        maxiter,
        center,
        Tuple{R1,R1}(plane_size),
        (R2(0.0), R2(0.0)),
        R2(zoom_factor),
    )
end

#= }}}=#

#= calculation {{{=#

function calc_point(
    start_point::Complex{R},
    maxiter::I
)::I where {R<:Real,I<:Integer}
    point = start_point
    for i in I(0):maxiter-I(1)
        if point.re * point.re + point.im * point.im >= R(4)
            return i
        end
        point = point * point + start_point
    end
    return maxiter
end

function update!(
    m::MandelbrotCPU{C,I,R1,R2},
    color_map::F,
) where {C,I,R1,R2,F<:Function}
    img_size = R1.(size(m.img[]))
    @threads for i in axes(m.img[], 2)
        for j in axes(m.img[], 1)
            point = Complex{R1}(
                -m.center.re + m.plane_size[1] * (j / img_size[1] - R1(1 / 2)),
                m.center.im + m.plane_size[2] * (-i / img_size[2] + R1(1 / 2))
            )
            @inbounds m.img[][j, i] = color_map(calc_point(point, m.maxiter), m.maxiter)
        end
    end
    # this triggers update
    m.img[] = m.img[]
    nothing
end

function update!(m::MandelbrotCPU{C,I,R1,R2}) where {C,I,R1,R2}
    update!(m, m.color_map)
end

#= }}}=#
