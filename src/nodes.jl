################################################################
# STATE OF A NODE
################################################################

"""
A node can be in one of three states:
* unmarked
* temporary
* permanently
This is necessary for graph algorithms, especially for finding
a topological order of the nodes in an SPN.
"""
@enum State unmarked temporary permanently



################################################################
# ABSTRACT NODES
################################################################

"""
Every node of an SPN has to be of a subtype of `Node`.

Every subtype of `Node` needs to have the fields (even though Julia does not enforce it):

* `parents`:  a list of parent nodes
* `scope`: a list of variables which influence the node
* `logval`: the current value of the node
* `state`: a symbol representing the state of the node for graph traversals
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
    "The node can have a state. Necessary for graph traversals."
    state::State

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
    state = unmarked
	parents = InnerNode[]
	children = Node[]
	scope = Int[]
	ProdNode(logval, state, parents, children, scope)
end


"""
A sum node computes a weighted sum of the values of its child nodes.
"""
mutable struct SumNode <: InnerNode
	"The log-likelihood value of this node."
	logval::Float64
    "The node can have a state. Necessary for graph traversals."
    state::State

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
    state = unmarked
	parents = InnerNode[]
	children = Node[]
	scope = Int[]

	weights = Float64[]

	SumNode(logval, state, parents, children, scope, weights)
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
    "The node can have a state. Necessary for graph traversals."
    state::State

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
	@assert varidx > 0
    logval = -Inf
    state = unmarked
    parents = InnerNode[]
    scope = Int[varidx]
    IndicatorNode(logval, state, parents, scope, indicates)
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



################################################################
# EVALUATING NODES
# An SPN is evaluated by an upward pass through the network,
# evaluating one node after another. Evaluating a node means
# setting its value according to the current input.
# Working in log-space is less prone to numerical problems,
# such as underflow resulting from multiplying together several
# very small probabilities.
################################################################

"""
    eval!(i::IndicatorNode, x::AbstractVector) -> Float64

Computes the log value of the indicator node `i` on input `x`.

Let X be the variable of the indicator and k the indicated value.
The value is log(1)=0 if X==k.
Otherwise the value of the indicator is log(0)=-Inf.
"""
function eval!(i::IndicatorNode, x::AbstractVector)
    idx = i.scope[1]  # get the column index of the variable i indicates
    @assert length(x) >= idx
    if x[idx] ≈ i.indicates
        i.logval = 0.0
    else
        i.logval = -Inf
    end
    return i.logval
end


"""
    eval!(p::ProdNode, x::AbstractVector) -> Float64

Computes the log value of the product node `p` on input `x`.

The value of a product node is the product of the values of its children.
Therefore, the log value is the sum of the log values of its children.
"""
function eval!(p::ProdNode, x::AbstractVector)
    childvalues = [child.logval for child in p.children]
    p.logval = sum(childvalues)
    return p.logval
end


"""
    eval!(s::SumNode, x::AbstractVector) -> Float64

Computes the log value of the sum node `s` on input `x`.

The value of a sum node is the sum of the values of its children.
In log-space this looks a lot more ugly:
log(S_i) = log(sum_j w_ij S_j) = log(sum_j exp(log(w_ij)) * exp(log(S_j)))
= log(sum_j exp(log(w_ij) + log(S_j))
"""
function eval!(s::SumNode, x::AbstractVector)
    childvalues = [child.logval for child in s.children]

    sum_val = 0.0
    for (w, cval) in zip(s.weights, childvalues)
        weighted_cval = exp(cval + log(w))
        sum_val += weighted_cval
    end
    
    s.logval = log(sum_val)
    return s.logval
end