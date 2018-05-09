# for GaussianNode:
using Distributions

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

* `id`: a unique number representing the node. Necessary for evaluation
* `parents`:  a list of parent nodes
* `scope`: a list of variables which influence the node
* `logval`: the current value of the node
* `logdrv`: the current value of the log derivative
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
    "The id number of this node."
    id::Int

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
function ProdNode(id::Int=0)
	#logval = -Inf  # The default logval is log(0)=-Inf
    #logdrv = -Inf  # The default logdrv is log(0)=-Inf
    state = unmarked
	parents = InnerNode[]
	children = Node[]
	scope = Int[]
	#ProdNode(id, logval, logdrv, state, parents, children, scope)
    ProdNode(id, state, parents, children, scope)
end


"""
A sum node computes a weighted sum of the values of its child nodes.
"""
mutable struct SumNode <: InnerNode
    "The id number of this node."
    id::Int

    "The index of the child with highest weighted value. Necessary for MPE inference."
    maxidx::Int
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
    # counts for each child. The EM algorithm uses these to compute new weights.
    counts::Vector{Float64}
end


"""
Creates a new sum node.
"""
function SumNode(id::Int=0)
	#logval = -Inf  # The default logval is log(0)=-Inf
    #logdrv = -Inf  # The default logdrv is log(0)=-Inf
    maxidx = -1
    state = unmarked
	parents = InnerNode[]
	children = Node[]
	scope = Int[]

	weights = Float64[]
    counts = Float64[]

	#SumNode(id, logval, logdrv, maxidx, state, parents, children, scope, weights, counts)
    SumNode(id, maxidx, state, parents, children, scope, weights, counts)
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
    "The id number of this node."
    id::Int

    "the log-likelihood value of this node."
    #logval::Float64
    "The log-derivative value of this node."
    #logdrv::Float64
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
function IndicatorNode(varidx::Int, indicates::Float64, id::Int=0)
	@assert varidx > 0
    #logval = -Inf
    #logdrv = -Inf
    state = unmarked
    parents = InnerNode[]
    scope = Int[varidx]
    #IndicatorNode(id, logval, logdrv, state, parents, scope, indicates)
    IndicatorNode(id, state, parents, scope, indicates)
end

"""
Creates a new indicator node for a random variable with integer values.
"""
IndicatorNode(varidx::Int, indicates::Int, id::Int=0) = IndicatorNode(varidx, float(indicates), id)

"""
Creates a new indicator node for a random variable with boolean values.
"""
IndicatorNode(varidx::Int, indicates::Bool, id::Int=0) = IndicatorNode(varidx, float(indicates), id)


"""
A `GaussianNode` represents a univariate Gaussian distribution.
"""
mutable struct GaussianNode <: LeafNode
    "The id number of this node."
    id::Int

    "the log-likelihood value of this node."
    #logval::Float64
    "The log-derivative value of this node."
    #logdrv::Float64
    "The node can have a state. Necessary for graph traversals."
    state::State

    "The parent nodes of this node."
    parents::Vector{InnerNode}
    "the scope of this node."
    scope::Vector{Int}

    "The mean of the Gaussian."
    μ::Float64
    "The standard deviation of the Gaussian"
    σ::Float64
    "The distribution object that defines the Gaussian."
    distr::Distributions.Normal{Float64}
end


"""
    GaussianNode(varidx::Int, μ::Float64, σ::Float64) -> GaussianNode

Creates a new Gaussian node.
"""
function GaussianNode(varidx::Int, μ::Float64, σ::Float64, id::Int=0)
    @assert varidx > 0

    #logval = -Inf
    #logdrv = -Inf
    state = unmarked
    parents = InnerNode[]
    scope = Int[varidx]
    distr = Normal(μ,σ)

    #GaussianNode(id,logval,logdrv,state,parents,scope,μ,σ,distr)
    GaussianNode(id,state,parents,scope,μ,σ,distr)
end


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
    push!(parent.counts, 0.0)
end



################################################################
# DISPLAYING NODES
################################################################

"""
Display an inner node.
"""
function Base.show(io::IO, n::InnerNode)
   print(io, "$(typeof(n))(parents=$(length(n.parents)), children=$(length(n.children)))") 
end


"""
Display an indicator node.
"""
function Base.show(io::IO, i::IndicatorNode)
   print(io, "$(typeof(i))(parents=$(length(i.parents)), scope=$(i.scope[1]), indicates=$(i.indicates))") 
end


"""
Display a Gaussian node.
"""
function Base.show(io::IO, g::GaussianNode)
   print(io, "$(typeof(g))(parents=$(length(g.parents)), scope=$(g.scope[1]), μ=$(g.μ), σ=$(g.σ))") 
end



################################################################
# MISCELLANEOUS FUNCTIONS
################################################################

"""
    normalize!(s::SumNode)

Normalizes the weights of the edges emanating from a sum node, 
such that they sum up to 1.
"""
function Base.normalize!(s::SumNode)
    ε::Float64 = 1e-10
    s.weights = s.weights / (sum(s.weights)+ε)
end


"""
    resetCounts!(s::SumNode)

Sets the counts for each child of a `SumNode` to 0.
"""
function resetCounts!(s::SumNode)
    s.counts = zeros(Float64, length(s.weights))
end
