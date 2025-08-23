#= imports, settings {{{=#

using Observables

const DEFAULT_MIN_ITERS = 5
const DEFAULT_MAX_ITERS = 100000

#= }}}=#

#= basics {{{=#

mutable struct Block{N}
    block::Makie.Block
    installers::NTuple{N,<:Function}
    args::NTuple{N,<:Tuple}
    observer_functions::NTuple{N,<:ObserverFunction}
end

"
Element of GUI for fractal explorations.
Contains every gui widget that somehow corresponds to given fractal.
"
mutable struct FractalGElement
    "axis where fractal is drawn"
    axis::Axis
    "fractal object"
    fractal::AbstractFractal
    "elements of gui that control the fractal"
    blocks::NTuple{N,Block} where {N}
end

"GUI for fractal explorations"
struct FractalGUI{NT<:NamedTuple}
    "figure inside which whole gui lives"
    figure::Figure
    "elements of type FractalGElement"
    elements::NT
end

function Block(
    block::Makie.Block,
    fractal::AbstractFractal,
    installers::NTuple{N,<:Function},
    args::Union{<:NTuple{N,<:Any},Nothing}=nothing,
) where {N}
    block_args::NTuple{N,<:Any} =
        if args === nothing
            ((() for _ in 1:N)...,)
        else
            conversion = function (e)
                if e === nothing
                    tuple()
                elseif typeof(e) <: Tuple
                    e
                else
                    tuple(e)
                end
            end
            map(conversion, args)
        end
    return Block(
        block,
        installers,
        block_args,
        apply_installers(block, fractal, installers, block_args)
    )
end

function GLMakie.display(gui::FractalGUI)
    display(gui.figure)
end

#= }}}=#

#= helpers {{{=#

function apply_installers(
    block::Makie.Block,
    fractal::AbstractFractal,
    installers::NTuple{N,<:Function},
    args::NTuple{N,<:Any},
) where {N}
    apply = (f, block, fractal, args) -> f(block, fractal, args...)
    return apply.(installers, (block,), (fractal,), args)
end

function apply_installers(block::Block, fractal::AbstractFractal)
    apply_installers(block.block, fractal, block.installers, block.args)
end

function apply_installers(element::FractalGElement)
    for block in element.blocks
        apply_installers(block, element.fractal)
    end
end

function apply_installers!(block::Block, fractal::AbstractFractal)
    block.observer_functions = apply_installers(
        block.block,
        fractal,
        block.installers,
        block.args
    )
end

function apply_installers!(element::FractalGElement)
    for block in element.blocks
        apply_installers!(block, element.fractal)
    end
end

#= }}}=#

#= actions {{{=#

function zoom!(fractal::AbstractFractal)
    (event::ScrollEvent, axis::Axis) -> zoom!(fractal, event, axis)
end

function zoom!(
    fractal::AbstractFractal,
    event::ScrollEvent,
    _::Axis,
)
    if event.y == 0
        return
    end
    zoom!(fractal, fractal.zoom_factor^(-event.y))
end

function move!(fractal::AbstractFractal)
    (event::MouseEvent, axis::Axis) -> move!(fractal, event, axis)
end

function move!(
    fractal::AbstractFractal,
    event::MouseEvent,
    ax::Axis,
)
    if event.type == MouseEventTypes.leftdragstart ||
       event.type == MouseEventTypes.leftdrag ||
       event.type == MouseEventTypes.leftdragstop
        px_unit = fractal.plane_size ./ tuple(ax.scene.viewport[].widths...)
        dpx = event.prev_px .- event.px
        d = (dpx[1], dpx[2])
        fractal.drag_distance = fractal.drag_distance .- px_unit .* d
        if event.type == MouseEventTypes.leftdragstop
            move!(fractal, fractal.drag_distance)
            fractal.drag_distance = (0, 0)
        end
    end
end

function change_maxiter!(
    fractal::AbstractFractal,
    calc_maxiter::Function,
)
    return function (value::Real)
        change_maxiter!(fractal, calc_maxiter(value))
    end
end

function transform_float_type!(
    element::FractalGElement,
    new_type::Type{<:Number}
)
    new_fractal = transform_float_type(element.fractal, new_type)
    fractal!(element, new_fractal; refresh=true, reinstall=true)
    return new_fractal
end

function transform_float_type!(
    gui::FractalGUI,
    name::Symbol,
    new_type::Type{<:Number}
)
    return transform_float_type!(gui.elements[name], new_type)
end

function transform_float_type!(
    gui::FractalGUI,
    new_type::Type{<:Number}
)
    return transform_float_type!.(gui.elements, (new_type,))
end

#= }}}=#

#= gui setup {{{=#

function figure(
    fractal::AbstractFractal;
    figure_args...
)::Figure
    return Figure(
        size=size(fractal.img[]),
        viewmode=:fitzoom; # no margin around axis
        figure_args...
    )
