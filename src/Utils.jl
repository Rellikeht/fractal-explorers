module Utils
using Colors
using GLMakie

function def_hsv(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    return HSV(360 * iters / maxiter, 0.8, 1.0)
end

function black_white(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    v = 1.0 - iters / maxiter
    return RGBf(v, v, v)
end

const DEFAULT_COLOR_MAP = def_hsv
const DEFAULT_VIEW_SIZE = (1920, 1080)
const DEFAULT_MAXITER = 100
const DEFAULT_CENTER = 0.0 + 0im
const DEFAULT_PLANE_SIZE = (1.6, 0.9) .* 2
const DEFAULT_ZOOM_FACTOR = 1.1

const ZOOM_ACTION = :scrollzoom
const DRAG_ACTION = :dragmove
const RESET_ACTION = :reset

end
