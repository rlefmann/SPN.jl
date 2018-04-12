module SPN

include("architecture/nodes.jl")
export Node, InnerNode, LeafNode, SumNode, ProdNode, IndicatorNode, GaussianNode
export connect!, setInput!, eval!, passDerivative!
export eval1!

include("architecture/network.jl")
export SumProductNetwork, computeDerivatives!
export numNodes, numSumNodes, numProdNodes, numLeafNodes
export setIDs!

include("inference/inference.jl")
export marginalInference!, conditionalInference!, mpeInference!

include("utils.jl")
export addExp, quantileMeans, dataLikelihood!

include("learn/parameter.jl")
export parameterLearnHardEM!, parameterLearnEM!, parameterLearnGD!

include("learn/poon.jl")
export structureLearnPoon

end # module
