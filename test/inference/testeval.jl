################################################################
# EVALUATING NODES
# This file tests the evaluation of nodes.
################################################################

################################################################
# OLD WAY TO EVALUATE NODES
################################################################

################################################################
# SETTING THE INPUTS OF INDICATOR NODES
################################################################

"""
Sets the input of three indicator nodes, given two different
datapoints.
"""
function setinput_indicator_node()
	i1 = IndicatorNode(1, 1.0)
	i2 = IndicatorNode(2, 2.0)
	i3 = IndicatorNode(3, 3.0)  # there is no third variable in the data

	x1 = Float64[1.0, 5.0]
	x2 = Float64[1.0, 2.0]

	setInput!(i1, x1)
	setInput!(i2, x1)
	@test i1.logval == 0.0
	@test i2.logval == -Inf

	setInput!(i1, x2)
	@test i1.logval == 0.0
	setInput!(i2, x2)
	@test i2.logval == 0.0
	@test_throws AssertionError setInput!(i3, x1)
end


"""
Sets the input of three indicator nodes, given two different
datapoints. This time there is only partial evidence, specified
in the bitvector `e`.
"""
function setinput_indicator_node_partial_evidence()
	i1 = IndicatorNode(1, 2.0)
	i2 = IndicatorNode(1, 3.0)
	i3 = IndicatorNode(2, 2.0)
	i4 = IndicatorNode(2, 3.0)

	x = Float64[2.0, 3.0]
	e = BitVector([true, false])

	setInput!(i1, x, e)
	setInput!(i2, x, e)
	setInput!(i3, x, e)
	setInput!(i4, x, e)

	@test i1.logval == 0.0
	@test i2.logval == -Inf
	@test i3.logval == 0.0
	@test i4.logval == 0.0
end



################################################################
# EVALUATING A TOY SPN
################################################################

"""
Test the eval methods for leaf and inner nodes on the toy spn.
"""
function eval_nodes()
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

	# set input of indicator nodes:
	setInput!(i1, x)
	setInput!(i2, x)
	setInput!(i3, x)
	setInput!(i4, x)

	# Compare results:
	@test eval!(i1) ≈ log(1)
	@test eval!(i2) ≈ log(0)
	@test eval!(i3) ≈ log(0)
	@test eval!(i4) ≈ log(1)
	@test eval!(s1) ≈ log(s1_val)
	@test eval!(s2) ≈ log(s2_val)
	@test eval!(s3) ≈ log(s3_val)
	@test eval!(s4) ≈ log(s4_val)
	@test eval!(p1) ≈ log(p1_val)
	@test eval!(p2) ≈ log(p2_val)
	@test eval!(p3) ≈ log(p3_val)
	@test eval!(s) ≈ log(s_val)
end

#=
"""
Test the evaluation with the max keyword argument set to true.
Every sum node becomes a max node whose value is its maximum weighted child value.
"""
function eval_nodes_max()
	s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
	
	x = [true, false]
	e = BitVector([true, false])  # we only know the state of the first variable

	# Calculate value of nodes manually (not in logspace):
	s1_val = 0.6
	s1_idx = 1
	s2_val = 0.9
	s2_idx = 1
	s3_val = 0.7
	s3_idx = 2
	s4_val = 0.8
	s4_idx = 2
	p1_val = s1_val*s3_val
	p2_val = s1_val*s4_val
	p3_val = s2_val*s4_val
	s_val = 0.3*p3_val
	s_idx = 3

	setInput!(i1, x, e)
	setInput!(i2, x, e)
	setInput!(i3, x, e)
	setInput!(i4, x, e)

	@test eval!(i1, max=true) ≈ log(1)
	@test eval!(i2, max=true) ≈ log(0)
	@test eval!(i3, max=true) ≈ log(1)
	@test eval!(i4, max=true) ≈ log(1)
	@test eval!(s1, max=true) ≈ log(s1_val)
	@test eval!(s2, max=true) ≈ log(s2_val)
	@test eval!(s3, max=true) ≈ log(s3_val)
	@test eval!(s4, max=true) ≈ log(s4_val)
	@test eval!(p1, max=true) ≈ log(p1_val)
	@test eval!(p2, max=true) ≈ log(p2_val)
	@test eval!(p3, max=true) ≈ log(p3_val)
	@test eval!(s, max=true) ≈ log(s_val)
	@test s1.maxidx == s1_idx
	@test s2.maxidx == s2_idx
	@test s3.maxidx == s3_idx
	@test s4.maxidx == s4_idx
	@test s.maxidx == s_idx
end
=#



################################################################
# MATRIX EVALUATION OF NODES
################################################################

