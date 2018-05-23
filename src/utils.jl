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


"""
    dataLikelihood!(spn::SumProductNetwork, x::AbstractMatrix) -> Float64

Computes the log-likelihood of the data `x` given the current SPN model.
"""
function dataLikelihood!(spn::SumProductNetwork, x::AbstractMatrix)
    llhvals = eval!(spn, x)
    return sum(llhvals)
end


"""
Creates the example SPN from the Poon paper.
"""
function create_toy_spn()
    s = SumNode()

    p1 = ProdNode()
    p2 = ProdNode()
    p3 = ProdNode()

    s1 = SumNode()
    s2 = SumNode()
    s3 = SumNode()
    s4 = SumNode()

    i1 = IndicatorNode(1,1)
    i2 = IndicatorNode(1,0)
    i3 = IndicatorNode(2,1)
    i4 = IndicatorNode(2,0)

    connect!(s,p1,weight=0.5)
    connect!(s,p2,weight=0.2)
    connect!(s,p3,weight=0.3)

    connect!(p1,s1)
    connect!(p1,s3)
    connect!(p2,s1)
    connect!(p2,s4)
    connect!(p3,s2)
    connect!(p3,s4)

    connect!(s1,i1,weight=0.6)
    connect!(s1,i2,weight=0.4)
    connect!(s2,i1,weight=0.9)
    connect!(s2,i2,weight=0.1)

    connect!(s3,i3,weight=0.3)
    connect!(s3,i4,weight=0.7)
    connect!(s4,i3,weight=0.2)
    connect!(s4,i4,weight=0.8)

    return s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4
end


"""
    convert_to_float(x::AbstractVecOrMat, e::BitArray)

Convert a vector or a matrix to type `Float64`. Entries of `x` for which the
corresponding entry in `e` is false are set to `NaN`.
"""
function convert_to_float(x::AbstractVecOrMat, e::BitArray=trues(x))
    @assert size(x) == size(e)
    xfloat = float(x)
	xfloat[.!e] = NaN
    return xfloat
end


"""
convert_to_float(x::AbstractMatrix, e::BitVector)

Convert a vector or a matrix to type `Float64`. All entries in columns of `x`
for which the corresponding entry in `e` is false are set to `NaN`.
"""
function convert_to_float(x::AbstractMatrix, e::BitVector)
    @assert length(e) == size(x, 2)
    xfloat = float(x)
    xfloat[:,.!e] = NaN
    return xfloat
end
