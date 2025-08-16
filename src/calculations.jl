#= standard functions {{{=#

function mandelbrot_calculation(
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

function _mandelbrot_calculation(
    start_point::Complex{N},
    maxiter::I
)::I where {N<:Real,I<:Integer}
    point = start_point
    temp = start_point
    n = I(20)
    iters = 0
    for _ in I(1):div(maxiter, n)
        for _ in I(1):n
            temp = temp * temp + start_point
        end
        if isnan(temp) || temp.re * temp.re + temp.im * temp.im >= N(4)
            for i in I(0):n-I(1)
                xs, ys = point.re * point.re, point.im * point.im
                if xs + ys >= N(4)
                    return iters + i
                end
                point = Complex(
                    xs - ys + start_point.re,
                    2 * point.re * point.im + start_point.im
                )
            end
        end
        point = temp
        iters += n
    end
    xs, ys = point.re * point.re, point.im * point.im
    for i in I(0):rem(maxiter, n)-I(2)
        xs, ys = point.re * point.re, point.im * point.im
        if xs + ys >= N(4)
            return iters + i
        end
        point = Complex(
            xs - ys + start_point.re,
            2 * point.re * point.im + start_point.im
        )
        point = point * point + start_point
    end
    if xs + ys >= N(4)
        return maxiter - I(1)
    end
    return maxiter
end

# TODO julia set

const DEFAULT_CALCULATION = mandelbrot_calculation

#= }}}=#

#= beautiful bugs {{{=#

function drunkenbrot_calculation(
    start_point::Complex{R},
    maxiter::I
)::I where {R<:Real,I<:Integer}
    point = start_point
    for i in I(0):maxiter-I(1)
        if point.re * point.re + point.im * point.im >= R(9)
            return i
        end
        re, im = point.re, point.im
        re = re * re - im * im + start_point.re
        im = 2 * re * im + start_point.im
        point = Complex{R}(re, im)
    end
    return maxiter
end

# TODO name them

function test1_mandelbrot_calculation(
    start_point::Complex{R},
    maxiter::I
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

function test2_mandelbrot_calculation(
    start_point::Complex{R},
    maxiter::I
)::I where {R<:Real,I<:Integer}
    point = start_point
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

function test3_mandelbrot_calculation(
    start_point::Complex{R},
    maxiter::I
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
    maxiter::I
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
