abstract type SmoothingKernel end

struct IdentitySmoother <: SmoothingKernel
    S::Float64
    κ₁::Float64
    κ₂::Float64
    κ₃::Float64
end

struct TruncatedSmoother <: SmoothingKernel
    ξ::Integer
    S::Float64
    smoother::Function
    κ₁::Float64
    κ₂::Float64
    κ₃::Float64
end

struct BartlettSmoother <: SmoothingKernel
    ξ::Integer
    S::Float64
    smoother::Function
    κ₁::Float64
    κ₂::Float64
    κ₃::Float64
end

IdentitySmoother() = IdentitySmoother(1.0, 1.0, 1.0, 1.0)

function TruncatedSmoother(ξ::Integer)
    function smoother(G::Array{T, 2}) where T
        N, M = size(G)
        nG   = zeros(T, N, M)
        for m=1:M
            for t=1:N
                low = max((t-N), -ξ)
                high = min(t-1, ξ)
                for s = low:high
                    @inbounds nG[t, m] += G[t-s, m]
                end
            end
        end
        return(nG/(2.0*ξ+1.0))
    end
    TruncatedSmoother(ξ, (2.0*ξ+1.0)/2.0, smoother, 2.0, 2.0, 1.0)
end

function BartlettSmoother(ξ::Integer)
    function smoother(G::Array{T, 2}) where T
        N, M = size(G)
        nG   = zeros(T, N, M)
        St   = (2.0*ξ+1.0)/2.0
        for m=1:M
            for t=1:N
                low = max((t-N), -ξ)
                high = min(t-1, ξ)
                for s = low:high
                    κ = 1.0-s/St
                    @inbounds nG[t, m] += κ*G[t-s, m]
                end
            end
        end
        return(nG/(2*ξ+1))
    end
    BartlettSmoother(ξ, (2.0*ξ+1.0)/2.0, smoother, 1.0, 2.0/3.0, 0.5)
end


## Used to scale objective function
bw(k::SmoothingKernel) = k.S
κ₁(k::SmoothingKernel) = k.κ₁
κ₂(k::SmoothingKernel) = k.κ₂

smooth(g::Array{T, 2}, k::IdentitySmoother) where T = g
smooth(g::Array{T, 2}, k::SmoothingKernel) where T = k.smoother(g)
