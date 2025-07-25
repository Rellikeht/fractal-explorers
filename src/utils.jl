#= import/export {{{=#

export AbstractFractal,
    def_hsv,
    fhsv,
    rhsv,
    black_white,
    white_black

using Colors
using GLMakie

#= }}}=#

#= colors {{{=#

function fhsv(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    return HSV(360 * iters / maxiter, 0.8, 1.0)
end

function rhsv(iters::I, maxiter::I)::RGBf where {I<:Integer}
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

const def_hsv = rhsv

#= }}}=#

#= setup {{{=#

abstract type AbstractFractal end
abstract type AbstractIFractal <: AbstractFractal end

const DEFAULT_COLOR_MAP = def_hsv
const DEFAULT_VIEW_SIZE = (1920, 1080)
const DEFAULT_MAXITER = 100
const DEFAULT_COMPLEX_CENTER = 0.0 + 0im
const DEFAULT_CENTER = 0.0 + 0im
const DEFAULT_PLANE_SIZE = (1.6, 0.9) .* 2
const DEFAULT_ZOOM_FACTOR = 1.1

const ZOOM_ACTION = :scrollzoom
const DRAG_ACTION = :dragmove
const RESET_ACTION = :reset

#= }}}=#

#= other {{{=#

function reset!(fractal::AbstractFractal)
    # TODO how to properly implement this
    # fractal.center = DEFAULT_CENTER
    # fractal.plane_size = DEFAULT_PLANE_SIZE
    update!(fractal)
end

function GLMakie.save(name::String, fractal::AbstractFractal)
    GLMakie.save(name, rotl90(fractal.img[]))
end

#= }}}=#
