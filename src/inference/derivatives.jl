################################################################
# COMPUTING NODE DERIVATIVES
# We require the derivatives of the likelihood with respect
# to the nodes of the network: ∂S/∂S_i. Because values are
# treated in logspace, derivatives are also in logspace.
# That means, we compute log(∂S/∂S_i).
# The derivatives can be computed using backpropagation.
################################################################

"""
Sets the `logdrv` field of every node to -Inf.
"""
function initDerivatives!(spn::SumProductNetwork)
    for node in spn.order
        node.logdrv = -Inf
    end
end


"""
Computes the log derivative of the likelihood w.r.t. all
nodes in the SPN.
Performs a top-down pass through the network (backpropagation).
"""
function computeDerivatives!(spn::SumProductNetwork)

    # root derivative is log(1)=0:
    spn.root.logdrv = 0.0

    for node in reverse(spn.order)
        if typeof(node) <: InnerNode
            passDerivative!(node)
        end
    end
end


"""
Matrix evaluation of derivatives for SumProductNetwork.
"""
function computeDerivatives!(spn::SumProductNetwork, x::AbstractMatrix, llhvals::Matrix{Float64})
    n,d = size(x)
    m = numNodes(spn)
    logdrvs = Matrix{Float64}(m,n)
    computeDerivatives!(spn, x, llhvals, logdrvs)
end


"""
Matrix evaluation of derivatives for SumProductNetwork.
"""
function computeDerivatives!(spn::SumProductNetwork, x::AbstractMatrix, llhvals::Matrix{Float64}, logdrvs::Matrix{Float64})
    n,d = size(x)
    m = numNodes(spn)
    @assert size(logdrvs) == (m, n)

    logdrvs[:,:] = -Inf * ones(Float64, m, n)
    logdrvs[spn.root.id, :] = zeros(Float64, n)

    for node in reverse(spn.order)
        if typeof(node) <: InnerNode
            passDerivative!(node, x, llhvals, logdrvs)
        end
    end
end


"""
Computes the derivative
"""
function passDerivative!(n::InnerNode)
    for (i, child) in enumerate(n.children)    
        # compute l value: l=∂S_n/∂S_i
        if typeof(n) == SumNode
            l = log(n.weights[i])
        else  # n is ProdNode
            l = n.logval - child.logval
        end

        if child.logdrv == -Inf
            child.logdrv = n.logdrv + l
        else
            child.logdrv = addExp(child.logdrv, n.logdrv + l)
        end
    end
end


function passDerivative!(node::InnerNode, x::AbstractMatrix, llhvals::Matrix{Float64}, logdrvs::Matrix{Float64})
    n,d = size(x)
    child_ids = [child.id for child in node.children]
    
    if isa(node, SumNode)
        # each entry in a column has the same value
        # ls = log.(n.weights) .* ones(numchildren, n)  # slower alternative
        ls = repeat(log.(node.weights), inner=(1,n))
    else
        node_logvals = llhvals[node.id,:]
        child_logvals = llhvals[child_ids, :]
        ls = node_logvals' .- child_logvals
    end

    logdrvs[child_ids, :] = addExp.(logdrvs[child_ids, :], ls .+ logdrvs[node.id,:]')
    #=
    for id in child_ids, j in 1:n
        if logdrvs[child_ids, j] == -Inf
            logdrvs[child_ids, j] =  0.0
        end
    end
    =#
end