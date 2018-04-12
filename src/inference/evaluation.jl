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
function eval!(spn::SumProductNetwork; max=false)
    for node in spn.order
        eval!(node, max=max)
    end
    return spn.root.logval
end


function eval!(spn::SumProductNetwork, x::AbstractMatrix)
    n,d = size(x)
    m = numNodes(spn)
    llhvals = Matrix{Float64}(m,n)
    # TODO: max evaluation
    for node in spn.order
        eval1!(node, llhvals, x)
    end
    return vec(llhvals[spn.root.id,:])
end