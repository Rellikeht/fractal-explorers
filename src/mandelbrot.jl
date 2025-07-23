#= import/export {{{=#

using GLMakie
using Colors
import Base.Threads: @threads
GLMakie.activate!(; framerate=60)

export Mandelbrot,
    update!,
    prepare!,
    calc_point

#= }}}=#

#= basics {{{=#

mutable struct Mandelbrot{
    C<:Color,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    B1<:AbstractMatrix{Complex{R1}},
    B2<:AbstractMatrix{I},
    B3<:AbstractMatrix{I},
} <: AbstractFractal
    color_map::F where {F<:Function}
    img::Observable{Matrix{C}}
    maxiter::I
    center::Complex{R1}
    plane_size::Tuple{R1,R1}
    drag_distance::Tuple{R2,R2}
    zoom_factor::R2
    coords_buffer::B1
    iters_in_buffer::B2
    iters_out_buffer::B3
end

function Mandelbrot(;
    view_size::Tuple{S,S}=DEFAULT_VIEW_SIZE,
    maxiter::I=DEFAULT_MAXITER,
    center::Complex{R1}=DEFAULT_CENTER,
    plane_size::Tuple{R3,R3}=DEFAULT_PLANE_SIZE,
    color_map::F where {F<:Function}=DEFAULT_COLOR_MAP,
    zoom_factor::R2=DEFAULT_ZOOM_FACTOR,
    coords_buffer::Union{<:AbstractMatrix{Complex{R1}},Nothing}=nothing,
)::Mandelbrot where {
    S<:Integer,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    R3<:Real,
}
    img = Observable(fill(RGBf(0, 0, 0), view_size))
    if coords_buffer === nothing
        coords_buffer = Matrix{Complex{R1}}(undef, view_size)
    end
    iters_buffer = zeros(I, view_size)
    return Mandelbrot(
        color_map,
        img,
        maxiter,
        center,
        Tuple{R1,R1}(plane_size),
        (R2(0.0), R2(0.0)),
        R2(zoom_factor),
        coords_buffer,
        iters_buffer,
        iters_buffer
    )
end

#= }}}=#

#= calculation {{{=#

function prepare!(
    coords_buffer::Matrix{Complex{R1}},
    img_size::Tuple{R1,R1},
    center::Complex{R1},
    plane_size::Tuple{R2,R2}
) where {R1<:Real,R2<:Real}
    bsize = size(coords_buffer)
    @threads for i in axes(coords_buffer, 2)
        for j in axes(coords_buffer, 1)
            @inbounds coords_buffer[j, i] = Complex{R1}(
                -center.re + plane_size[1] * (j / img_size[1] - R1(1 / 2)),
                center.im + plane_size[2] * (-i / img_size[2] + R1(1 / 2))
            )
        end
    end
end

# By default uses calc_point from CPU
function update!(
    coords_buffer::Matrix{Complex{R}},
    iters_in_buffer::Matrix{I},
    _::Matrix{I},
    maxiter::I
) where {R<:Real,I<:Integer}
    @threads for i in eachindex(coords_buffer)
        @inbounds iters_in_buffer[i] = calc_point(coords_buffer[i], maxiter)
    end
end

function color!(
    color_map::F,
    img::Matrix{RGBf},
    iters_buffer::Matrix{I},
    maxiter::I
) where {F<:Function,I<:Integer}
    @threads for i in eachindex(iters_buffer)
        @inbounds img[i] = color_map(iters_buffer[i], maxiter)
    end
end

function update!(m::Mandelbrot{C,I,R1,R2,B1,B2}) where {C,I,R1,R2,B1,B2}
    prepare!(m.coords_buffer, R1.(size(m.img[])), m.center, m.plane_size)
    update!(m.coords_buffer, m.iters_in_buffer, m.iters_out_buffer, m.maxiter)
    color!(m.color_map, m.img[], m.iters_out_buffer, m.maxiter)
    # trigger update
    m.img[] = m.img[]
    nothing
end

#= }}}=#
