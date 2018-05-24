################################################################
# INFERENCE METHODS FOR SPN OBJECTS
################################################################

using DataStructures

marginalInference!(spn::SumProductNetwork, x::Matrix{Float64}) = eval!(spn, x)
marginalInference!(spn::SumProductNetwork, x::Vector{Float64}) = eval!(spn, x)

marginalInference!(spn::SumProductNetwork, x::AbstractVecOrMat) = marginalInference!(spn, float(x))

"""
Marginal inference with incomplete evidence. Queries of type P(E=e),
where E ⊆ X.
"""
function marginalInference!(spn::SumProductNetwork, x::AbstractVecOrMat, e::BitArray)
	xfloat = convert_to_float(x, e)
	return eval!(spn, xfloat)
end


"""
Conditional inference. Queries of type P(Q=q | E=e).

We have P(q|e) = P(q,e)/P(e), so it can be computed with two upward passes.
Because we compute probabilities in logspace, we have
log(P(q|e)) = log(P(q,e)/P(e)) = log(P(q,e)) - log(P(e)).
"""
function conditionalInference!(spn::SumProductNetwork, x::AbstractVecOrMat, q::BitVector, e::BitVector)
	if !(size(x)[end] == length(q) == length(e))
		throw(ArgumentError("the input x, the query bitvector, and the evidence bitvector must have the same length"))
	elseif sum(q .& e) > 0
		throw(ArgumentError("a query variable is also part of the evidence"))
	end
	qe = q .| e
	log_joint_prob = marginalInference!(spn, x, qe)
	log_evidence_prob = marginalInference!(spn, x, e)
	return log_joint_prob .- log_evidence_prob
end


"""
Given values for some set of variables E ⊆ X, find the most
likely assignment to all remaining variables Q = X\E.
"""
function mpeInference!(spn::SumProductNetwork, x::AbstractMatrix, e::BitVector; maxeval=true)
	if !(size(x)[end] == length(e))
		throw(ArgumentError("the input x and the evidence bitvector must have the same length"))
	end
	xfloat = convert_to_float(x, e)
	mpeInference!(spn, x, maxeval = maxeval)
end


"""
Given values for variables, find the most likely assignment to all remaining variables.
Entries in `x` for variables with unknown value are assumed to be `NaN`.
"""
function mpeInference!(spn::SumProductNetwork, x::Matrix{Float64}; maxeval=true)
	maxchids = eval_mpe!(spn, x, maxeval = maxeval)
	stack = Stack(Int)  # stack of node ids
	for i in 1:size(x, 1)  # for each datapoint. this can probably be parallelized
		push!(stack, spn.root.id)
		while length(stack) > 0
		 	id = pop!(stack)
			node = spn.id2node[id]
			if isa(node, SumNode)
				maxchild = maxchids[node.id, i]
				push!(stack, maxchild)
				println("$maxchild added to stack")
			elseif isa(node, ProdNode)
				for child in node.children
					push!(stack, child.id)
					println("$(child.id) added to stack")
				end
			elseif isa(node, IndicatorNode)
				varidx = node.scope[1]
				x[i, varidx] = node.indicates
				println("set x[$i, $varidx] to $(node.indicates)")
			elseif isa(node, GaussianNode)
				varidx = node.scope[1]
				x[i, varidx] = node.μ
				println("set x[$i, $varidx] to $(node.μ)")
			end
		end
	end
end
