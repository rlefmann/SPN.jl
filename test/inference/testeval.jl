################################################################
# EVALUATING NODES
# This file tests the evaluation of nodes.
################################################################



################################################################
# EXPECTED VALUES FOR EVALUATION OF TOY SPN
################################################################

"""
Compute the value of each node in the toy SPN for the given input.
If maxeval is set to true, max evaluation is used, i.e. the value
of a sum node is the maximum weighted value among its children.
"""
function compute_values_for_datapoint(i1_val, i2_val, i3_val, i4_val; maxeval::Bool=false)
    if maxeval == false
    	s1_val = 0.6*i1_val + 0.4*i2_val
    	s2_val = 0.9*i1_val + 0.1*i2_val
    	s3_val = 0.3*i3_val + 0.7*i4_val
    	s4_val = 0.2*i3_val + 0.8*i4_val
    	p1_val = s1_val*s3_val
    	p2_val = s1_val*s4_val
    	p3_val = s2_val*s4_val
    	s_val = 0.5*p1_val + 0.2*p2_val + 0.3*p3_val
    	return [s_val, p1_val, p2_val, p3_val, s1_val, s2_val, s3_val, s4_val, i1_val, i2_val, i3_val, i4_val]
    else
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
end


"""
Compute the IDs of the winning child for each sum node
in the toy SPN when performing MPE evaluation.
"""
function compute_maxchildids_for_datapoint(i1_val, i2_val, i3_val, i4_val; maxeval::Bool=false)

    values = compute_values_for_datapoint(i1_val, i2_val, i3_val, i4_val, maxeval=maxeval)

    s_val = values[1]
    p1_val = values[2]
    p2_val = values[3]
    p3_val = values[4]
    s1_val = values[5]
    s2_val = values[6]
    s3_val = values[7]
    s4_val = values[8]
    i1_val = values[9]
    i2_val = values[10]
    i3_val = values[11]
    i4_val = values[12]

    (_, s1_maxidx) = findmax([0.6*i1_val, 0.4*i2_val])
    (_, s2_maxidx) = findmax([0.9*i1_val, 0.1*i2_val])
    (_, s3_maxidx) = findmax([0.3*i3_val, 0.7*i4_val])
    (_, s4_maxidx) = findmax([0.2*i3_val, 0.8*i4_val])
    s1_maxidx += 8  # idx1 = id9, idx2 = id10
    s2_maxidx += 8
    s3_maxidx += 10  # idx1 = id11, idx2 = id12
    s4_maxidx += 10

    _, s_maxidx = findmax([0.5*p1_val, 0.2*p2_val, 0.3*p3_val])
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
# MATRIX EVALUATION OF NETWORK
################################################################

function eval_network(; maxeval=false)
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)

    x = [ true false; false false; false true; true true]
    llhvals = eval!(spn, x, maxeval=maxeval)

    dp1_values = compute_values_for_datapoint(1.0, 0.0, 0.0, 1.0, maxeval=maxeval)
    dp2_values = compute_values_for_datapoint(0.0, 1.0, 0.0, 1.0, maxeval=maxeval)
    dp3_values = compute_values_for_datapoint(0.0, 1.0, 1.0, 0.0, maxeval=maxeval)
    dp4_values = compute_values_for_datapoint(1.0, 0.0, 1.0, 0.0, maxeval=maxeval)

    @test llhvals[1] ≈ log(dp1_values[1])
    @test llhvals[2] ≈ log(dp2_values[1])
    @test llhvals[3] ≈ log(dp3_values[1])
    @test llhvals[4] ≈ log(dp4_values[1])

    # vector evaluation:
    x1 = x[1,:]
    res::Float64 = eval!(spn, x1, maxeval=maxeval)
    @test res ≈ log(dp1_values[1])
end


