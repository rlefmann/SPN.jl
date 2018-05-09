################################################################
# EVALUATING NODES
# This file tests the evaluation of nodes.
################################################################



################################################################
# EXPECTED VALUES FOR EVALUATION OF TOY SPN
################################################################

"""
Compute the value of each node in the toy SPN for the given input.
"""
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


"""
Compute the value of each node in the toy SPN for the given input
when max evaluation is used, i.e. the value of a sum node is the
maximum weighted value among its children.
"""
function compute_values_for_datapoint_max(i1_val, i2_val, i3_val, i4_val)
	s1_val = maximum([0.6*i1_val, 0.4*i2_val])
	s2_val = maximum([0.9*i1_val, 0.1*i2_val])
	s3_val = maximum([0.3*i3_val, 0.7*i4_val])
	s4_val = maximum([0.3*i3_val, 0.8*i4_val])
	s2_val = 0.9*i1_val + 0.1*i2_val
	s3_val = 0.3*i3_val + 0.7*i4_val
	s4_val = 0.2*i3_val + 0.8*i4_val
	p1_val = s1_val*s3_val
	p2_val = s1_val*s4_val
	p3_val = s2_val*s4_val
	s_val = maximum([0.5*p1_val, 0.2*p2_val, 0.3*p3_val])
	return [s_val, p1_val, p2_val, p3_val, s1_val, s2_val, s3_val, s4_val, i1_val, i2_val, i3_val, i4_val]
end


"""
Compute the IDs of the winning child for each sum node
in the toy SPN when performing MPE evaluation.
"""
function compute_maxchildids_for_datapoint(i1_val, i2_val, i3_val, i4_val)
	(s1_val, s1_maxidx) = findmax([0.6*i1_val, 0.4*i2_val])
	(s2_val, s2_maxidx) = findmax([0.9*i1_val, 0.1*i2_val])
	(s3_val, s3_maxidx) = findmax([0.3*i3_val, 0.7*i4_val])
	(s4_val, s4_maxidx) = findmax([0.2*i3_val, 0.8*i4_val])
	s1_maxidx += 8  # idx1 = id9, idx2 = id10
	s2_maxidx += 8
	s3_maxidx += 10  # idx1 = id11, idx2 = id12
	s4_maxidx += 10
	s2_val = 0.9*i1_val + 0.1*i2_val
	s3_val = 0.3*i3_val + 0.7*i4_val
	s4_val = 0.2*i3_val + 0.8*i4_val
	p1_val = s1_val*s3_val
	p2_val = s1_val*s4_val
	p3_val = s2_val*s4_val
	s_val, s_maxidx = findmax([0.5*p1_val, 0.2*p2_val, 0.3*p3_val])
	s_maxidx += 1  # idx1 = id2, idx2 = id3, idx3 = id4

	maxchids = zeros(Int, 12)
	maxchids[1] = s_maxidx
	maxchids[5] = s1_maxidx
	maxchids[6] = s2_maxidx
	maxchids[7] = s3_maxidx
	maxchids[8] = s4_maxidx

	return maxchids
end


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



################################################################
# MATRIX EVALUATION OF NETWORK
################################################################

function eval_network()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)
    
    x = [ true false; false false; false true; true true]
    llhvals = eval!(spn, x)
    
    dp1_values = compute_values_for_datapoint(1.0, 0.0, 0.0, 1.0)
    dp2_values = compute_values_for_datapoint(0.0, 1.0, 0.0, 1.0)
    dp3_values = compute_values_for_datapoint(0.0, 1.0, 1.0, 0.0)
    dp4_values = compute_values_for_datapoint(1.0, 0.0, 1.0, 0.0)

    @test llhvals[1] ≈ log(dp1_values[1])
    @test llhvals[2] ≈ log(dp2_values[1])
    @test llhvals[3] ≈ log(dp3_values[1])
    @test llhvals[4] ≈ log(dp4_values[1])
end


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

    # expected result for datapoints:
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

    # expected result for datapoint 1:
    dp1_values = compute_values_for_datapoint_max(1.0, 0.0, 0.0, 1.0)
    dp2_values = compute_values_for_datapoint_max(0.0, 1.0, 0.0, 1.0)
    dp3_values = compute_values_for_datapoint_max(0.0, 1.0, 1.0, 0.0)
    dp4_values = compute_values_for_datapoint_max(1.0, 0.0, 1.0, 0.0)

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


function eval_mpe()
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
    
    llhvals = Matrix{Float64}(m, n)
    maxchids = zeros(Int, m, n)

    for node in reverse(node_vector)
    	eval_mpe!(node, x, llhvals, maxchids, maxeval=true)
    end

    dp1_values = compute_maxchildids_for_datapoint(1.0, 0.0, 0.0, 1.0)
    dp2_values = compute_maxchildids_for_datapoint(0.0, 1.0, 0.0, 1.0)
   	dp3_values = compute_maxchildids_for_datapoint(0.0, 1.0, 1.0, 0.0)
    dp4_values = compute_maxchildids_for_datapoint(1.0, 0.0, 1.0, 0.0)

    @test maxchids[:,1] == dp1_values
    @test maxchids[:,2] == dp2_values
    @test maxchids[:,3] == dp3_values
    @test maxchids[:,4] == dp4_values
end


#setinput_indicator_node()
#setinput_indicator_node_partial_evidence()
#eval_nodes()
eval_network()
eval_nodes_matrix()
eval_nodes_matrix_max()
eval_gaussian_nodes_matrix()
eval_mpe()