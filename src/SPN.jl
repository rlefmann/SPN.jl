module SPN

include("nodes.jl")
export Node, InnerNode, LeafNode, SumNode, ProdNode, IndicatorNode
export connect!, eval!, passDerivative!

include("network.jl")
export SumProductNetwork

include("utils.jl")
export addExp

end # module