function eval_network_mpe(; maxeval=false)
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)

    # change order and IDs such that they correspond to the IDs
    # assumed by compute_maxchildids_for_datapoint:
    spn.order = reverse([s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4])
    for i in 1:length(spn.order)
        spn.order[i].id = 13-i
    end

    x = [ true false; false false; false true; true true]
    maxchids = eval_mpe!(spn, x, maxeval=maxeval)

    dp1_values = compute_maxchildids_for_datapoint(1.0, 0.0, 0.0, 1.0, maxeval=maxeval)
    dp2_values = compute_maxchildids_for_datapoint(0.0, 1.0, 0.0, 1.0, maxeval=maxeval)
    dp3_values = compute_maxchildids_for_datapoint(0.0, 1.0, 1.0, 0.0, maxeval=maxeval)
    dp4_values = compute_maxchildids_for_datapoint(1.0, 0.0, 1.0, 0.0, maxeval=maxeval)

    @test maxchids[:,1] == dp1_values
    @test maxchids[:,2] == dp2_values
    @test maxchids[:,3] == dp3_values
    @test maxchids[:,4] == dp4_values

    # vector evaluation:
    x1 = x[1,:]
    res::Vector{Int} = eval_mpe!(spn, x1, maxeval=maxeval)
    @test res ≈ dp1_values
end


################################################################
# MATRIX EVALUATION OF NODES
################################################################

function eval_nodes(; maxeval=false)
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
    	eval!(node, x, llhvals, maxeval=maxeval)
    end

    # expected result for datapoints:
    dp1_values = compute_values_for_datapoint(1.0, 0.0, 0.0, 1.0, maxeval=maxeval)
    dp2_values = compute_values_for_datapoint(0.0, 1.0, 0.0, 1.0, maxeval=maxeval)
    dp3_values = compute_values_for_datapoint(0.0, 1.0, 1.0, 0.0, maxeval=maxeval)
    dp4_values = compute_values_for_datapoint(1.0, 0.0, 1.0, 0.0, maxeval=maxeval)

    @test llhvals[:,1] ≈ log.(dp1_values)
    @test llhvals[:,2] ≈ log.(dp2_values)
    @test llhvals[:,3] ≈ log.(dp3_values)
    @test llhvals[:,4] ≈ log.(dp4_values)
end


function eval_nodes_mpe(;maxeval::Bool=true)
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()

    # set the ids of the SPN nodes:
    node_vector = [s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4]
    for i in 1:length(node_vector)
        node_vector[i].id = i
    end

    x = float([ true false; false false; false true; true true])

    n,d = size(x)
    m = length(node_vector)

    llhvals = Matrix{Float64}(m, n)
    maxchids = zeros(Int, m, n)

    for node in reverse(node_vector)
        eval_mpe!(node, x, llhvals, maxchids, maxeval=maxeval)
    end

    dp1_values = compute_maxchildids_for_datapoint(1.0, 0.0, 0.0, 1.0, maxeval=maxeval)
    dp2_values = compute_maxchildids_for_datapoint(0.0, 1.0, 0.0, 1.0, maxeval=maxeval)
    dp3_values = compute_maxchildids_for_datapoint(0.0, 1.0, 1.0, 0.0, maxeval=maxeval)
    dp4_values = compute_maxchildids_for_datapoint(1.0, 0.0, 1.0, 0.0, maxeval=maxeval)

    @test maxchids[:,1] == dp1_values
    @test maxchids[:,2] == dp2_values
    @test maxchids[:,3] == dp3_values
    @test maxchids[:,4] == dp4_values
end


function eval_gaussian_nodes()
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



eval_network(maxeval=true)
eval_network(maxeval=false)
eval_network_mpe(maxeval=true)
eval_network_mpe(maxeval=false)
eval_nodes(maxeval=true)
eval_nodes(maxeval=false)
eval_nodes_mpe(maxeval=true)
eval_nodes_mpe(maxeval=false)
eval_gaussian_nodes()
