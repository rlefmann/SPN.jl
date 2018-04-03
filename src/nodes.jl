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

	"The log-likelihood value of this node."
	logval::Float64
    "The log-derivative value of this node."
    logdrv::Float64
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
	logval = -Inf  # The default logval is log(0)=-Inf
    logdrv = -Inf  # The default logdrv is log(0)=-Inf
    state = unmarked
	parents = InnerNode[]
	children = Node[]
	scope = Int[]
	ProdNode(id, logval, logdrv, state, parents, children, scope)
end


"""
A sum node computes a weighted sum of the values of its child nodes.
"""
mutable struct SumNode <: InnerNode
    "The id number of this node."
    id::Int

	"The log-likelihood value of this node."
	logval::Float64
    "The log-derivative value of this node."
    logdrv::Float64
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
	logval = -Inf  # The default logval is log(0)=-Inf
    logdrv = -Inf  # The default logdrv is log(0)=-Inf
    maxidx = -1
    state = unmarked
	parents = InnerNode[]
	children = Node[]
	scope = Int[]

	weights = Float64[]
    counts = Float64[]

	SumNode(id, logval, logdrv, maxidx, state, parents, children, scope, weights, counts)
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
    logval::Float64
    "The log-derivative value of this node."
    logdrv::Float64
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
    logval = -Inf
    logdrv = -Inf
    state = unmarked
    parents = InnerNode[]
    scope = Int[varidx]
    IndicatorNode(id, logval, logdrv, state, parents, scope, indicates)
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
    logval::Float64
    "The log-derivative value of this node."
    logdrv::Float64
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

    logval = -Inf
    logdrv = -Inf
    state = unmarked
    parents = InnerNode[]
    scope = Int[varidx]
    distr = Normal(μ,σ)

    GaussianNode(id,logval,logdrv,state,parents,scope,μ,σ,distr)
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
   print(io, "$(typeof(n))(parents=$(length(n.parents)), children=$(length(n.children)), logval=$(n.logval))") 
end


"""
Display an indicator node.
"""
function Base.show(io::IO, i::IndicatorNode)
   print(io, "$(typeof(i))(parents=$(length(i.parents)), scope=$(i.scope[1]), indicates=$(i.indicates), logval=$(i.logval))") 
end


"""
Display a Gaussian node.
"""
function Base.show(io::IO, g::GaussianNode)
   print(io, "$(typeof(g))(parents=$(length(g.parents)), scope=$(g.scope[1]), μ=$(g.μ), σ=$(g.σ), logval=$(g.logval))") 
end


################################################################
# EVALUATING NODES
# An SPN is evaluated by an upward pass through the network,
# evaluating one node after another. Evaluating a node means
# setting its value according to the current input.
# Working in logspace is less prone to numerical problems,
# such as underflow resulting from multiplying together several
# very small probabilities.
################################################################

"""
    setInput!(i::IndicatorNode, x::AbstractVector, e::BitVector)

Sets the logval of the indicator node `i` according to the input `x`.
The bitvector `e` represents which values are in the evidence
and which are unknown.

Let X be the variable of the indicator and k the indicated value.
The value is log(1)=0 if X==k or if the value of X is unknown. 
Otherwise the value of the indicator is log(0)=-Inf.
"""
function setInput!(i::IndicatorNode, x::AbstractVector, e::BitVector=trues(length(x)))
    idx = i.scope[1]  # get the column index of the variable i indicates
    @assert length(x) >= idx
    if e[idx] == false  # variable not in evidence
        i.logval = 0.0
    elseif x[idx] ≈ i.indicates
        i.logval = 0.0
    else
        i.logval = -Inf
    end
end


"""
    setInput!(g::GaussianNode, x::AbstractVector, e::BitVector)

Sets the logval of the Gaussian node `g` according to the input `x`.
The bitvector `e` represents which values are in the evidence
and which are unknown.
"""
function setInput!(g::GaussianNode, x::AbstractVector, e::BitVector=trues(length(x)))
    idx = g.scope[1]  # get the column index of the variable g represents
    @assert length(x) >= idx
    if e[idx] == false  # variable not in evidence
        g.logval = 0.0
    else
        g.logval = logpdf(g.distr, x[idx])  # evaluate Gaussian
    end
end    


"""
    eval!(l::LeafNode; max::Bool=false; max::Bool=false) -> Float64

Returns the log value of the leaf node `l` on the current input.
The logval is already computed by `setInput!`.
"""
function eval!(l::LeafNode; max::Bool=false)
    return l.logval
end


function eval1!(i::IndicatorNode, llhvals::Matrix{Float64}, x::AbstractMatrix)
    varidx = i.scope[1]
    @assert size(x, 2) >= varidx
    # get parts of x and e corresponding to the variable i indicates:
    xvar = x[:, varidx]
    # set llh values corresponding to this node to -Inf:
    llhvals[i.id,:] = -Inf
    # The indicator node value is log(1)=0 when the variable is not in the evidence:
    llhvals[i.id, isnan(xvar)] = 0.0
    # If the node indicates the value the variable has, the node value is set to log(1)=0:
    llhvals[i.id, xvar .≈ i.indicates] = 0.0
end


"""
    eval!(p::ProdNode; max::Bool=false) -> Float64

Computes the log value of the product node `p` on the current input.

The value of a product node is the product of the values of its children.
Therefore, the log value is the sum of the log values of its children.
"""
function eval!(p::ProdNode; max::Bool=false)
    childvalues = [child.logval for child in p.children]
    p.logval = sum(childvalues)
    return p.logval
end



"""
    eval!(s::SumNode; max::Bool=false) -> Float64

Compute the log value of the sum node `s` on the current input.

The value of a sum node is the sum of the values of its children.
In log-space this looks a lot more ugly:
log(S_i) = log(sum_j w_ij S_j) = log(sum_j exp(log(w_ij)) * exp(log(S_j)))
= log(sum_j exp(log(w_ij) + log(S_j)).
If the keyword argument `max` is set to true the value of the sum node is its maximum weighted child value.
In log-space this means max(log(w_ij) + s_j).
"""
function eval!(s::SumNode; max::Bool=false)
    childvalues = [child.logval for child in s.children]
    numChildren = length(childvalues)

    sum_val = 0.0
    max_val = -Inf  # the maximum weighted childvalue
    max_idx = -1
    for (w, cval, idx) in zip(s.weights, childvalues, 1:numChildren)
        weighted_cval = cval + log(w)
        sum_val += exp(weighted_cval)
        if weighted_cval > max_val
            max_val = weighted_cval
            max_idx = idx
        end
    end

    if max == false
        s.logval = log(sum_val)
    else
        #s.logval = max_val
        s.logval = childvalues[max_idx]   # TODO: is this correct?
    end
    s.maxidx = max_idx

    return s.logval
end




################################################################
# COMPUTING NODE DERIVATIVES
# We require the derivatives of the likelihood with respect
# to the nodes of the network: ∂S/∂S_i. Because values are
# treated in logspace, derivatives are also in logspace.
# That means, we compute log(∂S/∂S_i).
# The derivatives can be computed using backpropagation.
################################################################

"""
Computes the derivative
"""
function passDerivative!(n::InnerNode)
    for (i, child) in enumerate(n.children)    
        # compute l value: l=∂S_n/∂S_i
        if typeof(n) == SumNode
            l = log(n.weights[i])
        else  # n is ProdNode
            l = n.logval - child.logval
        end

        if child.logdrv == -Inf
            child.logdrv = n.logdrv + l
        else
            child.logdrv = addExp(child.logdrv, n.logdrv + l)
        end
    end
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