module FractalExplorersCuda

using CUDA
using FractalExplorers

export CUDAMandelbrot, update!, prepare!, max_therads

function CUDAMandelbrot(;
    view_size::Tuple{S,S}=DEFAULT_VIEW_SIZE,
    maxiter::I=Int32(DEFAULT_MAXITER),
    center::Complex{R1}=DEFAULT_CENTER,
    plane_size::Tuple{R3,R3}=DEFAULT_PLANE_SIZE,
    color_map::F where {F<:Function}=DEFAULT_COLOR_MAP,
    zoom_factor::R2=DEFAULT_ZOOM_FACTOR,
    coords_buffer::Union{CuMatrix{Complex{R1}},Nothing}=nothing,
    iters_in_buffer::Union{CuMatrix{I},Nothing}=nothing,
)::Mandelbrot where {
    S<:Integer,
    I<:Integer,
    R1<:Real,
    R2<:Real,
    R3<:Real,
}
    img = Observable(fill(RGBf(0, 0, 0), view_size))
    if coords_buffer === nothing
        coords_buffer = CUDA.zeros(Complex{R1}, view_size)
    end
    if iters_in_buffer === nothing
        iters_in_buffer = CUDA.zeros(I, view_size)
    end
    return Mandelbrot(
        color_map,
        img,
        maxiter,
        center,
        Tuple{R1,R1}(plane_size),
        (R2(0.0), R2(0.0)),
        R2(zoom_factor),
        coords_buffer,
        iters_in_buffer,
        zeros(I, view_size)
    )
end

function max_therads(
    N::I,
    kernf::F,
    args...
) where {F,I<:Integer}
    # https://cuda.juliagpu.org/stable/tutorials/introduction/#Writing-a-parallel-GPU-kernel
    kernel = @cuda launch = false kernf(args...)
    config = launch_configuration(kernel.fun)
    threads = min(N, config.threads)
    blocks = cld(N, threads)
    return (blocks, threads)
end

function max_therads(m::Mandelbrot)
    max_therads(
        length(m.iters_out_buffer),
        cuda_update!,
        m.coords_buffer,
        m.iters_in_buffer,
        m.maxiter,
    )
end

function FractalExplorers.prepare!(
    buffer::B,
    asize::Tuple{R1,R1},
    center::Complex{R1},
    plane_size::Tuple{R2,R2}
) where {
    B<:Union{CuMatrix{Complex{R1}},CuDeviceMatrix{Complex{R1}}},
} where {
    R1<:Real,
    R2<:Real
}
    nblocks, threads = max_therads(
        length(buffer),
        cuda_prepare!,
        buffer,
        asize,
        center,
        plane_size
    )
    CUDA.@sync @cuda threads = threads blocks = nblocks cuda_prepare!(
        buffer,
        asize,
        center,
        plane_size
    )
end

function cuda_prepare!(
    coords_buffer::B,
    asize::Tuple{R1,R1},
    center::Complex{R1},
    plane_size::Tuple{R2,R2}
) where {
    B<:Union{CuMatrix{Complex{R1}},CuDeviceMatrix{Complex{R1}}}
} where {R1<:Real,R2<:Real}
    bsize = Int32.(size(coords_buffer))
    k = (blockIdx().x - Int32(1)) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    @inbounds while k <= Int32(length(coords_buffer))
        i, j = divrem(k - 1, bsize[1]) .+ 1
        coords_buffer[j, i] = Complex{R1}(
            -center.re + plane_size[1] * (j / asize[1] - R1(1 / 2)),
            center.im + plane_size[2] * (-i / asize[2] + R1(1 / 2))
        )
        k += stride
    end
end

function FractalExplorers.update!(
    coords_buffer::B1,
    iters_in_buffer::B2,
    iters_out_buffer::Matrix{I},
    maxiter::I
) where {
    B1<:Union{CuMatrix{Complex{R}},CuDeviceMatrix{Complex{R}}},
    B2<:Union{CuMatrix{I},CuDeviceMatrix{I}}
} where {R<:Real,I<:Integer}
    nblocks, threads = max_therads(
        length(coords_buffer),
        cuda_update!,
        coords_buffer,
        iters_in_buffer,
        maxiter
    )
    CUDA.@sync @cuda threads = threads blocks = nblocks always_inline = true cuda_update!(
        coords_buffer,
        iters_in_buffer,
        maxiter
    )
    copyto!(iters_out_buffer, iters_in_buffer)
end

function cuda_update!(
    coords_buffer::B1,
    iters_buffer::B2,
    maxiter::I
) where {
    B1<:Union{CuMatrix{Complex{R}},CuDeviceMatrix{Complex{R}}},
    B2<:Union{CuMatrix{I},CuDeviceMatrix{I}},
} where {R<:Real,I<:Integer}
    i = (blockIdx().x - Int32(1)) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    @inbounds while i < Int32(length(coords_buffer))
        iters_buffer[i] = cuda_calc_point(
            coords_buffer[i],
            maxiter
        )
        i += stride
    end
    return nothing
end

# z = z^2 + c
# x+yi = x^2 - y^2 +2xyi + cx + cyi
# x = x^2 - y^2 + cx
# y = (2xy + cy)i
# |z| >= 4
# x^2 + y+2 >= 4

function cuda_calc_point(
    start_point::Complex{R},
    maxiter::I
)::I where {R<:Real,I<:Integer}
    point = start_point
    for i in I(0):maxiter-I(1)
        xs, ys = point.re * point.re, point.im * point.im
        if xs + ys >= R(4)
            return i
        end
        point = Complex(
            xs - ys + start_point.re,
            2 * point.re * point.im + start_point.im
        )
    end
    return maxiter
end

end # module FractalExplorersCuda
