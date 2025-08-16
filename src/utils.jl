#= definitions {{{=#

using Colors
using GLMakie

abstract type AbstractFractal end
abstract type AbstractIFractal <: AbstractFractal end

#= }}}=#

#= colors {{{=#

function simple_hsv(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    return HSV(360 * iters / maxiter, 0.8, 1.0)
end

function reverse_simple_hsv(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    return HSV(360 * (maxiter - iters) / maxiter, 0.8, 1.0)
end

function black_white(iters::I, maxiter::I)::RGBf where {I<:Integer}
    v = 1.0 - iters / maxiter
    return RGBf(v, v, v)
end

function white_black(iters::I, maxiter::I)::RGBf where {I<:Integer}
    return RGBf(iters / maxiter, iters / maxiter, iters / maxiter)
end

function default_hsv(iters::I, maxiter::I)::RGBf where {I<:Integer}
    start = 250
    stop = -30
    hue = start + (stop - start) * iters / maxiter
    return HSV(hue, 0.8, iters != maxiter)
end

function reverse_hsv(iters::I, maxiter::I)::RGBf where {I<:Integer}
    start = -30
    stop = 250
    hue = start + (stop - start) * iters / maxiter
    return HSV(hue, 0.8, iters != maxiter)
end

function trippy(iters::I, maxiter::I)::RGBf where {I<:Integer}
    return HSV(
        (maxiter - iters) / (iters + 1) * 360,
        0.8,
        iters != maxiter,
    )
end

#= }}}=#

#= defaults {{{=#

const DEFAULT_COLOR_MAP = default_hsv
const DEFAULT_VIEW_SIZE = (1920, 1080)
const DEFAULT_MAXITER = 100
const DEFAULT_COMPLEX_CENTER = 0.0 + 0im
const DEFAULT_CENTER = 0.0 + 0im
const DEFAULT_PLANE_SIZE = (1.6, 0.9) .* 2
const DEFAULT_ZOOM_FACTOR = 1.2

const ZOOM_ACTION = :scrollzoom
const DRAG_ACTION = :dragmove
const RESET_ACTION = :reset
const FRACTAL_ACTION = :fractal

#= }}}=#

#= utilities {{{=#

function reset!(fractal::AbstractFractal)
    # TODO how to properly implement this
    # fractal.center = DEFAULT_CENTER
    # fractal.plane_size = DEFAULT_PLANE_SIZE
    recalculate!(fractal)
end

function GLMakie.save(name::String, fractal::AbstractFractal)
    GLMakie.save(name, rotl90(fractal.img[]))
end

macro supress_err(block)
    return quote
        try
            $block
        catch
        end
    end
end

#= }}}=#
