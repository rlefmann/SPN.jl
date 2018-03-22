using SPN
using MNIST
using MultivariateStats
using Gadfly

x, y = traindata()
@show size(x)
@show size(y)


pcaModel = fit(PCA, x; maxoutdim=9)
xTransformed = transform(pcaModel, x)
# swap rows and columns:
x = xTransformed'


# Normalize the dataset such that each
# variable (column) has mean 0 and variance 1.

function normalizeDataset!(x::AbstractArray)
    x = x .- mean(x,1)
    x = x
    return x ./ std(x,1)
end

x = normalizeDataset!(x)
spn = structureLearnPoon(x,3,3,nsum=5,nleaf=10,baseres=1)
x = x[1:100,:]
llhvals = parameterLearnEM!(spn, x)



plot(y=llhvals, Geom.point, Geom.line)