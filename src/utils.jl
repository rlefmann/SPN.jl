"""
Computes `log(exp(a)+exp(b))`.
"""
function addExp(a::Float64, b::Float64)
	if a > b
		return a + log(1 + exp(b - a))
	end
	return b + log(1 + exp(a - b))
end