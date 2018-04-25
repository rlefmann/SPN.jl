################################################################
# EVALUATING NODES
# Creates a dataset of PCA features from the MNIST dataset.
# The dataset is stored in a CSV file mnist-pca.csv
################################################################

using MNIST
using MultivariateStats

x, y = traindata()

pcaModel = fit(PCA, x)
#pcaModel = fit(PCA, x; maxoutdim=9)
xTransformed = transform(pcaModel, x)
# swap rows and columns:
x = xTransformed'

# Normalize the dataset such that each
# variable (column) has mean 0 and variance 1.
x = x .- mean(x,1)
x = x ./ std(x,1)

writecsv("mnist-pca.csv", [x y])