module SPN

include("nodes.jl")
export Node, InnerNode, LeafNode, SumNode, ProdNode, IndicatorNode
export connect!, setInput!, eval!, passDerivative!

include("network.jl")
export SumProductNetwork, computeDerivatives!

include("inference.jl")
export marginalInference!, conditionalInference!, mpeInference!

include("utils.jl")
export addExp

end # module
