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


function test_eval_inner_nodes()
	s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
	
	x = [true, false]

	# Calculate value of nodes manually (not in logspace):
	s1_val = 0.6*1+0.4*0
	s2_val = 0.9*1+0.1*0
	s3_val = 0.3*0+0.7*1
	s4_val = 0.2*0+0.8*1
	p1_val = s1_val*s3_val
	p2_val = s1_val*s4_val
	p3_val = s2_val*s4_val
	s_val = 0.5*p1_val + 0.2*p2_val + 0.3*p3_val

	# Compare results:
	@test eval!(i1, x) ≈ log(1)
	@test eval!(i2, x) ≈ log(0)
	@test eval!(i3, x) ≈ log(0)
	@test eval!(i4, x) ≈ log(1)
	@test eval!(s1, x) ≈ log(s1_val)
	@test eval!(s2, x) ≈ log(s2_val)
	@test eval!(s3, x) ≈ log(s3_val)
	@test eval!(s4, x) ≈ log(s4_val)
	@test eval!(p1, x) ≈ log(p1_val)
	@test eval!(p2, x) ≈ log(p2_val)
	@test eval!(p3, x) ≈ log(p3_val)
	@test eval!(s, x) ≈ log(s_val)
end


test_inner_node_construction()
test_indicator_node_construction()
test_connect_nodes()
test_eval_indicator_node()
test_eval_inner_nodes()