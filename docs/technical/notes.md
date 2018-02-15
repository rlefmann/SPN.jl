Implementation Notes
====================

This document describes the progress of implementing the SPN package.

## Evaluation of nodes

An important design decision is: how does the input of the SPN look like?

The simplest idea is to give the input to the SPN as a vector. This is the approach we take first. However, this assumes complete evidence, which is an unrealistic assumption in many real-world applications.

For incomplete evidence, we can give the SPN a dictionary as input, where the keys are the indexes of random variables in the evidence. However this is costly:

```julia
julia> x = rand(10000)
julia> @benchmark xdict = Dict{Int, Float64}(enumerate(x))
BenchmarkTools.Trial: 
  memory estimate:  364.66 KiB
  allocs estimate:  25
  --------------
  minimum time:     704.016 μs (0.00% GC)
  median time:      717.570 μs (0.00% GC)
  mean time:        739.259 μs (1.40% GC)
  maximum time:     1.721 ms (38.36% GC)
  --------------
  samples:          6737
  evals/sample:     1
```

Can we do better than this? Maybe give input as a vector and a separate `evidence` vector of indices.


## Evaluation order

The evaluation order is a reversed topological order of the network. It can be obtained by a post-order traversal of the network: a node is added to the order after all of its children were added to the order. Implementing a post-order traversal recursively is easy:

```julia
function computeOrder(root::Node)
    order = Node[]

    """
    Post-order traversal for inner nodes.
    """
    function postOrder(n::InnerNode)
        for child in n.children
            if child.state == unmarked
                postOrder(child)
            end
        end
        push!(order, n)
    end

    """
    Post-order traversal for leaf nodes.
    """
    function postOrder(l::LeafNode)
        push!(order, l)
    end

    postOrder(root)
    return order
end
```

This could be too slow and we may need to switch to a non-recursive stack-based implementation.