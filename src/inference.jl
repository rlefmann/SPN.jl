################################################################
# INFERENCE METHODS FOR SPN OBJECTS
################################################################

"""
Marginal inference with incomplete evidence. Queries of type P(E=e),
where E ⊆ X.
"""
function marginalInference(x::AbstractVector, e::BitVector)

end


"""
Marginal inference with complete evidence. Queries of type P(X=x).
"""
function marginalInference(x::AbstractVector)
	n, d = size(x)
	e::BitVector = trues(d)
	return marginalInference(x, e)
end


"""
Conditional inference. Queries of type P(Q=q | E=e).
"""
function conditionalInference(x::AbstractVector, q::BitVector, e::BitVector)

end


"""
Given values for some set of variables E ⊆ X, find the most
likely assignment to all remaining variables Q = X\E.
"""
function mpeInference(x::AbstractVector, e::BitVector)

end