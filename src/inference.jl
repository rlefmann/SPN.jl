################################################################
# INFERENCE METHODS FOR SPN OBJECTS
################################################################

"""
Marginal inference with incomplete evidence. Queries of type P(E=e),
where E ⊆ X.
"""
function marginalInference!(spn::SumProductNetwork, x::AbstractVector, e::BitVector)
	setInput!(spn, x, e)
	return eval!(spn)
end


"""
Marginal inference with complete evidence. Queries of type P(X=x).
"""
function marginalInference!(spn::SumProductNetwork, x::AbstractVector)
	d = length(x)
	e::BitVector = trues(d)
	return marginalInference!(spn, x, e)
end


"""
Conditional inference. Queries of type P(Q=q | E=e).
"""
function conditionalInference!(spn::SumProductNetwork, x::AbstractVector, q::BitVector, e::BitVector)

end


"""
Given values for some set of variables E ⊆ X, find the most
likely assignment to all remaining variables Q = X\E.
"""
function mpeInference!(spn::SumProductNetwork, x::AbstractVector, e::BitVector)

end