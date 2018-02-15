# Run tests by typing `Pkg.test("SPN")`.

using SPN
using Base.Test


"""
Creates the example SPN from the Poon paper.
"""
function create_toy_spn()
	s = SumNode()

	p1 = ProdNode()
	p2 = ProdNode()
	p3 = ProdNode()

	s1 = SumNode()
	s2 = SumNode()
	s3 = SumNode()
	s4 = SumNode()

	i1 = IndicatorNode(1,1)
	i2 = IndicatorNode(1,0)
	i3 = IndicatorNode(2,1)
	i4 = IndicatorNode(2,0)

	connect!(s,p1,weight=0.5)
	connect!(s,p2,weight=0.2)
	connect!(s,p3,weight=0.3)

	connect!(p1,s1)
	connect!(p1,s3)
	connect!(p2,s1)
	connect!(p2,s4)
	connect!(p3,s2)
	connect!(p3,s4)

	connect!(s1,i1,weight=0.6)
	connect!(s1,i2,weight=0.4)
	connect!(s2,i1,weight=0.9)
	connect!(s2,i2,weight=0.1)

	connect!(s3,i3,weight=0.3)
	connect!(s3,i4,weight=0.7)
	connect!(s4,i3,weight=0.2)
	connect!(s4,i4,weight=0.8)

	return s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4
end


include("testnodes.jl")
include("testnetwork.jl")
include("testinference.jl")
include("testutils.jl")