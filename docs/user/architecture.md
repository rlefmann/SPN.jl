Creating a Sum-Product Network
==============================

## Nodes

An SPN contains three types of nodes:

* sum nodes
* product nodes
* leaf nodes

A sum node computes a weighted sum of the values of its children.

```julia
s = SumNode()
```

The value of a product node product of the values of its children.

```julia
p = ProdNode()
```

A leaf node represents a univariate probability distribution. The simplest type of leaf node is an indicator node.

```julia
i = IndicatorNode(1, 1.0)
```

Nodes can be linked by an edge using the `connect!` method:

```julia
connect!(p, i)
```

If the child node is a sum node, a weight is assigned to the connection. By default this is a random value between 0 and 1. Alternatively you can specify the weight value:

```julia
connect!(s, p, weight=0.5)
```