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


#=
"""
    computeOrder(root::Node) -> Vector{Node}

Computes a topological ordering of the nodes of an SPN rooted at `root`.
Uses depth first search.
"""
function computeOrder(root::Node)
    root.state = temporary
    stack = Node[root]
    order = Node[]
    while ! isempty(stack)
        node = stack[end]
        @assert node.state == temporary
        # remove node from stack and add it to order:
        node.state = permanently
        pop!(stack)
        push!(order, node)

        # add all children to stack that are not on
        # the stack or in the order list:
        if typeof(node) <: InnerNode
            for child in node.children
                if child.state == unmarked
                    push!(stack, child)
                    child.state = temporary
                end
            end
        end
    end

    # reset state of nodes:
    for node in order
        node.state = unmarked
    end

    return order
end
=#


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

    """
    Post-order traversal for inner nodes.
    """
    function postOrder(n::InnerNode)
        n.state = temporary
        for child in n.children
            if child.state == unmarked
                postOrder(child)
            elseif child.state == temporary
                error("network contains cycle. Not a DAG.")
            end
        end
        n.state = permanently
        push!(order, n)
    end

    """
    Post-order traversal for leaf nodes.
    """
    function postOrder(l::LeafNode)
        push!(order, l)
        l.state = permanently
    end

    postOrder(root)

    # reset state of nodes:
    for node in order
        node.state = unmarked
    end

    return order
end


"""
Computes order non-recursive, using a stack.
"""
function computeOrderStack(root::Node)
    order = Vector{Node}()
    stack = Vector{Node}()
    push!(stack, root)

    while ! isempty(stack)

        node = pop!(stack)

        # all children have been visited:
        if node.state == temporary
            push!(order, node)
            node.state = permanently
            continue
        end

        node.state = temporary

        push!(stack, node)

        if typeof(node) <: InnerNode
            for child in node.children
                if child.state == unmarked
                    push!(stack, child)
                elseif child.state == temporary
                    error("network contains cycle. Not a DAG.")
                end
            end
        end
    end

    # reset state of nodes:
    for node in order
        node.state = unmarked
    end

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
Display a SumProductNetwork object.
"""
function Base.show(io::IO, spn::SumProductNetwork)
    print(io, "SumProductNetwork(size=$(length(spn)))")
end


"""
The number of nodes of the SumProductNetwork.
"""
function Base.length(spn::SumProductNetwork)
    return length(spn.order)
end