end

function clean_axis!(ax::Axis)
    hidespines!(ax)
    hidedecorations!(ax)
    tight_ticklabel_spacing!(ax) # no idea if needed
end

function simple_setup(fractal::AbstractFractal)::FractalGUI
    fig = figure(fractal, figure_padding=0)
    ax = Axis(fig[1, 1])
    clean_axis!(ax)
    main = FractalGElement(ax, fractal, ())
    return FractalGUI(fig, (main=main,))
end

function advanced_setup(
    fractal::AbstractFractal;
    min_iters::Real=DEFAULT_MIN_ITERS,
    max_iters::Real=DEFAULT_MAX_ITERS,
    log_slider::Bool=true,
)::FractalGUI
    fig = figure(fractal)
    ax = Axis(fig[1:2, 1])
    steps = fig.scene.viewport[].widths[2] - fig.scene.viewport[].origin[2]
    if log_slider
        start_value = log10(fractal.maxiter)
        min_iters = log10(min_iters)
        max_iters = log10(max_iters)
        calc_maxiter_base = n::Real -> 10^n
    else
        start_value = fractal.maxiter
        calc_maxiter_base = identity
    end
    calc_maxiter = n::Real -> n |> calc_maxiter_base |> round |> Int

    b = Button(
        fig[1, 2],
        label="Reset"
    )
    # TODO more vertical slider
    sl = SliderGrid(
        fig[2, 2],
        (
            label="maxiter",
            format=n -> string(calc_maxiter(n)),
            range=range(min_iters, max_iters, div(steps, 2) + 1),
            startvalue=start_value,
            horizontal=false,
            update_while_dragging=false,
            linewidth=size(fractal.img[])[1] / 100
        )
    )

    on_reset_installer =
        (b, f) -> on(_ -> reset!(f), b.clicks; weak=true)
    on_change_installer =
        (sg, f, c) ->
            on(
                change_maxiter!(f, c),
                sg.sliders[1].value;
                weak=true
            )
    button_block = Block(
        b,
        fractal,
        (on_reset_installer,),
        nothing,
    )
    slider_block = Block(
        sl,
        fractal,
        (on_change_installer,),
        ((calc_maxiter,),)
    )

    rowsize!(sl.layout, 1, Relative(0.95))
    clean_axis!(ax)
    main = FractalGElement(ax, fractal, (button_block, slider_block))
    return FractalGUI(fig, (main=main,))
end

function simple_gui(
    fractal::AbstractFractal;
    refresh::Bool=false
)::FractalGUI
    gui = simple_setup(fractal)
    fractal!(gui.elements[:main].axis, fractal; refresh=refresh)
    return gui
end

function advanced_gui(
    fractal::AbstractFractal;
    refresh::Bool=false,
    kw_args...
)::FractalGUI
    gui = advanced_setup(fractal; kw_args...)
    fractal!(gui; refresh=refresh, reinstall=false)
    return gui
end

function fractal!(
    ax::Axis,
    fractal::AbstractFractal;
    refresh::Bool=false,
    static::Bool=false
)
    empty!(ax)
    image!(ax, fractal.img)
    ax_interactions = ax |> interactions |> keys
    for interaction in [
        :scrollzoom,
        :dragpan,
        :rectanglezoom,
        :limitreset,
        :fractal,
        ZOOM_ACTION,
        DRAG_ACTION,
    ]
        if interaction in ax_interactions
            deregister_interaction!(ax, interaction)
        end
    end
    if !static
        register_interaction!(zoom!(fractal), ax, ZOOM_ACTION)
        register_interaction!(move!(fractal), ax, DRAG_ACTION)
    end
    if refresh
        recalculate!(fractal)
    end
end

function fractal!(
    element::FractalGElement;
    refresh::Bool=false,
    reinstall::Bool=true,
    kw_args...
)
    fractal!(
        element.axis,
        element.fractal;
        refresh=refresh,
        kw_args...
    )
    if reinstall
        apply_installers!(element)
    end
end

function fractal!(gui::FractalGUI, name::Symbol; kw_args...)
    fractal!(gui, gui.elements[name]; kw_args...)
end

function fractal!(gui::FractalGUI; kw_args...)
    for element in gui.elements
        fractal!(element; kw_args...)
    end
end

function fractal!(
    element::FractalGElement,
    fractal::AbstractFractal;
    kw_args...
)
    element.fractal = fractal
    fractal!(element; kw_args...)
end

function fractal!(
    gui::FractalGUI,
    name::Symbol,
    fractal::AbstractFractal;
    kw_args...
)
    gui.elements[name].fractal = fractal
    fractal!(gui.elements[name]; kw_args...)
end

#= }}}=#

#= TODO animations {{{=#

#= }}}=#
