using SPN
using Base.Test


function test_inner_node_construction()
	# Create a product node and check the values of its fields:
	p = ProdNode()
	@test p.logval == -Inf
	@test p.parents == InnerNode[]
	@test p.children == Node[]
	@test p.scope == Int[]

	# Create a sum node and check the values of its fields:
	s = SumNode()
	@test s.logval == -Inf
	@test s.parents == InnerNode[]
	@test s.children == Node[]
	@test s.scope == Int[]
	@test s.weights == Float64[]
end


function test_indicator_node_construction()
	# Create an indicator node and check the values of its fields:
	i = IndicatorNode(1,3.0)
	@test i.logval == -Inf
	@test i.parents == InnerNode[]
	@test length(i.scope) == 1
	@test i.scope == [1]
	@test i.indicates == 3.0

	# Indicator nodes for integer and boolean variables:
	i2 = IndicatorNode(2,1)
	@test i2.indicates == 1.0
	i3 = IndicatorNode(3,true)
	@test i3.indicates == 1.0
	i4 = IndicatorNode(3,false)
	@test i4.indicates == 0.0
end


function test_connect_nodes()
	s = SumNode()
	p1 = ProdNode()
	p2 = ProdNode()
	i1 = IndicatorNode(1,0)
	i2 = IndicatorNode(1,1)
	i3 = IndicatorNode(1,2)

	connect!(s,p1,weight=0.3)
	connect!(s,p2,weight=0.7)
	connect!(p1,i1)
	connect!(p1,i2)
	connect!(p2,i2)
	connect!(p2,i3)

	@test length(s.children) == 2
	@test length(p1.children) == 2
	@test length(p2.children) == 2
	@test p1 in s.children
	@test p2 in s.children
	@test i1 in p1.children
	@test !(i1 in p2.children)
end


function test_eval_indicator_node()
	i1 = IndicatorNode(1, 1.0)
	i2 = IndicatorNode(2, 2.0)
	i3 = IndicatorNode(3, 3.0)
	x1 = Float64[1.0, 5.0]
	x2 = Float64[1.0, 2.0]
	eval!(i1, x1)
	@test i1.logval == 0.0
	eval!(i2, x1)
	@test i2.logval == -Inf
	eval!(i1, x2)
	@test i1.logval == 0.0
	eval!(i2, x2)
	@test i2.logval == 0.0
	@test_throws AssertionError eval!(i3, x1)
end


test_inner_node_construction()
test_indicator_node_construction()
test_connect_nodes()
test_eval_indicator_node()