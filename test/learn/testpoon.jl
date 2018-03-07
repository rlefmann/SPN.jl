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
function expectedNumRegions(m::Int, n::Int)
	nsr = m*(m+1)*n*(n+1)/4
	return Int(nsr)
end


function expectedNumDecompositions(m::Int, n::Int)
	nd = 0
	for i in 1:m, j in 1:n
		nd += (m+1-i)*(n+1-j)*(i+j-2)
	end
	return nd
end


function expectedNumLeafNodes(m::Int, n::Int, nleaf::Int)
	return m*n*nleaf
end


function expectedNumSumNodes(m::Int, n::Int, nsum::Int)
	return (expectedNumRegions(m,n)-m*n-1)*nsum + 1
end


function expectedNumProdNodes(m::Int, n::Int, nsum::Int, nleaf::Int)
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


function expectedNumNodes(m::Int, n::Int, nsum::Int, nleaf::Int)
	return expectedNumLeafNodes(m,n,nleaf) + expectedNumSumNodes(m,n,nsum) + expectedNumProdNodes(m,n,nsum,nleaf)
end



################################################################
# TESTS FOR THE FUNCTIONS ABOVE
################################################################

@test expectedNumRegions(3,2) == 18
@test expectedNumDecompositions(3,2) == 18
@test expectedNumLeafNodes(3,2,4) == 24
@test expectedNumSumNodes(3,2,2) == 23
@test expectedNumProdNodes(3,2,2,4) == 172
@test expectedNumNodes(3,2,2,4) == 219



################################################################
# TESTING POON ARCHITECTURE SPN WITH BASERES=1
################################################################

h = 3
w = 2
nsum = 2
nleaf = 4
baseres = 1

spn = structureLearnPoon(x, h, w, nsum=nsum, nleaf=nleaf, baseres=1)

@test length(spn) == expectedNumNodes(h,w,nsum,nleaf)
@test numNodes(spn) == expectedNumNodes(h,w,nsum,nleaf)
@test numSumNodes(spn) == expectedNumSumNodes(h,w,nsum)
@test numProdNodes(spn) == expectedNumProdNodes(h,w,nsum,nleaf)
@test numLeafNodes(spn) == expectedNumLeafNodes(h,w,nleaf)



################################################################
# TEST FUNCTIONS FOR NUMBER OF NODES (INCL. COARSE REGIONS)
################################################################

function expectedNumRegions(m::Int, n::Int, baseres::Int)
	# coarse regions:
	cm = m ÷ baseres
	cn = n ÷ baseres
	# don't count coarse unit regions:
	numCoarse = expectedNumRegions(cm, cn) - cm*cn
	# fine regions:
	numFine = cm*cn * expectedNumRegions(baseres, baseres)
	return numCoarse + numFine
end


function expectedNumDecompositions(m::Int, n::Int, baseres::Int)
	cm = m ÷ baseres
	cn = n ÷ baseres
	numCoarse = expectedNumDecompositions(cm, cn)
	numFine = cm * cn * expectedNumDecompositions(baseres, baseres)
	return numCoarse + numFine
end


function expectedNumLeafNodes(m::Int, n::Int, nleaf::Int, baseres::Int)
	return m*n*nleaf
end


function expectedNumSumNodes(m::Int, n::Int, nsum::Int, baseres::Int)
	cm = m ÷ baseres
	cn = n ÷ baseres
	numCoarse = expectedNumSumNodes(cm, cn, nsum)
	# the (+numsum-1) part takes into account that for
	# the fine decomposition the root region is represented
	# by nsum sum nodes instead of by a single sum node.
	numFine = cm * cn * (expectedNumSumNodes(baseres, baseres, nsum) + nsum - 1)
	return numCoarse + numFine
end


function expectedNumProdNodes(m::Int, n::Int, nsum::Int, nleaf::Int, baseres::Int)
	cm = m ÷ baseres
	cn = n ÷ baseres
	numCoarse = expectedNumDecompositions(cm, cn)*nsum^2
	numFine = cm * cn * expectedNumProdNodes(baseres, baseres, nsum, nleaf)
	return numCoarse + numFine
end


function expectedNumNodes(m::Int, n::Int, nsum::Int, nleaf::Int, baseres::Int)
	return expectedNumLeafNodes(m,n,nleaf,baseres) + expectedNumSumNodes(m,n,nsum,baseres) + expectedNumProdNodes(m,n,nsum,nleaf,baseres)
end



################################################################
# TESTS FOR THE FUNCTIONS ABOVE
################################################################

h=4
w=6
b=2
s=2
l=4

@test expectedNumRegions(h, w, b) == (18-6) + 6*9
@test expectedNumDecompositions(h, w, b) == 18 + 6*6
@test expectedNumLeafNodes(h, w, l, b) == 96
@test expectedNumSumNodes(h, w, s, b) == (1 + 11*2) + 6*(5*2)
@test expectedNumProdNodes(h, w, s, l, b) == 18*s^2 + 6*(2*s^2+4*l^2)
@test expectedNumNodes(h, w, s, l, b) == 96 + 23 + 60 + 72 + 432



################################################################
# TESTING POON ARCHITECTURE SPN WITH BASERES=2
################################################################

# a "dataset" with 10 data points of dimension 24:
x = reshape(1:240, :, 24)
n,d = size(x)

h = 4
w = 6
nsum = 2
nleaf = 4
b = 2

spn = structureLearnPoon(x, h, w, nsum=nsum, nleaf=nleaf, baseres=b)

@test length(spn) == expectedNumNodes(h,w,nsum,nleaf,b)
@test numNodes(spn) == expectedNumNodes(h,w,nsum,nleaf,b)
@test numSumNodes(spn) == expectedNumSumNodes(h,w,nsum,b)
@test numProdNodes(spn) == expectedNumProdNodes(h,w,nsum,nleaf,b)
@test numLeafNodes(spn) == expectedNumLeafNodes(h,w,nleaf,b)