################################################################
# COMPUTING NODE DERIVATIVES
# We require the derivatives of the likelihood with respect
# to the nodes of the network: ∂S/∂S_i. Because values are
# treated in logspace, derivatives are also in logspace.
# That means, we compute log(∂S/∂S_i).
# The derivatives can be computed using backpropagation.
################################################################

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


function passDerivative!(n::InnerNode, x::AbstractMatrix, llhvals::Matrix{Float64}, logdrvs::Matrix{Float64})
    n,d = size(x)
    child_ids = [child.id for child in s.children]
    numchildren = length(s.children)
    child_drvs = logdrvs[childids, :]
    
    if isa(n, SumNode)
        # each entry in a column has the same value
        # ls = log.(n.weights) .* ones(numchildren, n)  # slower alternative
        ls = repeat(log.(n.weights), inner=(1,n))
    else
        node_logvals = llhvals[n.id,:]
        child_logvals = llhvals[childids, :]
        ls = node_logvals' .- child_logvals
    end

    for id in childids, j in 1:n
        if logdrvs[childids, j] == -Inf
            logdrvs[childids, j] =  0
        end
    end
end