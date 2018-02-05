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

Creates a new indicator node for a random variable with floating point values.
"""
function IndicatorNode(varidx::Int, indicates::Float64)
    logval = -Inf
    parents = InnerNode[]
    scope = Int[varidx]
    IndicatorNode(logval, parents, scope, indicates)
end

"""
Creates a new indicator node for a random variable with integer values.
"""
IndicatorNode(varidx::Int, indicates::Int) = IndicatorNode(varidx, float(indicates))

"""
Creates a new indicator node for a random variable with boolean values.
"""
IndicatorNode(varidx::Int, indicates::Bool) = IndicatorNode(varidx, float(indicates))



################################################################
# CONNECTING NODES
# We can connect nodes by adding the child node to the list of
# children of the parent and the parent to the list of parents
# of the child. Note that the parent has to be an inner node.
################################################################

"""
    connect!(parent::InnerNode, child::Node)

Connects two nodes with an edge.
"""
function connect!(parent::InnerNode, child::Node)
    push!(parent.children, child)
    push!(child.parents, parent)
end


"""
    connect!(parent::SumNode, child::Node; weight=rand())

Connects two nodes with an edge, where the parent node is a
sum node. Because edges emanating from a sum node have weights
assigned to them, we can specify them with a keyword argument.
If no weight is specified, a weight is chosen at random.
"""
function connect!(parent::SumNode, child::Node; weight=rand())
    push!(parent.children, child)
    push!(child.parents, parent)
    push!(parent.weights, weight)
end



################################################################
# DISPLAYING NODES
################################################################

"""
Display an inner node.
"""
function Base.show(io::IO, n::InnerNode)
   print(io, "$(typeof(n))(parents=$(length(n.parents)), children=$(length(n.children)), logval=$(n.logval))") 
end


"""
Display an indicator node.
"""
function Base.show(io::IO, i::IndicatorNode)
   print(io, "$(typeof(i))(parents=$(length(i.parents)), scope=$(i.scope[1]), indicates=$(i.indicates), logval=$(i.logval))") 
end
