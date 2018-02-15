Inference
=========

The are demonstrated on the SPN built in the [Creating an SPN section](architecture.md).

## Marginal Inference

P(X=x)

As an example, we compute `P(X1=true, X2=false)`:

```julia
x = [true, false]
marginalInference!(spn, x)
```

## Conditional Inference

## Most Probable Explanation (MPE) Inference