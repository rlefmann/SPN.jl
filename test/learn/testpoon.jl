width = 2
height = 3
baseres = 1
nsum = 5

s = structureLearnPoon(width, height, baseres, nsum)
spn = SumProductNetwork(s)

#=
A (m x n) rectangle has m*(m+1)*n*(n+1)/4 subrectangles.
Therefore the 2x3 rectangle in this case has 2*3*3*4/4 = 18 subrectangles.
Each subrectangle other than the full rectangle is represented by 5 sum nodes.
The full rectangle (root) is represented by a single sum node.
Each decomposition is represented by 5^2 = 25 product nodes.
Therefore the total number of nodes has to be 17*(25+5)+1*(25+1) = 536.

TODO: the explanation isn't quite correct, because in general
#rectangles != #decompositons.
=#

@test length(spn) == 536



width = 2
height = 2
baseres = 1
nsum = 5

s = structureLearnPoon(width, height, baseres, nsum)
spn = SumProductNetwork(s)

@test length(spn) == 191