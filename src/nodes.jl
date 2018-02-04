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