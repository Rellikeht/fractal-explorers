# linear {{{

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
    return HSV(240, 1 - iters / maxiter, 0.2 + 0.8 * iters / maxiter)
end

function blue_white_faded(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    return HSV(240, 0.8 - 0.8 * iters / maxiter, 0.1 + 0.8 * iters / maxiter)
end

function blue_total_white(iters::I, maxiter::I)::RGBf where {I<:Integer}
    return HSV(240, 0.8 - 0.8 * iters / maxiter, 0.1 + 0.8 * iters / maxiter)
end

#  }}}

# square/sqrt {{{

function hsv_square(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    start = 250
    stop = -30
    v = (iters / maxiter)^2
    hue = start + (stop - start) * v
    return HSV(hue, 0.8 + 0.2 * v, 1 - 0.2 * v)
end

function hsv_square_dark(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    start = 250
    stop = -30
    v = (iters / maxiter)
    value = 0.05 + 0.85 * sqrt(sqrt(v))
    v = v * v
    hue = start + (stop - start) * v
    return HSV(hue, 0.8 + 0.2 * v, value)
end

function blue_yellow_white(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    q = iters / maxiter
    h = q > 0.5 ? 36 : 240
    s = abs(2 * q - 1)
    s = s * sqrt(s)
    v = 0.4 + 0.6 * sqrt(q)
    return HSV(h, s, v)
end

function byrw(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    q = iters / maxiter
    h = (q > 0.5) ? (10 + 40 * sqrt(2 - 2 * q)) : (240)
    s = sqrt(abs(2 * q - 1))
    s = s * sqrt(s)
    v = 0.3 + 0.7 * sqrt(q)
    return HSV(h, s, v)
end

function blue_white_sqrt(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    v = sqrt(iters / maxiter)
    return HSV(240, 1 - v, 0.2 + 0.8 * v)
end

#  }}}

# log {{{

function showcase(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    q = iters / maxiter
    h = (q > 0.5) ? (10 + 40 * sqrt(2 - 2 * q)) : (240)
    s = sqrt(abs(2 * q - 1))
    s = s * sqrt(s)
    v = 0.3 + 0.7 * log2(log2(log2(q + 1) + 1) + 1)
    return HSV(h, s, v)
end

function dark_showcase(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    q = iters / maxiter
    h = (q > 0.5) ? (10 + 40 * sqrt(2 - 2 * q)) : (240)
    s = sqrt(abs(2 * q - 1))
    s = s * sqrt(s)
    v = (q > 0.5) ? 2 * q * sqrt(1 / 2) * sqrt(q) : (2 * q * q)
    v = 0.3 + 0.7 * log2(v + 1)
    return HSV(h, s, v)
end

function blue_white_log(iters::I, maxiter::I)::RGBf where {I<:Integer}
    if iters == maxiter
        return RGBf(0, 0, 0)
    end
    v = log2(1 + iters / maxiter)
    return HSV(240, 1 - v, 0.2 + 0.8 * v)
end

#  }}}

# other {{{

function trippy(iters::I, maxiter::I)::RGBf where {I<:Integer}
    return HSV(
        (maxiter - iters) / (iters + 1) * 360,
        0.8,
        iters != maxiter,
    )
end

function holy_moly(iters::I, maxiter::I)::RGBf where {I<:Integer}
    start = 250
    stop = -30
    v = iters / maxiter
    hue = start + (stop - start) * v
    return HSV(hue, 0.9, v * v)
end

function holier_moly(iters::I, maxiter::I)::RGBf where {I<:Integer}
    start = 250
    stop = -30
    v = iters / maxiter
    hue = start + (stop - start) * v
    return HSV(hue, 0.9, 0.05 + 0.95 * v)
end

function pink_storm(iters::I, maxiter::I)::RGBf where {I<:Integer}
    start = 250
    stop = -30
    v = iters / maxiter
    hue = start + (stop - start) * v
    return HSV(hue, 0.9, 0.9 * sqrt(v))
end

#  }}}

const DEFAULT_COLOR_MAP = default_hsv
