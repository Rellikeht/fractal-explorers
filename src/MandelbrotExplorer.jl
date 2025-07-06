#= import/export {{{=#

using GLMakie
using Colors
import Base.Threads: @threads
GLMakie.activate!(; framerate=60)

export Mandelbrot,
    update!,
    calc_point

#= }}}=#

#= basics {{{=#

mutable struct Mandelbrot{
    F<:Function,
    C<:Color,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    B1<:AbstractMatrix{Complex{R1}},
    B2<:AbstractMatrix{I},
} <: AbstractFractal
    color_map::F
    img::Observable{Matrix{C}}
    maxiter::I
    center::Complex{R1}
    plane_size::Tuple{R1,R1}
    drag_distance::Tuple{R2,R2}
    zoom_factor::R2
    buffer_in::B1
    buffer_out::B2
end

function Mandelbrot(;
    view_size::Tuple{S,S}=DEFAULT_VIEW_SIZE,
    maxiter::I=DEFAULT_MAXITER,
    center::Complex{R1}=DEFAULT_CENTER,
    plane_size::Tuple{R3,R3}=DEFAULT_PLANE_SIZE,
    color_map::F=DEFAULT_COLOR_MAP,
    zoom_factor::R2=DEFAULT_ZOOM_FACTOR,
    buffer_in::Union{B,Nothing}=nothing,
)::Mandelbrot where {
    F<:Function,
    S<:Integer,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    R3<:Real,
    B<:AbstractMatrix{<:Complex{R1}},
}
    img = Observable(fill(RGBf(0, 0, 0), view_size))
    if buffer_in === nothing
        buffer_in = Matrix{Complex{R1}}(undef, view_size)
    end
    return Mandelbrot(
        color_map,
        img,
        maxiter,
        center,
        Tuple{R1,R1}(plane_size),
        (R2(0.0), R2(0.0)),
        R2(zoom_factor),
        buffer_in,
        zeros(I, view_size)
    )
end

#= }}}=#

#= calculation {{{=#

# By default uses calc_point from CPU
function update!(
    buffer_in::Matrix{Complex{R}},
    buffer_out::Matrix{I},
    maxiter::I
) where {R<:Real,I<:Integer}
    @threads for i in eachindex(buffer_in)
        @inbounds buffer_out[i] = calc_point(buffer_in[i], maxiter)
    end
end

function update!(m::Mandelbrot{F,C,I,R1,R2,B1,B2}) where {F,C,I,R1,R2,B1,B2}
    asize = R1.(size(m.img[]))
    @threads for i in axes(m.img[], 2)
        for j in axes(m.img[], 1)
            @inbounds m.buffer_in[j, i] = Complex{R1}(
                -m.center.re + m.plane_size[1] * (j / asize[1] - R1(1 / 2)),
                m.center.im + m.plane_size[2] * (-i / asize[2] + R1(1 / 2))
            )
        end
    end
    update!(m.buffer_in, m.buffer_out, m.maxiter)
    @threads for i in eachindex(m.buffer_out)
        @inbounds m.img[][i] = m.color_map(m.buffer_out[i], m.maxiter)
    end
    # this triggers update
    m.img[] = m.img[]
    nothing
end

#= }}}=#
