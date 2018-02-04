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