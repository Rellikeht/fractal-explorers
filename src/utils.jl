#= definitions {{{=#

using Colors
using GLMakie

abstract type AbstractFractal end
abstract type AbstractIFractal <: AbstractFractal end

#= }}}=#

#= defaults {{{=#

const DEFAULT_VIEW_SIZE = (1920, 1080)
# just in case some gpu or vector extension isn't suited for full Ints
const DEFAULT_MAXITER = Int32(100)
const DEFAULT_COMPLEX_CENTER = 0.0 + 0im
const DEFAULT_CENTER = 0.0 + 0im
const DEFAULT_PLANE_SIZE = (1.6, 0.9) .* 2
const DEFAULT_ZOOM_FACTOR = 1.2

const ZOOM_ACTION = :scrollzoom
const DRAG_ACTION = :dragmove
const RESET_ACTION = :reset
const NAME_ACTION = :name

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
    # heuristics that look ok
    DEFAULT_MIN_OCCURRENCES = 0.0005
    DEFAULT_ITER_DIFFERENCE = 1
    DEFAULT_MAX_ITER = 10
    _iters_freq_dict::Dict{Int,Int} = Dict()
    # _sorted = []

    function _find_max_iter(
        buffer::AbstractArray{I},
        min_occurrences::Integer,
    )::I where {I<:Integer}
        empty!(_iters_freq_dict)
        # empty!(_sorted)
        for e in buffer
            _iters_freq_dict[e] = get(_iters_freq_dict, e, 0) + 1
        end
        # sort!(_sorted)
        max_iter = maximum(_iters_freq_dict)
        first_max = max_iter.first
        while true
            if max_iter.second >= min_occurrences
                return max_iter.first
            elseif length(_iters_freq_dict) > 0
                return first_max
            end
            max_iter = maximum(_iters_freq_dict)
            delete!(_iters_freq_dict, max_iter.first)
        end
    end

    function find_max_iter(
        buffer::AbstractArray{I},
        min_occurrences::Integer,
    )::Union{Nothing,I} where {I<:Integer}
        max_iter = _find_max_iter(buffer, min_occurrences)
        if max_iter <= DEFAULT_MAX_ITER ||
           max_iter - minimum(buffer) <= DEFAULT_ITER_DIFFERENCE
            return nothing
        end
        return max_iter
    end

    function find_max_iter(
        buffer::AbstractArray{<:Integer},
        min_occurrences::Real=DEFAULT_MIN_OCCURRENCES,
    )
        find_max_iter(buffer, Int(round(length(buffer) * min_occurrences)))
    end
end

#= }}}=#
