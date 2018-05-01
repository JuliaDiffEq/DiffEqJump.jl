struct ExtendedJumpArray{T3<:Number, T1, T<:AbstractArray{T3,T1},T2} <: AbstractArray{T3,1}
  u::T
  jump_u::T2
end

Base.length(A::ExtendedJumpArray) = length(A.u) + length(A.jump_u)
Base.size(A::ExtendedJumpArray) = (length(A),)
@inline function Base.getindex(A::ExtendedJumpArray,i::Int)
  i <= length(A.u) ? A.u[i] : A.jump_u[i-length(A.u)]
end
@inline function Base.getindex(A::ExtendedJumpArray,I...)
  A[sub2ind(A.u,I...)]
end
@inline function Base.getindex(A::ExtendedJumpArray,I::CartesianIndex{1})
  A[I[1]]
end
@inline Base.setindex!(A::ExtendedJumpArray,v,I...) = (A[sub2ind(A.u,I...)] = v)
@inline Base.setindex!(A::ExtendedJumpArray,v,I::CartesianIndex{1}) = (A[I[1]] = v)
@inline function Base.setindex!(A::ExtendedJumpArray,v,i::Int)
  i <= length(A.u) ? (A.u[i] = v) : (A.jump_u[i-length(A.u)] = v)
end

@compat Base.IndexStyle(::Type{<:ExtendedJumpArray}) = IndexLinear()
Base.similar(A::ExtendedJumpArray) = ExtendedJumpArray(similar(A.u),similar(A.jump_u))
Base.similar{S}(A::ExtendedJumpArray,::Type{S}) = ExtendedJumpArray(similar(A.u,S),similar(A.jump_u,S))

function recursivecopy!{T<:ExtendedJumpArray}(dest::T, src::T)
  recursivecopy!(dest.u,src.u)
  recursivecopy!(dest.jump_u,src.jump_u)
end
#indices(A::ExtendedJumpArray) = Base.OneTo(length(A.u) + length(A.jump_u))
Base.show(io::IO,A::ExtendedJumpArray) = show(io,A.u)
plot_indices(A::ExtendedJumpArray) = eachindex(A.u)

add_idxs1(x,expr) = expr
add_idxs1{T<:ExtendedJumpArray}(::Type{T},expr) = :($(expr).u)

add_idxs2(x,expr) = expr
add_idxs2{T<:ExtendedJumpArray}(::Type{T},expr) = :($(expr).jump_u)

@generated function Base.broadcast!(f,A::ExtendedJumpArray,B::Union{Number,ExtendedJumpArray}...)
  exs1 = ((add_idxs1(B[i],:(B[$i])) for i in eachindex(B))...)
  exs2 = ((add_idxs2(B[i],:(B[$i])) for i in eachindex(B))...)
  res = quote
      broadcast!(f,A.u,$(exs1...));broadcast!(f,A.jump_u,$(exs2...))
    end
  res
end

Base.Broadcast.promote_containertype(::Type{T}, ::Type{T}) where {T<:ExtendedJumpArray} = T
Base.Broadcast.promote_containertype(::Type{T}, ::Type{S}) where {T<:ExtendedJumpArray, S<:AbstractArray} = T
Base.Broadcast.promote_containertype(::Type{S}, ::Type{T}) where {T<:ExtendedJumpArray, S<:AbstractArray} = T
Base.Broadcast.promote_containertype(::Type{T}, ::Type{<:Any}) where {T<:ExtendedJumpArray} = T
Base.Broadcast.promote_containertype(::Type{<:Any}, ::Type{T}) where {T<:ExtendedJumpArray} = T
Base.Broadcast.promote_containertype(::Type{Array}, ::Type{T}) where {T<:ExtendedJumpArray} = T
Base.Broadcast.promote_containertype(::Type{T}, ::Type{Array}) where {T<:ExtendedJumpArray} = T
Base.Broadcast._containertype(::Type{T}) where {T<:ExtendedJumpArray} = T
Base.Broadcast.broadcast_indices(::Type{<:ExtendedJumpArray}, A) = indices(A)

@inline function Base.Broadcast.broadcast_c(f, ::Type{S}, A, Bs...) where S<:ExtendedJumpArray
    T = Base.Broadcast._broadcast_eltype(f, A, Bs...)
    shape = Base.Broadcast.broadcast_indices(A, Bs...)
    broadcast!(f, similar(A), A, Bs...)
end

@inline function Base.Broadcast.broadcast_c(f, ::Type{S}, A::ExtendedJumpArray, Bs::Union{ExtendedJumpArray,Number}...) where S<:ExtendedJumpArray
    new_A = similar(A)
    broadcast!(f,new_A,A,Bs...)
    new_A
end

@inline function Base.Broadcast.broadcast_c(f, ::Type{S}, A::ExtendedJumpArray) where S<:ExtendedJumpArray
    new_A = similar(A)
    broadcast!(f,new_A,A)
    new_A
end

@inline Base.broadcast!(::typeof(identity), u::DiffEqJump.ExtendedJumpArray, x::Number) = fill!(u,x)
#=
Base.Broadcast._containertype(::Type{<:ExtendedJumpArray}) = ExtendedJumpArray
Base.Broadcast.promote_containertype(::Type{ExtendedJumpArray}, _) = ExtendedJumpArray
Base.Broadcast.promote_containertype(_, ::Type{ExtendedJumpArray}) = ExtendedJumpArray
Base.Broadcast.promote_containertype(::Type{ExtendedJumpArray}, ::Type{Array}) = ExtendedJumpArray
Base.Broadcast.promote_containertype(::Type{Array}, ::Type{ExtendedJumpArray}) = ExtendedJumpArray

@generated function Base.broadcast_c(f,::Type{ExtendedJumpArray},B...)
  exs1 = ((add_idxs1(B[i],:(B[$i])) for i in eachindex(B))...)
  exs2 = ((add_idxs2(B[i],:(B[$i])) for i in eachindex(B))...)
  res = quote
          @show B
          for b in B
            @show b
            @show typeof(b)
            @show typeof(b) <: ExtendedJumpArray
            if typeof(b) <: ExtendedJumpArray
              @show "here"
              L = length(b.u)
              @show L
              break
            end
          end
          @show L
          ExtendedJumpArray(broadcast(f,$(exs1...)),broadcast(f,$(exs2...)))
        end
  end
  @show res
  res
end
=#
