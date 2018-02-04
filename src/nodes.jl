################################################################
# ABSTRACT NODES
################################################################

"""
Every node of an SPN has to be of a subtype of `Node`.

Every subtype of `Node` needs to have the fields (even though Julia does not enforce it):

* `parents`:  a list of parent nodes
* `scope`: a list of variables which influence the node.
* `logval`: the current value of the node
"""
abstract type Node end


"""
Inner nodes are either sum nodes or product nodes.

They must have an additional field `children::Vector{Node}` that is a list of their child nodes.
"""
abstract type InnerNode <: Node end


"""
Leaf nodes are nodes without children that represent some univariate probability distribution.
"""
abstract type LeafNode <: Node end


################################################################
# INNER NODES
################################################################

"""
A product node computes the product of the values of its child nodes.
"""
mutable struct ProdNode <: InnerNode
	"The log-likelihood value of this node."
	logval::Float64

	"The parent nodes of this node."
	parents::Vector{InnerNode}
	"The child nodes of this node."
	children::Vector{Node}
	"The scope of this node (a list of variables which influence the node)."
	scope::Vector{Int}
end


"""
Creates a new product node.
"""
function ProdNode()
	logval = -Inf  # The default logval is log(0)=-Inf
	parents = InnerNode[]
	children = Node[]
	scope = Int[]
	ProdNode(logval, parents, children, scope)
end


"""
A sum node computes a weighted sum of the values of its child nodes.
"""
mutable struct SumNode <: InnerNode
	"The log-likelihood value of this node."
	logval::Float64

	"The parent nodes of this node."
	parents::Vector{InnerNode}
	"The child nodes of this node."
	children::Vector{Node}
	"The scope of this node (a list of variables which influence the node)."
	scope::Vector{Int}

	"The weights of the edges connecting the sum node with its child nodes."
	weights::Vector{Float64}
end


"""
Creates a new sum node.
"""
function SumNode()
	logval = -Inf  # The default logval is log(0)=-Inf
	parents = InnerNode[]
	children = Node[]
	scope = Int[]

	weights = Float64[]

	SumNode(logval, parents, children, scope, weights)
end


################################################################
# LEAF NODES
# A leaf node represents some univariate probability
# distribution.
################################################################

"""
An indicator node for a random variable X and value k is 1 if X=k
for the current input example from the dataset.
Otherwise it has a value of 0. The corresponding log-values are
log(1) = 0 and log(0)=-Inf.
"""
mutable struct IndicatorNode <: LeafNode
    "the log-likelihood value of this node."
    logval::Float64

    "The parent nodes of this node."
    parents::Vector{InnerNode}
    "the scope of this node."
    scope::Vector{Int}
    "The value of the (discrete) variable that the node indicates."
    indicates::Float64
end


"""
	IndicatorNode(varidx::Int, indicates::Int) -> IndicatorNode

Creates a new indicator node.
"""
function IndicatorNode(varidx::Int, indicates::Float64)
    logval = -Inf
    parents = InnerNode[]
    scope = Int[varidx]
    IndicatorNode(logval, parents, scope, indicates)
end 