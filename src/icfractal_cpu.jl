#= imports and settings {{{=#

using GLMakie
using Colors
import Base.Threads: @threads
GLMakie.activate!(; framerate=60)

#= }}}=#

#= setup {{{=#

"
Iterated Complex Fractal built for cpu calculations
"
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
    params::Union{Nothing,<:NamedTuple}
end

function ICFractalCPU(;
    color_map::F1 where {F1<:Function}=DEFAULT_COLOR_MAP,
    calculation::F2 where {F2<:Function}=DEFAULT_CALCULATION,
    view_size::Tuple{S,S}=DEFAULT_VIEW_SIZE,
    maxiter::Integer=DEFAULT_MAXITER,
    center::Complex{<:Real}=DEFAULT_CENTER,
    plane_size::Tuple{R1,R1}=DEFAULT_PLANE_SIZE,
    zoom_factor::Real=DEFAULT_ZOOM_FACTOR,
    params::Union{Nothing,<:NamedTuple}=nothing,
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

function transform_float_type(
    f::ICFractalCPU,
    new_type::Type{<:Complex{R}} where {R<:Real}
)::ICFractalCPU
    R = new_type.parameters[1]
    ICFractalCPU(
        f.color_map,
        f.calculation,
        Observable(f.img[][:, :]),
        f.maxiter,
        new_type(f.center),
        R.(f.plane_size),
        f.drag_distance,
        f.zoom_factor,
        f.params
    )
end

function transform_float_type(
    f::ICFractalCPU,
    new_type::Type{<:Real}
)::ICFractalCPU
    transform_float_type(f, Complex{new_type})
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
    color_map::F1,
    calculation::F2,
    center::Complex{R1},
    img::Observable{<:Matrix{<:Color}},
    maxiter::Integer,
    plane_size::Tuple{R2,R2},
    params::Union{Nothing,<:NamedTuple}
) where {F1<:Function,F2<:Function,R1<:Real,R2<:Real}
    img_size = R1.(size(img[]))
    @threads for i in axes(img[], 2)
        for j in axes(img[], 1)
            point = Complex{R1}(
                -center.re + plane_size[1] * (j / img_size[1] - R1(1 / 2)),
                center.im + plane_size[2] * (-i / img_size[2] + R1(1 / 2))
            )
            @inbounds img[][j, i] = color_map(calculation(point, maxiter, params), maxiter)
        end
    end
    # this triggers update
    img[] = img[]
    nothing
end

function recalculate!(m::ICFractalCPU)
    recalculate!(
        m.color_map,
        m.calculation,
        m.center,
        m.img,
        m.maxiter,
        m.plane_size,
        m.params
    )
end

#= }}}=#
