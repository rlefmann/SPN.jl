"""
A (m x n) rectangle has c = m*(m+1)*n*(n+1)/4 subrectangles.
The Poon architecture has `nsum` sum nodes for every subrectangle.
Only the full rectangle (base region) is represented by just one sum node.
"""
function numSumNodesBaseres1(w, h, nsum)
	numSubRects = w*(w+1)*h*(h+1)/4
	return (numSubRects-1)*nsum + 1
end


"""
A ixj rectangle can be decomposed in i+j-2 ways.
There are therefore

\sum_{i=1}^w \sum_{j=1}^h (w+1-i)*(h+1-j)*(i+j-2)

decompositions of subrectangles.
Each decomposition is represented by nsum^2 product nodes.
"""
function numProdNodesBaseres1(w, h, nsum)
	numDecompositions = 0
	for i in 1:w, j in 1:h
		numDecompositions += (w+1-i)*(h+1-j)*(i+j-2)
	end
	return numDecompositions * nsum^2
end


width = 2
height = 3
baseres = 1
nsum = 5

s = structureLearnPoon(width, height, baseres, nsum)
spn = SumProductNetwork(s)

expectedNumNodes = numSumNodesBaseres1(width, height, nsum) + numProdNodesBaseres1(width, height, nsum)
@test length(spn) == expectedNumNodes

width = 2
height = 2
baseres = 1
nsum = 5

s = structureLearnPoon(width, height, baseres, nsum)
spn = SumProductNetwork(s)

expectedNumNodes = numSumNodesBaseres1(width, height, nsum) + numProdNodesBaseres1(width, height, nsum)
@test length(spn) == expectedNumNodes