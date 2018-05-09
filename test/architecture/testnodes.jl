using SPN
using Base.Test


function test_inner_node_construction()
	# Create a product node and check the values of its fields:
	p = ProdNode()
	@test p.parents == InnerNode[]
	@test p.children == Node[]
	@test p.scope == Int[]

	# Create a sum node and check the values of its fields:
	s = SumNode()
	@test s.parents == InnerNode[]
	@test s.children == Node[]
	@test s.scope == Int[]
	@test s.weights == Float64[]
end


function test_indicator_node_construction()
	# Create an indicator node and check the values of its fields:
	i = IndicatorNode(1,3.0)
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


#=
"""
Test matrix evaluation of SPN.
"""
function test_eval1()
	s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
	spn = SumProductNetwork(s, recursive=false)
	setIDs!(spn)

	x = float([ true false; false false; false true; true true])

	n,d = size(x)
    m = numNodes(spn)
    llhvals = Matrix{Float64}(m,n)
    for node in spn.order
        eval!(node, x, llhvals)
    end

    # i1 indicates if the first variable is 1. This is the case for datapoints 1 and 4:
    @test llhvals[i1.id, 1] == 0.0
    @test llhvals[i1.id, 2] == -Inf
    @test llhvals[i1.id, 3] == -Inf
    @test llhvals[i1.id, 4] == 0.0

    # i2 indicates if the first variable is 0. This is the case for datapoints 2 and 3:
    @test llhvals[i2.id, 1] == -Inf
    @test llhvals[i2.id, 2] == 0.0
    @test llhvals[i2.id, 3] == 0.0
    @test llhvals[i2.id, 4] == -Inf

    # i3 indicates if the second variable is 1. This is the case for datapoints 3 and 4:
    @test llhvals[i3.id, 1] == -Inf
    @test llhvals[i3.id, 2] == -Inf
    @test llhvals[i3.id, 3] == 0.0
    @test llhvals[i3.id, 4] == 0.0

    # i4 indicates if the second variable is 0. This is the case for datapoints 1 and 2:
    @test llhvals[i4.id, 1] == 0.0
    @test llhvals[i4.id, 2] == 0.0
    @test llhvals[i4.id, 3] == -Inf
    @test llhvals[i4.id, 4] == -Inf


    # Calculate value of nodes for the first datapoint manually (not in logspace):
	s1_val = 0.6*1+0.4*0
	s2_val = 0.9*1+0.1*0
	s3_val = 0.3*0+0.7*1
	s4_val = 0.2*0+0.8*1
	p1_val = s1_val*s3_val
	p2_val = s1_val*s4_val
	p3_val = s2_val*s4_val
	s_val = 0.5*p1_val + 0.2*p2_val + 0.3*p3_val

	@test llhvals[s1.id, 1] ≈ log(s1_val)
	@test llhvals[s2.id, 1] ≈ log(s2_val)
	@test llhvals[s3.id, 1] ≈ log(s3_val)
	@test llhvals[s4.id, 1] ≈ log(s4_val)

	@test llhvals[p1.id, 1] ≈ log(p1_val)
	@test llhvals[p2.id, 1] ≈ log(p2_val)
	@test llhvals[p3.id, 1] ≈ log(p3_val)
	@test llhvals[s.id, 1] ≈ log(s_val)
end
=#


function test_normalize()
	s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
	s.weights *= 3
	normalize!(s)
	@test s.weights[1] ≈ 0.5
	@test s.weights[2] ≈ 0.2
	@test s.weights[3] ≈ 0.3

	s1.weights *= 5
	normalize!(s1)
	@test s1.weights[1] ≈ 0.6
	@test s1.weights[2] ≈ 0.4
end


test_inner_node_construction()
test_indicator_node_construction()
test_connect_nodes()
#test_eval1()
# test_eval_max()  # TODO: this needs some work!
test_normalize()
