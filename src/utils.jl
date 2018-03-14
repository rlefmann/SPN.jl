using StatsBase

"""
Compute `log(exp(a)+exp(b))`.
"""
function addExp(a::Float64, b::Float64)
	if a > b
		return a + log(1 + exp(b - a))
	end
	return b + log(1 + exp(a - b))
end


"""
    quantileMeans(x::AbstractVector, n::Integer)

Compute the n-quantile means of a vector `x`, i.e. compute the values
which partition `x` into `n` subsets of nearly equal size and
return the means of each subset.
"""
function quantileMeans(x::AbstractVector, n::Integer)
    quantiles = nquantile(x, n)
    means = zeros(Float64, n)
    for j in 1:n
        if j != n
            mask = map(e->(quantiles[j]<=e<quantiles[j+1]), x)
        else
            mask = map(e->(quantiles[j]<=e), x)
        end
        means[j] = mean(x[mask])
    end
    return means
end