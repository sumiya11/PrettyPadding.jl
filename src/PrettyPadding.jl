

module PrettyPadding

# it would be exponential :3
import Combinatorics: permutations

export prettypadding, bestpadding

#------------------------------------------------------------------------------

"""
    Prints the structure layout of `T`
    highlighting fields padding
"""
function prettypadding(T::Type; depth::Int=1)
    (depth <= 0) && error("depth should be > 1")
    checktype(T)
    walkfields(T, depth, "", "")
    return
end

"""
    Searches for a field layout for `T` which
    minimizes the overall struct padding
"""
function bestpadding(T::Type)
    checktype(T)

    defaultname = "PrettyPadding_$(rand(UInt32))"
    besttype    = T
    bestlayout  = layout(T)
    for (i, layout) in enumerate(permutations(layout(T)))
        name = defaultname*string(i)
        type = evallayout(name, layout)
        if sizeof(type) < sizeof(besttype)
            bestlayout = layout
            besttype   = type
        end
    end

    if sizeof(besttype) < sizeof(T)
        print("Better layout found! ")
        printstyled("(-$(sizeof(T)-sizeof(besttype)) bytes)\n", color=:green)
        walkfields(besttype, 1, "", "")
    else
        println("No better layout found.")
    end
    return
end


prettypadding(T; depth=1) = prettypadding(typeof(T), depth=depth)
bestpadding(T) = bestpadding(typeof(T))

#------------------------------------------------------------------------------

function walkfields(T::Type, depth::Int, name::String, indent::String)

    footer = printheader(T, depth, name, indent)

    # discover current level padding
    ptralign = isstructtype(T) ? 0 : sizeof(T)
    for (_, type) in layout(T)
        ptralign = max(ptralign, walkfields(type, -1, "", ""))
    end

    # pretty print current level
    padding = printpadding(ptralign, depth - 1, indent*"  ")
    for (name, type) in layout(T)
        padding(sizeof(type))
        walkfields(type, depth - 1, string(name), indent*"  ")
    end
    padding(-1)

    # print footers like (i.e "end" for the struct)
    footer()

    ptralign
end

#------------------------------------------------------------------------------

#=
    Checks if the alignment of the given type fields can be assessed
=#
function checktype(T::Type)
    isabstracttype(T) && error("type should be concrete and complete")
    !isconcretetype(T) && error("type should be concrete and complete")
end

#=
    Constructs a `name` struct with with fields from `layout`
    and evaluates it in the global scope
=#
function evallayout(name::String, layout)
    strfields  = join(map(el -> join(string.(el), "::"), layout), "\n")
    strrepr    = "struct $name"*
                    " $(strfields)"*
                " end;"*
                " $name;"
    eval(Meta.parse(strrepr))
end

#=
    Returns an iterator over the fields of the given type
=#
function layout(T::Type)
    [
        (fieldname(T, i), fieldtype(T, i))
        for i in 1:fieldcount(T)
    ]
end

#------------------------------------------------------------------------------

#=
    Returns a funcion to print field padding in a nice way
=#
function printpadding(align::Int, depth::Int, indent::String)
    (depth < 0) && return identity
    spare = align
    # called at each iteration
    function step(sz)
        if sz == -1 && spare != align
            printpadding(spare, indent)
        elseif sz > spare && spare != align
            printpadding(spare, indent)
            spare = max(align - sz, align)
        elseif sz >= spare
            spare = align
        else
            spare -= sz
        end
    end
    step
end

#=
    Prints padding of length `count`
=#
function printpadding(count::Int, indent::String)
    print("$indent"*"#"^count)
    printstyled("  $count bytes\n", color=:yellow)
end

#=
    Prints typeinfo for `T`
=#
function printheader(T::Type, depth::Int, name::String, indent::String)
    if depth < 0
        return () -> print()
    end
    if isstructtype(T)
        # first outer structure
        if isempty(name)
            print("$(indent)struct $T")
            printstyled("  $(sizeof(T)) bytes\n", color=:light_black)
            return () -> println("$(indent)end")
        else
            if depth == 0
                print("$(indent)$(name)::$(T)")
                printstyled("  $(sizeof(T)) bytes\n", color=:light_black)
                return () -> print()
            else
                print("$(indent)$(name)::$(T)")
                printstyled("  $(sizeof(T)) bytes\n", color=:light_black)
                return () -> println("$(indent)end")
            end
        end
    else
        print("$(indent)$(name)::$(T)")
        printstyled("  $(sizeof(T)) bytes\n", color=:light_black)
        return () -> print()
    end
end

end
