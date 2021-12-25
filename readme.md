
# PrettyPadding.jl

This is a package for printing padding for struct fields in a nice way. We export functions `prettypadding` and `bestpadding`. For usage please see examples below.

<details>
  <summary>What alignment rules we use?</summary>

  The rules meet C struct alignment requirements. Namely,
  * Fields within a struct are aligned by the widest scalar member.
  * The leading field is always aligned.
  * The allocated order of variables is same as their source order.
</details>

### Example 1

First we define a nice `struct`

```julia
struct Uwu
  x::Int16
  y::Int32
  z::Int8
end

julia> prettypadding(Uwu)
```

```
struct Uwu  12 bytes
  x::Int16  2 bytes
  ##  2 bytes
  y::Int32  4 bytes
  z::Int8  1 bytes
  ###  3 bytes
end
```

..and try to find a better representation

```julia
julia> bestpadding(Uwu)
```
```
Better layout found! (-4 bytes)
struct PrettyPadding_25917735682  8 bytes
  x::Int16  2 bytes
  z::Int8  1 bytes
  #  1 bytes
  y::Int32  4 bytes
end
```

Name is quite ugly though (todo).

### Example 2

Using `Uwu` from previous example we define

```julia
struct Owo{T}
  s1::Uwu
  s2::T
  s3::Pair{Uwu, T}
end

julia> prettypadding(Uwu, depth=3)
```

```
struct Owo{Int8}  32 bytes
  s1::Uwu  12 bytes
    x::Int16  2 bytes
    ##  2 bytes
    y::Int32  4 bytes
    z::Int8  1 bytes
    ###  3 bytes
  end
  s2::Int8  1 bytes
  ###  3 bytes
  s3::Pair{Uwu, Int8}  16 bytes
    first::Uwu  12 bytes
      x::Int16  2 bytes
      ##  2 bytes
      y::Int32  4 bytes
      z::Int8  1 bytes
      ###  3 bytes
    end
    second::Int8  1 bytes
    ###  3 bytes
  end
end
```
