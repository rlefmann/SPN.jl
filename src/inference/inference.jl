################################################################
# INFERENCE METHODS FOR SPN OBJECTS
################################################################

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
function mpeInference!(spn::SumProductNetwork, x::AbstractVector, e::BitVector)

end
