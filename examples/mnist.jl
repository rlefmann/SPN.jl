################################################################
# MNIST PCA FEATURES
# This (almost) reproduces the experiment in section 7.1 of
# R. Peharz - Foundations of Sum-Product Networks for
# Probabilistic Modeling.
################################################################

using SPN
using Gadfly

n = 1000

data = readcsv("mnist-pca.csv")

function trainspn(p::Int)
    x = data[1:n, 1:p*p]
    spn = structureLearnPoon(x,p,p,nsum=5,nleaf=10,baseres=1)
    llhvals = parameterLearnEM!(spn, x, iterations=30)
    return llhvals./(p*p)  # llhvals normalized by number of random variables
end


llhvals2 = trainspn(2)
llhvals3 = trainspn(3)
llhvals4 = trainspn(4)

l1 = layer(y=llhvals2, Geom.point, Geom.line, Theme(default_color=colorant"red"))
l2 = layer(y=llhvals3, Geom.point, Geom.line, Theme(default_color=colorant"blue"))
l3 = layer(y=llhvals4, Geom.point, Geom.line, Theme(default_color=colorant"green"))
plot(l1, l2, l3)