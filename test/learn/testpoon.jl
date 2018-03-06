# a "dataset" with 10 data points of dimension 6:
x = reshape(1:60, :, 6)
n,d = size(x)

################################################################
# TESTING ILLEGAL INPUT PARAMETER COMBINATIONS
################################################################

@test_throws DomainError structureLearnPoon(x, 0, 0)
@test_throws DomainError structureLearnPoon(x, 0, 1)
@test_throws DomainError structureLearnPoon(x, 2, 2)
@test_throws DomainError structureLearnPoon(x, 3, 1)
@test_throws DomainError structureLearnPoon(x, -3, -2)

@test_throws DomainError structureLearnPoon(x, 3, 2, nsum=0)
@test_throws DomainError structureLearnPoon(x, 3, 2, nleaf=0)
@test_throws DomainError structureLearnPoon(x, 3, 2, nsum=-1)
@test_throws DomainError structureLearnPoon(x, 3, 2, nleaf=-1)
@test_throws DomainError structureLearnPoon(x, 3, 2, baseres=0)
@test_throws DomainError structureLearnPoon(x, 3, 2, baseres=-1)
@test_throws DomainError structureLearnPoon(x, 3, 2, baseres=3)


################################################################
# TEST FUNCTIONS FOR NUMBER OF NODES (FINE REGIONS ONLY)
################################################################

"""
A (m x n) rectangle has m*(m+1)*n*(n+1)/4 subrectangles.
"""
function numRegions(m::Int, n::Int)
	nsr = m*(m+1)*n*(n+1)/4
	return Int(nsr)
end


function numDecompositions(m::Int, n::Int)
	nd = 0
	for i in 1:m, j in 1:n
		nd += (m+1-i)*(n+1-j)*(i+j-2)
	end
	return nd
end


function numLeafNodes(m::Int, n::Int, nleaf::Int)
	return m*n*nleaf
end


function numSumNodes(m::Int, n::Int, nsum::Int)
	return (numRegions(m,n)-m*n-1)*nsum + 1
end


function numProdNodes(m::Int, n::Int, nsum::Int, nleaf::Int)
	# compute p1:
	p1 = 2*m*n - m - n

	# compute p2:
	f(x,y) = Int(x*(y*(y+1)/2 - 2y + 1))
	p2 = 2*(f(m,n) + f(n,m))

	# compute p3:
	p3 = 0
	for i in 2:m, j in 2:n
		p3 += (m+1-i)*(n+1-j)*(i+j-2)
	end
	for j in 3:n
		p3 += m*(n+1-j)*(j-3)
	end
	for i in 3:m
		p3 += n*(m+1-i)*(i-3)
	end

	return p1*nleaf^2 + p2*nleaf*nsum + p3*nsum^2
end


function numNodes(m::Int, n::Int, nsum::Int, nleaf::Int)
	return numLeafNodes(m,n,nleaf) + numSumNodes(m,n,nsum) + numProdNodes(m,n,nsum,nleaf)
end



################################################################
# TESTS FOR THE FUNCTIONS ABOVE
################################################################

@test numRegions(3,2) == 18
@test numDecompositions(3,2) == 18
@test numLeafNodes(3,2,4) == 24
@test numSumNodes(3,2,2) == 23
@test numProdNodes(3,2,2,4) == 172
@test numNodes(3,2,2,4) == 219



################################################################
# TESTING POON ARCHITECTURE SPN WITH BASERES=1
################################################################

h = 3
w = 2
nsum = 2
nleaf = 4
baseres = 1

spn = structureLearnPoon(x, h, w, nsum=nsum, nleaf=nleaf, baseres=1)

@test length(spn) == numNodes(h,w,nsum,nleaf)


#=
function numRegions(m::Int, n::Int, baseres::Int)
	coarse_m = m÷baseres
	coarse_n = n÷baseres
	numCoarse = numSubRects(coarse_m, coarse_n)
	# number of coarse unit regions:
	numCoarseBase = coarse_m * coarse_n
	numSubRectsPerCoarseBase = numSubRects(baseres, baseres)
	numFine = numCoarseBase * (numSubRectsPerCoarseBase - 1)  # -1, because we would otherwise count the coarse unit rectangles twice

	return numCoarse + numFine
end
=#




#=
function numDecompositions(m, n)
	nd = 0
	for i in 1:m, j in 1:n
		nd += (m+1-i)*(n+1-j)*(i+j-2)
	end
	return nd
end


function numSumNodes(m::Int, n::Int, baseres::Int, nsum::Int)
	nr = numRegions(m, n, baseres)
	return (nr-1)*nsum + 1
end




"""

The Poon architecture has `nsum` sum nodes for every subrectangle.
Only the full rectangle (base region) is represented by just one sum node.
"""
function numSumNodesBaseres1(w, h, nsum)
	nsr = numSubRects(h,w)
	return (nsr-1)*nsum + 1
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
=#


#=


w=2
h=2
nsum=
spn = structureLearnPoon(x, w, h)
expectedNumNodes = numSumNodesBaseres1(w, h, nsum) + numProdNodesBaseres1(width, height, nsum)
@test length(spn) == 
=#

#=
s = structureLearnPoon(width, height, baseres, nsum, nleaf)
spn = SumProductNetwork(s)

expectedNumNodes = numSumNodesBaseres1(width, height, nsum) + numProdNodesBaseres1(width, height, nsum)
@test length(spn) == expectedNumNodes

width = 2
height = 2
baseres = 1
nsum = 5
nleaf = 4

s = structureLearnPoon(width, height, baseres, nsum, nleaf)
spn = SumProductNetwork(s)

expectedNumNodes = numSumNodesBaseres1(width, height, nsum) + numProdNodesBaseres1(width, height, nsum)
@test length(spn) == expectedNumNodes
=#