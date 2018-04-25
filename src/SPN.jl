module SPN

include("architecture/nodes.jl")
export Node, InnerNode, LeafNode, SumNode, ProdNode, IndicatorNode, GaussianNode
export connect!, setInput!, eval!

include("architecture/network.jl")
export SumProductNetwork
export numNodes, numSumNodes, numProdNodes, numLeafNodes
export setIDs!

include("inference/evaluation.jl")
export setInput!, eval!

include("inference/derivatives.jl")
export initDerivatives!, computeDerivatives!, passDerivative!

include("inference/inference.jl")
export marginalInference!, conditionalInference!, mpeInference!

include("utils.jl")
export addExp, quantileMeans, dataLikelihood!

include("learn/parameter.jl")
export parameterLearnHardEM!, parameterLearnEM!, parameterLearnGD!
export parameterLearnEM1!

include("learn/poon.jl")
export structureLearnPoon

end # module
