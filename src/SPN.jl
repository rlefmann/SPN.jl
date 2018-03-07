module SPN

include("nodes.jl")
export Node, InnerNode, LeafNode, SumNode, ProdNode, IndicatorNode, GaussianNode
export connect!, setInput!, eval!, passDerivative!

include("network.jl")
export SumProductNetwork, computeDerivatives!
export numNodes, numSumNodes, numProdNodes, numLeafNodes

include("inference.jl")
export marginalInference!, conditionalInference!, mpeInference!

include("utils.jl")
export addExp

include("learn/parameter.jl")
export parameterLearnHardEM!

include("learn/poon.jl")
export structureLearnPoon

end # module
