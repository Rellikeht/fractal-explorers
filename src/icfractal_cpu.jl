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
    iters_buffer::Union{Nothing,Matrix{I}}
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
    iters_buffer::Bool=false,
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
        iters_buffer ? fill(typeof(maxiter)(0), view_size) : nothing,
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
        f.iters_buffer[:, :],
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

function recalculate!(
    color_map::F1,
    calculation::F2,
    center::Complex{R1},
    img::Observable{<:Matrix{<:Color}},
    maxiter::I,
    iters_buffer::Matrix{I},
    plane_size::Tuple{R2,R2},
    params::Union{Nothing,<:NamedTuple}
) where {F1<:Function,F2<:Function,I<:Integer,R1<:Real,R2<:Real}
    img_size = R1.(size(img[]))
    @threads for i in axes(img[], 2)
        for j in axes(img[], 1)
            point = Complex{R1}(
                -center.re + plane_size[1] * (j / img_size[1] - R1(1 / 2)),
                center.im + plane_size[2] * (-i / img_size[2] + R1(1 / 2))
            )
            @inbounds iters_buffer[j, i] = calculation(point, maxiter, params)
        end
    end
    color!(
        color_map,
        img[],
        iters_buffer,
        find_max_iter(iters_buffer)
    )
    # this triggers update
    img[] = img[]
    nothing
end

function recalculate!(f::ICFractalCPU)
    if f.iters_buffer === nothing ||
       !hasproperty(f.params, :adaptive_coloring) ||
       !f.params.adaptive_coloring
        recalculate!(
            f.color_map,
            f.calculation,
            f.center,
            f.img,
            f.maxiter,
            f.plane_size,
            f.params
        )
    else
        recalculate!(
            f.color_map,
            f.calculation,
            f.center,
            f.img,
            f.maxiter,
            f.iters_buffer,
            f.plane_size,
            f.params
        )
    end
end

#= }}}=#
