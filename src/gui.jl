#= imports, settings {{{=#

using Observables

const DEFAULT_MIN_ITERS = 5
const DEFAULT_MAX_ITERS = 100000

#= }}}=#

#= basics {{{=#

abstract type AbstractGUI end
abstract type AbstractGUIElement end

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
mutable struct FractalElem <: AbstractGUIElement
    "axis where fractal is drawn"
    axis::Axis
    "fractal object"
    fractal::AbstractFractal
    "elements of gui that control the fractal"
    blocks::NTuple{N,Block} where {N}
end

"GUI for fractal explorations"
struct FractalGUI{NT<:NamedTuple} <: AbstractGUI
    "figure inside which whole gui lives"
    figure::Figure
    "elements of type `FractalElem`"
    elements::NT
end

function apply_installers(block::Block)
    apply_installers(block.block, block.installers, block.args)
end

function apply_installers(
    block::Makie.Block,
    installers::NTuple{N,<:Function},
    args::NTuple{N,<:Any},
) where {N}
    ((f, block, args) -> f(block, args...)).(installers, block, args)
end


function Block(
    block::Makie.Block,
    installers::NTuple{N,<:Function},
    args::Union{<:NTuple{N,<:Any},Nothing}=nothing,
) where {N}
    block_args::NTuple{N,<:Any} =
        if args === nothing
            (((nothing,) for _ in 1:N)...,)
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
        apply_installers(block, installers, block_args)
    )
end

function GLMakie.display(gui::FractalGUI)
    display(gui.figure)
end

# function get_name(ax::Axis)::Symbol
#     return ax.interactions[:name][2]()
# end

#= }}}=#

#= helpers {{{=#

# function get_fractal(ax::Axis)::AbstractFractal
#     return ax.interactions[:fractal][2]()
# end

# function get_slider(ax::Axis)
#     ax.parent.content[]
#     # TODO
# end

# function get_button(ax::Axis)
#     # TODO
# end

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

function transform_float_type(
    ax::Axis,
    new_type::Type{<:Number}
)::AbstractFractal
    transform_float_type(get_fractal(ax), new_type)
end

function transform_float_type!(
    ax::Axis,
    new_type::Type{<:Number}
)::AbstractFractal
    new_fractal = transform_float_type(ax, new_type)
    fractal!(ax, new_fractal; refresh=true)
    # TODO maxiter slider doesn't work
    return new_fractal
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
    main = FractalElem(ax, fractal, ())
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
        (button, fractal) -> on(_ -> reset!(fractal), button.clicks)
    on_change_installer =
        (slider_grid, fractal, calc_maxiter) ->
            on(
                change_maxiter!(fractal, calc_maxiter),
                slider_grid.sliders[1].value
            )
    button_block = Block(
        b,
        (on_reset_installer,),
        ((fractal,),)
    )
    slider_block = Block(
        sl,
        (on_change_installer,),
        ((fractal, calc_maxiter),)
    )

    rowsize!(sl.layout, 1, Relative(0.95))
    clean_axis!(ax)
    main = FractalElem(ax, fractal, (button_block, slider_block))
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
    # name::Symbol,
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
    # register_interaction!(() -> name, ax, NAME_ACTION)
    if !static
        register_interaction!(zoom!(fractal), ax, ZOOM_ACTION)
        register_interaction!(move!(fractal), ax, DRAG_ACTION)
    end
    if refresh
        recalculate!(fractal)
    end
end

function fractal!(
    gui::FractalGUI;
    refresh::Bool=false,
    reinstall::Bool=true,
    kw_args...
)
    for (name, element) in pairs(gui.elements)
        fractal!(
            element.axis,
            # name,
            element.fractal;
            refresh=refresh,
            kw_args...
        )
        if reinstall
            for block in element.blocks
                apply_installers(block)
            end
        end
    end
end

#= }}}=#

#= TODO animations {{{=#

#= }}}=#
