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


function computeOrder(root::Node)
    return Vector{Node}()  # TODO: implement post-order traversal
end