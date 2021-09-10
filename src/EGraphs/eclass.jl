const AnalysisData = ImmutableDict{Type{<:AbstractAnalysis}, Any}

# parametrize metadata by M
mutable struct EClass
    id::EClassId
    nodes::Vector{ENode}
    parents::Vector{Pair{ENode, EClassId}}
    data::Union{Nothing, AnalysisData}
    # data::M
end
EClass(id) = EClass(id, ENode[], Pair{ENode, EClassId}[], nothing)
EClass(id, nodes, parents) = EClass(id, nodes, parents, nothing)

# Interface for indexing EClass
Base.getindex(a::EClass, i) = a.nodes[i]
Base.setindex!(a::EClass, v, i) = setindex!(a.nodes, v, i)
Base.firstindex(a::EClass) = firstindex(a.nodes)
Base.lastindex(a::EClass) = lastindex(a.nodes)

# Interface for iterating EClass
Base.iterate(a::EClass) = iterate(a.nodes)
Base.iterate(a::EClass, state) = iterate(a.nodes, state)

# Showing
function Base.show(io::IO, a::EClass)
    print(io, "EClass $(a.id) (")
    
    print(io, "[", Base.join(a.nodes, ", "), "]")
    if a.data === nothing
        print(io, ")")
        return
    end
    print(io, ", analysis = {")
    for (k, v) ∈ a.data
        print(io, "$k => $v, ")
    end
    print(io, "})")
end

function addparent!(a::EClass, n::ENode, id::EClassId)
    push!(a.parents, (n => id))
end

function Base.union!(to::EClass, from::EClass)
    append!(to.nodes, from.nodes)
    append!(to.parents, from.parents)
    if to.data !== nothing && from.data !== nothing
        # merge!(to.data, from.data)
        # to.data = join_analysis_data(to.data, from.data)
        to.data = join_analysis_data(to.data, from.data)
    elseif to.data === nothing
        to.data = from.data
    end
    return to
end

function join_analysis_data(d::AnalysisData, dsrc::AnalysisData)
    for (an, val_b) in dsrc
        if haskey(d, an)
            val_a = d[an]
            nv = join(an, val_a, val_b)
            # d[an] = nv
            # WARNING immutable version
            d = Base.ImmutableDict(d,an=>nv)
        end
    end
    return d
end

# Thanks to Shashi Gowda
function hasdata(a::EClass, x::Type{<:AbstractAnalysis})
    a.data === nothing && (return false)
    return haskey(a.data, x)
end

function getdata(a::EClass, x::Type{<:AbstractAnalysis})
    !hasdata(a, x) && error("EClass $a does not contain analysis data for $x")
    return a.data[x]
end

function getdata(a::EClass, x::Type{<:AbstractAnalysis}, default)
    hasdata(a, x) ? a.data[x] : default
end

function setdata!(a::EClass, x::Type{<:AbstractAnalysis}, value) 
    # lazy allocation
    a.data === nothing && (a.data = AnalysisData())
    # a.data[x] = value
    a.data = AnalysisData(a.data, x, value)
end

function funs(a::EClass)
    map(operation, a.nodes)
end

function funs_arity(a::EClass)
    map(a.nodes) do x 
        (operation(x), arity(x))
    end
end