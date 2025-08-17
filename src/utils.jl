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

function blue_hsv(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    return HSV(240, 0.8, 0.1 + 0.9 * iters / maxiter)
end

function blue_white(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    return HSV(240, 0.8 - 0.8 * iters / maxiter, 0.1 + 0.8 * iters / maxiter)
end

function blue_total_white(iters::I, maxiter::I)::RGBf where {I<:Integer}
    return HSV(240, 0.8 - 0.8 * iters / maxiter, 0.1 + 0.8 * iters / maxiter)
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

find_max_iter = let
    _iters_freq_dict::Dict{Int64,Int64} = Dict()
    # _sorted = []

    function _find_max_iter(
        buffer::AbstractArray{I},
        min_occurrences::Integer,
    ) where {I<:Integer}
        empty!(_iters_freq_dict)
        # empty!(_sorted)
        for e in buffer
            if haskey(_iters_freq_dict, e)
                _iters_freq_dict[e] += 1
            else
                _iters_freq_dict[e] = 1
            end
        end
        # sort!(_sorted)
        first_max = maximum(keys(_iters_freq_dict))
        while length(_iters_freq_dict) > 0
            max_iter = maximum(keys(_iters_freq_dict))
            if _iters_freq_dict[max_iter] >= min_occurrences
                return max_iter
            end
            delete!(_iters_freq_dict, max_iter)
        end
        return first_max
    end

    function find_max_iter(
        buffer::AbstractArray{I},
        min_occurrences::Integer,
    ) where {I<:Integer}
        max_iter = _find_max_iter(buffer, min_occurrences)
        if max_iter == 0
            return 1
        end
        return max_iter
    end

    function find_max_iter(
        buffer::AbstractArray{<:Integer},
        min_occurrences::Real=0.0005,
    )
        find_max_iter(buffer, Int(round(length(buffer) * min_occurrences)))
    end
end

#= }}}=#
