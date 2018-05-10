################################################################
# EVALUATING NODES
# An SPN is evaluated by an upward pass through the network,
# evaluating one node after another. Evaluating a node means
# setting its value according to the current input.
# Working in logspace is less prone to numerical problems,
# such as underflow resulting from multiplying together several
# very small probabilities.
################################################################



################################################################
# EVALUATION OF NETWORK
################################################################

"""
    eval!(spn::SumProductNetwork, x::AbstractMatrix) -> Vector{Float64}

Evaluate a `SumProductNetwork` for each of the datapoints in `x`.
Return the llhvals of the root node of the SPN.
"""
function eval!(spn::SumProductNetwork, x::AbstractMatrix; maxeval::Bool=false)
    n,d = size(x)
    m = numNodes(spn)
    llhvals = Matrix{Float64}(m,n)
    return eval!(spn, x, llhvals, maxeval=maxeval)
end


"""
    eval!(spn::SumProductNetwork, x::AbstractVector) -> Float64

Evaluate a `SumProductNetwork` for the single datapoint `x`.
"""
function eval!(spn::SumProductNetwork, x::AbstractVector; maxeval::Bool=false)
    return eval!(spn, x', maxeval=maxeval)[]  # the empty square braces turn a single element vector into a scalar
end


"""
    eval!(spn::SumProductNetwork, x::AbstractMatrix) -> Vector{Float64}

Evaluate a `SumProductNetwork` for each of the datapoints in `x`.
The matrix `llhvals` is used to store the llhvals for each node in the SPN and each datapoint.
Return the llhvals of the root node of the SPN.
"""
function eval!(spn::SumProductNetwork, x::AbstractMatrix, llhvals::Matrix{Float64}; maxeval::Bool=false)
    n,d = size(x)
    m = numNodes(spn)
    @assert size(llhvals) == (m,n)
    # TODO: max evaluation
    for node in spn.order
        eval!(node, x, llhvals, maxeval=maxeval)
    end
    return vec(llhvals[spn.root.id,:])
end



################################################################
# EVALUATION OF LEAF NODES
################################################################

function eval!(i::IndicatorNode, x::AbstractMatrix, llhvals::Matrix{Float64}; maxeval::Bool=false)
    varidx = i.scope[1]
    @assert size(x, 2) >= varidx
    # get parts of x and e corresponding to the variable i indicates:
    xvar = x[:, varidx]
    # set llh values corresponding to this node to -Inf:
    llhvals[i.id,:] = -Inf
    # The indicator node value is log(1)=0 when the variable is not in the evidence:
    llhvals[i.id, isnan.(xvar)] = 0.0
    # If the node indicates the value the variable has, the node value is set to log(1)=0:
    llhvals[i.id, xvar .≈ i.indicates] = 0.0
end


"""
    eval!(g::GaussianNode, x::AbstractMatrix, llhvals::Matrix{Float64})

Matrix evaluation of a Gaussian node.

## Arguments

* `llhvals::Matrix{Float64}`: The log-likelihood values for each node and each datapoint.
"""
function eval!(g::GaussianNode, x::AbstractMatrix, llhvals::Matrix{Float64}; maxeval::Bool=false)
    varidx = g.scope[1]
    xvar = x[:, varidx]
    llhvals[g.id, :] = logpdf.(g.distr, xvar)
    # logpdf(g.distr, NaN)=NaN, but we want these nodes to have value log(1)=0:
    llhvals[g.id, isnan.(xvar)] = 0.0
end


function eval_mpe!(l::LeafNode, x::AbstractMatrix, llhvals::Matrix{Float64}, maxchids::Matrix{Int}; maxeval::Bool=false)
    eval!(l, x, llhvals, maxeval=maxeval)
end



################################################################
# EVALUATION OF PRODUCT NODES
################################################################

function eval!(p::ProdNode, x::AbstractMatrix, llhvals::Matrix{Float64}; maxeval::Bool=false)
    childids = [child.id for child in p.children]
    childvalues = llhvals[childids, :]
    # The log value is the sum of the log values of its children.
    # We build a sum for each column, i.e. for each datapoint
    llhvals[p.id, :] = sum(childvalues, 1)
end


function eval_mpe!(p::ProdNode, x::AbstractMatrix, llhvals::Matrix{Float64}, maxchids::Matrix{Int}; maxeval::Bool=false)
    eval!(p, x, llhvals, maxeval=maxeval)
end



################################################################
# EVALUATION OF SUM NODES
################################################################

function eval!(s::SumNode, x::AbstractMatrix, llhvals::Matrix{Float64}; maxeval::Bool=false)
    childids = [child.id for child in s.children]
    weighted_cvals = compute_weighted_cvals(childids, s.weights, llhvals)
    if maxeval == false
        sum_vals = sum(exp.(weighted_cvals), 1)
        llhvals[s.id,:] = log.(sum_vals)
    else
        llhvals[s.id,:] = maximum(weighted_cvals, 1)
    end
end


function eval_mpe!(s::SumNode, x::AbstractMatrix, llhvals::Matrix{Float64}, maxchids::Matrix{Int}; maxeval::Bool=false)
    childids = [child.id for child in s.children]
    weighted_cvals = compute_weighted_cvals(childids, s.weights, llhvals)
    maxvals, maxidxs = findmax(weighted_cvals, 1)
    if maxeval == false
        sum_vals = sum(exp.(weighted_cvals), 1)
        llhvals[s.id,:] = log.(sum_vals)
    else
        llhvals[s.id,:] = maxvals
    end
    #=
    maxidxs is a flattened index for the weighted_cvals array.
    We have to find the row of the maximal entry of each column from these indices.
    We can use ind2sub, but this results in ugly code, so we do the conversion
    using modulo calculation.
    =#
    vertical_indices = ((maxidxs .- 1) .% size(weighted_cvals, 1)) .+ 1
    # turn the row index into a child id:
    maxchids[s.id,:] = childids[vertical_indices]
end


function compute_weighted_cvals(childids::Vector{Int}, weights::Vector{Float64}, llhvals::Matrix{Float64})
    childvalues = llhvals[childids, :]
    weighted_cvals = childvalues .+ log.(weights)
    return weighted_cvals
end
