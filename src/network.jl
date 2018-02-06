mutable struct SumProductNetwork
    "The root node of the SPN."
    root::Node
    "The order in which the nodes of the SPN are evaluated."
    order::Vector{Node}

    """
    Creates a new SPN from an existing graph of nodes.
    """
    function SumProductNetwork(root::Node)
        order = computeOrder(root)
        new(root, order)
    end
end


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
        if node.state == temporary
            # children have not yet been added to the stack

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
    end

    # reset state of nodes:
    for node in order
        node.state = unmarked
    end

    return order
end