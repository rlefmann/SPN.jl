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
    setInput!(spn::SumProductNetwork, x::AbstractVector, e::BitVector)

Sets the logval of all leaf nodes of the SPN according to the input.
"""
function setInput!(spn::SumProductNetwork, x::AbstractVector, e::BitVector=trues(length(x)))
    for node in spn.order
        if typeof(node) <: LeafNode
            setInput!(node, x, e)
        end
    end
end


"""
    eval!(spn::SumProductNetwork) -> Float64

Evaluates all nodes of an SPN on the current input. Returns the
logval of the root node.
"""
function eval!(spn::SumProductNetwork; maxeval=false)
    for node in spn.order
        eval!(node, maxeval=maxeval)
    end
    return spn.root.logval
end


"""
    eval!(spn::SumProductNetwork, x::AbstractMatrix) -> Vector{Float64}

Evaluate a `SumProductNetwork` for each of the datapoints in `x`.
Return the llhvals of the root node of the SPN.
"""
function eval!(spn::SumProductNetwork, x::AbstractMatrix; maxeval::Bool=false)
    n,d = size(x)
    m = numNodes(spn)
    llhvals = Matrix{Float64}(m,n)
    # TODO: max evaluation
    return eval!(spn, x, llhvals, maxeval=maxeval)
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
# SET INPUT OF LEAF NODES (ONLY FOR SEQUENTIAL EVALUATION)
################################################################

"""
    setInput!(i::IndicatorNode, x::AbstractVector, e::BitVector)

Sets the logval of the indicator node `i` according to the input `x`.
The bitvector `e` represents which values are in the evidence
and which are unknown.

Let X be the variable of the indicator and k the indicated value.
The value is log(1)=0 if X==k or if the value of X is unknown. 
Otherwise the value of the indicator is log(0)=-Inf.
"""
function setInput!(i::IndicatorNode, x::AbstractVector, e::BitVector=trues(length(x)))
    idx = i.scope[1]  # get the column index of the variable i indicates
    @assert length(x) >= idx
    if e[idx] == false  # variable not in evidence
        i.logval = 0.0
    elseif x[idx] ≈ i.indicates
        i.logval = 0.0
    else
        i.logval = -Inf
    end
end


"""
    setInput!(g::GaussianNode, x::AbstractVector, e::BitVector)

Sets the logval of the Gaussian node `g` according to the input `x`.
The bitvector `e` represents which values are in the evidence
and which are unknown.
"""
function setInput!(g::GaussianNode, x::AbstractVector, e::BitVector=trues(length(x)))
    idx = g.scope[1]  # get the column index of the variable g represents
    @assert length(x) >= idx
    if e[idx] == false  # variable not in evidence
        g.logval = 0.0
    else
        g.logval = logpdf(g.distr, x[idx])  # evaluate Gaussian
    end
end    



################################################################
# EVALUATION OF LEAF NODES
################################################################

"""
    eval!(l::LeafNode; max::Bool=false; max::Bool=false) -> Float64

Returns the log value of the leaf node `l` on the current input.
The logval is already computed by `setInput!`.
"""
function eval!(l::LeafNode; maxeval::Bool=false)
    return l.logval
end


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
"""
function eval!(g::GaussianNode, x::AbstractMatrix, llhvals::Matrix{Float64}; maxeval::Bool=false)
    varidx = g.scope[1]
    xvar = x[:, varidx]
    llhvals[g.id, :] = logpdf.(g.distr, xvar)
    # logpdf(g.distr, NaN)=NaN, but we want these nodes to have value log(1)=0:
    llhvals[g.id, isnan.(xvar)] = 0.0
end


function eval_mpe!(l::LeafNode, x::AbstractMatrix, llhvals::Matrix{Float64}, maxchidxs::Matrix{Int}; maxeval::Bool=false)
    eval!(l, x, llhvals, maxeval=maxeval)
end



################################################################
# EVALUATION OF PRODUCT NODES
################################################################

"""
    eval!(p::ProdNode; max::Bool=false) -> Float64

Computes the log value of the product node `p` on the current input.

The value of a product node is the product of the values of its children.
Therefore, the log value is the sum of the log values of its children.
"""
function eval!(p::ProdNode; maxeval::Bool=false)
    childvalues = [child.logval for child in p.children]
    p.logval = sum(childvalues)
    return p.logval
end


function eval!(p::ProdNode, x::AbstractMatrix, llhvals::Matrix{Float64}; maxeval::Bool=false)
    childids = [child.id for child in p.children]
    childvalues = llhvals[childids, :]
    # The log value is the sum of the log values of its children.
    # We build a sum for each column, i.e. for each datapoint
    llhvals[p.id, :] = sum(childvalues, 1)
end


function eval_mpe!(p::ProdNode, x::AbstractMatrix, llhvals::Matrix{Float64}, maxchidxs::Matrix{Int}; maxeval::Bool=false)
    eval!(p, x, llhvals, maxeval=maxeval)
end


################################################################
# EVALUATION OF SUM NODES
################################################################

"""
    eval!(s::SumNode; max::Bool=false) -> Float64

Compute the log value of the sum node `s` on the current input.

The value of a sum node is the sum of the values of its children.
In log-space this looks a lot more ugly:
log(S_i) = log(sum_j w_ij S_j) = log(sum_j exp(log(w_ij)) * exp(log(S_j)))
= log(sum_j exp(log(w_ij) + log(S_j)).
If the keyword argument `max` is set to true the value of the sum node is its maximum weighted child value.
In log-space this means max(log(w_ij) + s_j).
"""
function eval!(s::SumNode; maxeval::Bool=false)
    childvalues = [child.logval for child in s.children]
    numChildren = length(childvalues)

    sum_val = 0.0
    max_val = -Inf  # the maximum weighted childvalue
    max_idx = -1
    for (w, cval, idx) in zip(s.weights, childvalues, 1:numChildren)
        weighted_cval = cval + log(w)
        sum_val += exp(weighted_cval)
        if weighted_cval > max_val
            max_val = weighted_cval
            max_idx = idx
        end
    end

    if maxeval == false
        s.logval = log(sum_val)
    else
        #s.logval = max_val
        s.logval = childvalues[max_idx]   # TODO: is this correct?
    end
    s.maxidx = max_idx

    return s.logval
end


function eval!(s::SumNode, x::AbstractMatrix, llhvals::Matrix{Float64}; maxeval::Bool=false)
    weighted_cvals = compute_weighted_cvals(s, llhvals)
    if maxeval == false
        sum_vals = sum(exp.(weighted_cvals), 1)
        llhvals[s.id,:] = log.(sum_vals)
    else
        llhvals[s.id,:] = maximum(weighted_cvals, 1)
    end
end


function eval_mpe!(s::SumNode, x::AbstractMatrix, llhvals::Matrix{Float64}, maxchidxs::Matrix{Int}; maxeval::Bool=false)
    weighted_cvals = compute_weighted_cvals(s, llhvals)
    if maxeval == false
        sum_vals = sum(exp.(weighted_cvals), 1)
        llhvals[s.id,:] = log.(sum_vals)
        maxchidxs[s.id,:] = findmax(weighted_cvals, 1)[2]
    else
        llhvals[s.id,:], maxchidxs[s.id,:] = findmax(weighted_cvals, 1)
    end
end


function compute_weighted_cvals(s::SumNode, llhvals::Matrix{Float64})
    childids = [child.id for child in s.children]
    childvalues = llhvals[childids, :]
    weighted_cvals = childvalues .+ log.(s.weights)
    return weighted_cvals
end