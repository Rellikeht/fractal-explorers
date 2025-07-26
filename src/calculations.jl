#= setup {{{=#

export mandelbrot_calculation,
    drunkenbrot_calculation,
    test_mandelbrot_calculation

#= }}}=#

#= standard functions {{{=#

function mandelbrot_calculation(
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
        if point.re * point.re + point.im * point.im >= R(4)
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
        if point.re * point.re + point.im * point.im >= R(4)
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
        if point.re * point.re + point.im * point.im >= R(8)
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
