mutable struct SumProductNetwork
    "The root node of the SPN."
    root::Node
    "The order in which the nodes of the SPN are evaluated."
    order::Vector{Node}

    """
    Creates a new SPN from an existing graph of nodes.
    """
    function SumProductNetwork(root::Node; recursive=true)
        order = computeOrder(root, recursive=recursive)
        new(root, order)
    end
end


"""
    computeOrder(root::Node) -> Vector{Node}

Computes a topological ordering of the nodes of an SPN
rooted at `root` by performing a post-order traversal
of the network. 
"""
function computeOrder(root::Node; recursive=true)
    if recursive
        return computeOrderRecursive(root)
    else
        return computeOrderStack(root)
    end
end


"""
Recursively compute topological order. Might probably be slow.
"""
function computeOrderRecursive(root::Node)
    order = Node[]

    states = Dict{Node, State}()

    """
    Post-order traversal for inner nodes.
    """
    function postOrder(n::InnerNode, states::Dict{Node, State})
        states[n] = temporary

        for child in n.children
            if !haskey(states, child)
                postOrder(child, states)
            elseif states[child] == temporary
                error("network contains cycle. Not a DAG.")
            end
        end
        states[n] = permanently
        push!(order, n)
    end

    """
    Post-order traversal for leaf nodes.
    """
    function postOrder(l::LeafNode, states::Dict{Node, State})
        push!(order, l)
        states[l] = permanently
    end

    postOrder(root, states)

    return order
end


"""
Computes order non-recursive, using a stack.
"""
function computeOrderStack(root::Node)
    order = Vector{Node}()
    stack = Vector{Node}()
    push!(stack, root)

    states = Dict{Node, State}()

    while ! isempty(stack)

        node = pop!(stack)

        # all children have been visited:
        if haskey(states, node) && states[node] == temporary  #node.state == temporary
            push!(order, node)
            #node.state = permanently
            states[node] = permanently
            continue
        end

        #node.state = temporary
        states[node] = temporary

        push!(stack, node)

        if typeof(node) <: InnerNode
            for child in node.children
                if !haskey(states, child)  #child.state == unmarked
                    push!(stack, child)
                elseif states[child] == temporary  #child.state == temporary
                    error("network contains cycle. Not a DAG.")
                end
            end
        end
    end

    # reset state of nodes:
    #for node in order
    #    node.state = unmarked
    #end

    return order
end

#=
function computeOrderStack(root::Node)
    order = Vector{Node}()
    stack = Vector{ Tuple{Bool, Node} }()
    push!(stack, (false, root))

    while ! isempty(stack)

        (complete, node) = pop!(stack)

        # all children have been visited:
        if complete
            push!(order, node)
            node.state = permanently
            continue
        end

        node.state = temporary

        push!(stack, (true, node))

        if typeof(node) <: InnerNode
            for child in node.children
                if child.state == unmarked
                    push!(stack, (false, child))
                elseif child.state == temporary
                    error("network contains cycle. Not a DAG.")
                end
            end
        end
    end

    return order
end
=#


"""
    setIDs!(spn::SumProductNetwork)

Set the id field of the nodes of the SPN according to the evluation order.
"""
function setIDs!(spn::SumProductNetwork)
    for i in 1:length(spn.order)
        spn.order[i].id = i
    end
end


"""
   numNodes(spn::SumProductNetwork) -> Int

The total number of nodes in the SPN. 
"""
function numNodes(spn::SumProductNetwork)
    return length(spn.order)
end


"""
   numSumNodes(spn::SumProductNetwork) -> Int

The number of sum nodes in the SPN.
"""
function numSumNodes(spn::SumProductNetwork)
    return numNodes(spn, SumNode)
end


"""
   numProdNodes(spn::SumProductNetwork) -> Int

The number of product nodes in the SPN.
"""
function numProdNodes(spn::SumProductNetwork)
    return numNodes(spn, ProdNode)
end


"""
   numLeafNodes(spn::SumProductNetwork) -> Int

The number of leaf nodes in the SPN.
"""
function numLeafNodes(spn::SumProductNetwork)
    return numNodes(spn, LeafNode)
end


"""
    numNodes(spn::SumProductNetwork, t::Type) -> Int

The number of nodes in the SPN that are of type `t`. 
The type `t` can be concrete or abstract. In the latter case the number
of nodes that are of a subtype of `t` are counted.
"""
function numNodes(spn::SumProductNetwork, t::Type{T}) where T <: Node
    cnt = 0
    for node in spn.order
        if typeof(node) <: t
            cnt += 1
        end
    end
    return cnt
end



"""
Display a SumProductNetwork object.
"""
function Base.show(io::IO, spn::SumProductNetwork)
    print(io, "SumProductNetwork(size=$(length(spn)))")
end


"""
The number of nodes of the SumProductNetwork.
"""
function Base.length(spn::SumProductNetwork)
    return numNodes(spn)
end


"""
    normalize!(spn::SumProductNetwork)

Normalizes the SPN. All edge weights emanating from a sum node sum up to 1.
"""
function Base.normalize!(spn::SumProductNetwork)
    for node in spn.order
        if typeof(node) == SumNode
            SPN.normalize!(node)
        end
    end
end


"""
    resetCounts!(spn::SumProductNetwork)

Sets the counts for each child of every `SumNode` to 0.
"""
function resetCounts!(spn::SumProductNetwork)
    for node in spn.order
        if typeof(node) == SumNode
            resetCounts!(node)
        end
    end
end