function eval_nodes_matrix()
	s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()

	# set the ids of the SPN nodes:
	node_vector = [s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4]
	for i in 1:length(node_vector)
		node_vector[i].id = i
	end

	# Note: the first datapoint is the same as in eval_nodes
	x = float([ true false; false false; false true; true true])
	
	n,d = size(x)
    m = length(node_vector)
    
    llhvals = Matrix{Float64}(m,n)

    for node in reverse(node_vector)
    	eval!(node, x, llhvals)
    end

    function compute_values_for_datapoint(i1_val, i2_val, i3_val, i4_val)
    	s1_val = 0.6*i1_val + 0.4*i2_val
		s2_val = 0.9*i1_val + 0.1*i2_val
		s3_val = 0.3*i3_val + 0.7*i4_val
		s4_val = 0.2*i3_val + 0.8*i4_val
		p1_val = s1_val*s3_val
		p2_val = s1_val*s4_val
		p3_val = s2_val*s4_val
		s_val = 0.5*p1_val + 0.2*p2_val + 0.3*p3_val
		return [s_val, p1_val, p2_val, p3_val, s1_val, s2_val, s3_val, s4_val, i1_val, i2_val, i3_val, i4_val]
    end

    # expected result for datapoint 1:
    dp1_values = compute_values_for_datapoint(1.0, 0.0, 0.0, 1.0)
    dp2_values = compute_values_for_datapoint(0.0, 1.0, 0.0, 1.0)
    dp3_values = compute_values_for_datapoint(0.0, 1.0, 1.0, 0.0)
    dp4_values = compute_values_for_datapoint(1.0, 0.0, 1.0, 0.0)

    @test llhvals[:,1] ≈ log.(dp1_values)
    @test llhvals[:,2] ≈ log.(dp2_values)
    @test llhvals[:,3] ≈ log.(dp3_values)
    @test llhvals[:,4] ≈ log.(dp4_values)
end


# TODO: complete
function eval_nodes_matrix_max()
	s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()

	# set the ids of the SPN nodes:
	node_vector = [s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4]
	for i in 1:length(node_vector)
		node_vector[i].id = i
	end

	# Note: the first datapoint is the same as in eval_nodes
	x = float([ true false; false false; false true; true true])
	
	n,d = size(x)
    m = length(node_vector)
    
    llhvals = Matrix{Float64}(m,n)

    for node in reverse(node_vector)
    	eval!(node, x, llhvals, maxeval=true)
    end

    function compute_values_for_datapoint(i1_val, i2_val, i3_val, i4_val)
    	s1_val = maximum([0.6*i1_val, 0.4*i2_val])
    	s2_val = maximum([0.9*i1_val, 0.1*i2_val])
    	s3_val = maximum([0.3*i1_val, 0.7*i2_val])
    	s4_val = maximum([0.2*i1_val, 0.8*i2_val])
		s2_val = 0.9*i1_val + 0.1*i2_val
		s3_val = 0.3*i3_val + 0.7*i4_val
		s4_val = 0.2*i3_val + 0.8*i4_val
		p1_val = s1_val*s3_val
		p2_val = s1_val*s4_val
		p3_val = s2_val*s4_val
		s_val = maximum([0.5*p1_val, 0.2*p2_val, 0.3*p3_val])
		return [s_val, p1_val, p2_val, p3_val, s1_val, s2_val, s3_val, s4_val, i1_val, i2_val, i3_val, i4_val]
    end

    # expected result for datapoint 1:
    dp1_values = compute_values_for_datapoint(1.0, 0.0, 0.0, 1.0)
    dp2_values = compute_values_for_datapoint(0.0, 1.0, 0.0, 1.0)
    dp3_values = compute_values_for_datapoint(0.0, 1.0, 1.0, 0.0)
    dp4_values = compute_values_for_datapoint(1.0, 0.0, 1.0, 0.0)

    @test llhvals[:,1] ≈ log.(dp1_values)
    @test llhvals[:,2] ≈ log.(dp2_values)
    @test llhvals[:,3] ≈ log.(dp3_values)
    @test llhvals[:,4] ≈ log.(dp4_values)
end


function eval_gaussian_nodes_matrix()
	x = [1.9 2.0 NaN; 0.0 NaN 3.4]
	varidx = 2
	id = 4
	μ = 0.0
	σ = 1.0
	g = GaussianNode(varidx, μ, σ, id)
	llhvals = zeros(Float64,10,2)  # first number does not matter (number of nodes in network)
	eval!(g, x, llhvals)
	for i in 1:10
		if i != id
			@test llhvals[i,:] == zeros(Float64, 2)
		elseif i == id
			@test llhvals[i,1] ≈ -log(sqrt(2*pi))-2.0  # from simplification of gaussian equation
			@test llhvals[i,2] == 0.0
		end
	end
end

setinput_indicator_node()
setinput_indicator_node_partial_evidence()
eval_nodes()
eval_nodes_matrix()
eval_nodes_matrix_max()
eval_gaussian_nodes_matrix()