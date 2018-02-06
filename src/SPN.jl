module SPN

include("nodes.jl")
export Node, InnerNode, LeafNode, SumNode, ProdNode, IndicatorNode
export connect!, eval!

include("network.jl")
export SumProductNetwork

end # module
