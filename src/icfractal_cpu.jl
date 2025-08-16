#= imports and settings {{{=#

using GLMakie
using Colors
import Base.Threads: @threads
GLMakie.activate!(; framerate=60)

#= }}}=#

#= setup {{{=#

mutable struct ICFractalCPU{
    C<:Color,
    I<:Integer,
    R1<:Real,
    R2<:Real,
} <: AbstractIFractal
    color_map::F1 where {F1<:Function}
    calculation::F2 where {F2<:Function}
    img::Observable{Matrix{C}}
    maxiter::I
    center::Complex{R1}
    plane_size::Tuple{R1,R1}
    drag_distance::Tuple{R2,R2}
    zoom_factor::Real
    params
end

function ICFractalCPU(;
    color_map::F1 where {F1<:Function}=DEFAULT_COLOR_MAP,
    calculation::F2 where {F2<:Function}=DEFAULT_CALCULATION,
    view_size::Tuple{S,S}=DEFAULT_VIEW_SIZE,
    maxiter::Integer=DEFAULT_MAXITER,
    center::Complex{<:Real}=DEFAULT_CENTER,
    plane_size::Tuple{R1,R1}=DEFAULT_PLANE_SIZE,
    zoom_factor::Real=DEFAULT_ZOOM_FACTOR,
    params=nothing,
)::ICFractalCPU where {
    S<:Integer,
    R1<:Real,
}
    img = Observable(fill(RGBf(0, 0, 0), view_size))
    R2 = typeof(center).parameters[1]
    return ICFractalCPU(
        color_map,
        calculation,
        img,
        maxiter,
        center,
        Tuple{R1,R1}(plane_size),
        (R2(0.0), R2(0.0)),
        zoom_factor,
        params,
    )
end

#= }}}=#

#= calculations {{{=#

function move!(
    fractal::ICFractalCPU,
    amount::Complex{<:Real},
)
    fractal.center += amount
    recalculate!(fractal)
end

function recalculate!(
    m::ICFractalCPU{C,I,R1,R2},
    color_map::F1,
    calculation::F2,
) where {C,I,R1,R2,F1<:Function,F2<:Function}
    img_size = R1.(size(m.img[]))
    @threads for i in axes(m.img[], 2)
        for j in axes(m.img[], 1)
            point = Complex{R1}(
                -m.center.re + m.plane_size[1] * (j / img_size[1] - R1(1 / 2)),
                m.center.im + m.plane_size[2] * (-i / img_size[2] + R1(1 / 2))
            )
            @inbounds m.img[][j, i] = color_map(calculation(point, m.maxiter), m.maxiter)
        end
    end
    # this triggers update
    m.img[] = m.img[]
    nothing
end

function recalculate!(m::ICFractalCPU{C,I,R1,R2}) where {C,I,R1,R2}
    recalculate!(m, m.color_map, m.calculation)
end

#= }}}=#
