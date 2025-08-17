#= imports and settings {{{=#

using GLMakie
using Colors
import Base.Threads: @threads
GLMakie.activate!(; framerate=60)

#= }}}=#

#= basics {{{=#

"
Iterated Complex Fractal
"
mutable struct ICFractal{
    C<:Color,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    B1<:AbstractMatrix{Complex{R1}},
    B2<:AbstractMatrix{I},
    B3<:AbstractMatrix{I},
} <: AbstractIFractal
    color_map::F1 where {F1<:Function}
    calculation::F2 where {F2<:Function}
    img::Observable{Matrix{C}}
    maxiter::I
    center::Complex{R1}
    plane_size::Tuple{R1,R1}
    drag_distance::Tuple{R2,R2}
    zoom_factor::Real
    coords_buffer::B1
    iters_in_buffer::B2
    iters_out_buffer::B3
    params::Union{Nothing,<:NamedTuple}
end

function ICFractal(;
    color_map::Function=DEFAULT_COLOR_MAP,
    calculation::Function=DEFAULT_CALCULATION,
    view_size::Tuple{S,S}=DEFAULT_VIEW_SIZE,
    maxiter::Integer=DEFAULT_MAXITER,
    center::Complex{R1}=DEFAULT_CENTER,
    plane_size::Tuple{R2,R2}=DEFAULT_PLANE_SIZE,
    zoom_factor::Real=DEFAULT_ZOOM_FACTOR,
    coords_buffer::Union{<:AbstractMatrix{Complex{R1}},Nothing}=nothing,
    params::Union{Nothing,<:NamedTuple}=nothing
)::ICFractal where {
    S<:Integer,
    R1<:Real,
    R2<:Real,
}
    img = Observable(fill(RGBf(0, 0, 0), view_size))
    if coords_buffer === nothing
        coords_buffer = Matrix{Complex{R1}}(undef, view_size)
    end
    iters_buffer = zeros(typeof(maxiter), view_size)
    return ICFractal(
        color_map,
        calculation,
        img,
        maxiter,
        center,
        Tuple{R1,R1}(plane_size),
        (R2(0.0), R2(0.0)),
        zoom_factor,
        coords_buffer,
        iters_buffer,
        iters_buffer,
        params,
    )
end

function transform_float_type(
    f::ICFractal,
    new_type::Type{<:Complex{R}} where {R<:Real}
)::ICFractal
    R = new_type.parameters[1]
    ICFractal(
        f.color_map,
        f.calculation,
        Observable(f.img[][:, :]),
        f.maxiter,
        new_type(f.center),
        R.(f.plane_size),
        f.drag_distance,
        f.zoom_factor,
        new_type.(f.coords_buffer),
        f.iters_in_buffer[:, :],
        f.iters_out_buffer[:, :],
        f.params
    )
end

function transform_float_type(
    f::ICFractal,
    new_type::Type{<:Real}
)::ICFractal
    transform_float_type(f, Complex{new_type})
end

#= }}}=#

#= actions {{{=#

function zoom!(
    fractal::AbstractIFractal,
    factor::Real,
)
    fractal.plane_size = fractal.plane_size .* factor
    recalculate!(fractal)
end

function move!(
    fractal::AbstractIFractal,
    amount::Tuple{N,N}
) where {N<:Real}
    fractal.center =
        (fractal.center.re + amount[1]) +
        (fractal.center.im + amount[2])im
    recalculate!(fractal)
end

function move!(
    fractal::ICFractal,
    amount::Complex{<:Real},
)
    fractal.center += amount
    recalculate!(fractal)
end

function change_maxiter!(
    fractal::AbstractIFractal,
    maxiter::Integer
)
    fractal.maxiter = maxiter
    recalculate!(fractal)
end

#= }}}=#

#= calculation {{{=#

function prepare!(
    coords_buffer::Matrix{Complex{R}},
    img_size::Tuple{R,R},
    center::Complex{R},
    plane_size::Tuple{R,R}
) where {R<:Real}
    # bsize = size(coords_buffer)
    @threads for i in axes(coords_buffer, 2)
        for j in axes(coords_buffer, 1)
            @inbounds coords_buffer[j, i] = Complex{R}(
                -center.re + plane_size[1] * (j / img_size[1] - R(1 / 2)),
                center.im + plane_size[2] * (-i / img_size[2] + R(1 / 2))
            )
        end
    end
end

function recalculate!(
    coords_buffer::Matrix{Complex{R}},
    calculation::F,
    iters_in_buffer::Matrix{I},
    _::Matrix{I},
    maxiter::I,
    params::Union{Nothing,<:NamedTuple}
) where {R<:Real,I<:Integer,F<:Function}
    @threads for i in eachindex(coords_buffer)
        @inbounds iters_in_buffer[i] = calculation(coords_buffer[i], maxiter, params)
    end
end

function color!(f::ICFractal)
    # for testing purposes
    if hasproperty(f.params, :adaptive_coloring) && f.params.adaptive_coloring
        color!(
            f.color_map,
            f.img[],
            f.iters_out_buffer,
            maximum(f.iters_out_buffer)
        )
    else
        color!(f.color_map, f.img[], f.iters_out_buffer, f.maxiter)
    end
end

function color!(
    color_map::F,
    img::Matrix{RGBf},
    iters_buffer::Matrix{I},
    maxiter::I
) where {F<:Function,I<:Integer}
    # scheduler can do this suprisingly well
    @threads for i in eachindex(iters_buffer)
        @inbounds img[i] = color_map(iters_buffer[i], maxiter)
    end
end

function recalculate!(f::ICFractal)
    R = typeof(f.center).parameters[1]
    prepare!(f.coords_buffer, R.(size(f.img[])), f.center, f.plane_size)
    recalculate!(
        f.coords_buffer,
        f.calculation,
        f.iters_in_buffer,
        f.iters_out_buffer,
        f.maxiter,
        f.params
    )
    color!(f)
    # trigger update
    f.img[] = f.img[]
    nothing
end

#= }}}=#
