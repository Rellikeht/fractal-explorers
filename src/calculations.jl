export mandelbrot_calculation,
    drunkenbrot_calculation,
    heart_mandelbrot_calculation

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

function triple_mandelbrot_calculation(
    start_point::Complex{R},
    maxiter::I
)::I where {R<:Real,I<:Integer}
    point = start_point
    for i in I(0):maxiter-I(1)
        if point.re * point.re + point.im * point.im >= R(4)
            return i
        end
        point = point * point + start_point
        point = point * point
    end
    return maxiter
end

# TODO julia set

const DEFAULT_CALCULATION = mandelbrot_calculation
