#= utils {{{=#

# TODO macro to create methods for parsing params

#= }}}=#

#= mandelbrot calculation {{{=#

function mandelbrot_calculation(
    start_point::Complex,
    maxiter::Integer,
    params::Union{<:NamedTuple,Nothing},
)
    mandelbrot_calculation(
        start_point,
        maxiter,
        hasproperty(params, :start) ? params.start : typeof(start_point)(0, 0)
    )
end

function mandelbrot_calculation(
    start_point::Complex,
    maxiter::Integer,
    start::Number,
)
    mandelbrot_calculation(start_point, maxiter, typeof(start_point)(start))
end

function mandelbrot_calculation(
    calculated_point::Complex{R},
    maxiter::I,
    start_point::Complex{R},
)::I where {R<:Real,I<:Integer}
    point = calculated_point + start_point
    for i in I(0):maxiter-I(1)
        xs, ys = point.re * point.re, point.im * point.im
        if xs + ys >= R(4)
            return i
        end
        point = Complex(
            xs - ys + calculated_point.re,
            2 * point.re * point.im + calculated_point.im
        )
    end
    return maxiter
end

const DEFAULT_CALCULATION = mandelbrot_calculation

#= }}}=#

#= TODO julia calculation {{{=#

#= }}}=#

#= other {{{=#

function tricorn_calculation(
    start_point::Complex,
    maxiter::Integer,
    params::Union{<:NamedTuple,Nothing},
)
    tricorn_calculation(
        start_point,
        maxiter,
        hasproperty(params, :start) ? params.start : typeof(start_point)(0, 0)
    )
end

function tricorn_calculation(
    start_point::Complex,
    maxiter::Integer,
    start::Number,
)
    tricorn_calculation(start_point, maxiter, typeof(start_point)(start))
end

function tricorn_calculation(
    calculated_point::Complex{R},
    maxiter::I,
    start_point::Complex{R},
)::I where {R<:Real,I<:Integer}
    point = calculated_point + start_point
    for i in I(0):maxiter-I(1)
        xs, ys = point.re * point.re, point.im * point.im
        if xs + ys >= R(4)
            return i
        end
        point = Complex(
            xs - ys + calculated_point.re,
            - 2 * point.re * point.im + calculated_point.im
        )
    end
    return maxiter
end

#= }}}=#

#= beautiful bugs {{{=#

#= weird branch {{{=#

function test2_mandelbrot_calculation(
    calculated_point::Complex,
    maxiter::Integer,
    params::NamedTuple,
)
    test2_mandelbrot_calculation(
        calculated_point,
        maxiter,
        hasproperty(params, :start) ? params.start : nothing
    )
end

function test2_mandelbrot_calculation(
    calculated_point::Complex,
    maxiter::Integer,
    _::Nothing,
)
    test2_mandelbrot_calculation(
        calculated_point,
        maxiter,
        typeof(calculated_point)(0, 0)
    )
end

function test2_mandelbrot_calculation(
    calculated_point::Complex,
    maxiter::Integer,
    start::Number,
)
    test2_mandelbrot_calculation(
        calculated_point,
        maxiter,
        typeof(calculated_point)(start)
    )
end

"Weird branch"
function test2_mandelbrot_calculation(
    calculated_point::Complex{R},
    maxiter::I,
    start_point::Complex{R},
)::I where {R<:Real,I<:Integer}
    # start only moves this
    point = calculated_point + start_point
    for i in I(0):maxiter-I(1)
        if point.re * point.re + point.im * point.im >= R(16)
            return i
        end
        re, im = point.re, point.im
        point = Complex{R}(
            re * re - im * im + im,
            2 * re * im + im,
        )
    end
    return maxiter
end

#= }}}=#

#= drunkenbrot {{{=#

function drunkenbrot_calculation(
    start_point::Complex,
    maxiter::Integer,
    params::Union{<:NamedTuple,Nothing}=nothing,
)
    drunkenbrot_calculation(
        start_point,
        maxiter,
        hasproperty(params, :start) ? params.start : typeof(start_point)(0, 0)
    )
end

function drunkenbrot_calculation(
    start_point::Complex,
    maxiter::Integer,
    start::Number,
)
    drunkenbrot_calculation(
        start_point,
        maxiter,
        typeof(start_point)(start)
    )
end

function drunkenbrot_calculation(
    calculated_point::Complex{R},
    maxiter::I,
    start_point::Complex{R},
)::I where {R<:Real,I<:Integer}
    point = calculated_point + start_point
    for i in I(0):maxiter-I(1)
        if point.re * point.re + point.im * point.im >= R(9)
            return i
        end
        re, im = point.re, point.im
        re = re * re - im * im + calculated_point.re
        im = 2 * re * im + calculated_point.im
        point = Complex{R}(re, im)
    end
    return maxiter
end

#= }}}=#

# TODO name them

function test1_mandelbrot_calculation(
    start_point::Complex{R},
    maxiter::I,
    _::Union{Nothing,<:NamedTuple}=nothing,
)::I where {R<:Real,I<:Integer}
    point = start_point
    for i in I(0):maxiter-I(1)
        if point.re * point.re + point.im * point.im >= R(4)
            return i
        end
        re, im = point.re, point.im
        point = Complex{R}(
            re * re - im * im + re,
            2 * re * im,
        )
    end
    return maxiter
end

function test3_mandelbrot_calculation(
    start_point::Complex{R},
    maxiter::I,
    _::Union{Nothing,<:NamedTuple}=nothing,
)::I where {R<:Real,I<:Integer}
    point = start_point
    for i in I(0):maxiter-I(1)
        if point.re * point.re + point.im * point.im >= R(8)
            return i
        end
        re, im = point.re, point.im
        point = Complex{R}(
            re * re - im * im + im,
            re * im + im,
        )
    end
    return maxiter
end

function test4_mandelbrot_calculation(
    start_point::Complex{R},
    maxiter::I,
    _::Union{Nothing,<:NamedTuple}=nothing,
)::I where {R<:Real,I<:Integer}
    point = start_point
    for i in I(0):maxiter-I(1)
        if point.re * point.re + point.im * point.im >= R(9)
            return i
        end
        re, im = point.re, point.im
        re = re * re + im * im + start_point.re
        im = 2 * im * re + start_point.im
        point = Complex{R}(re, im)
    end
    return maxiter
end

#= }}}=#
