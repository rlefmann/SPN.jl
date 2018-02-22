################################################################
# PARAMETER LEARNING OF SPNs
################################################################

using StatsBase

"""
Learns the parameters of an SPN using hard EM.

## Arguments
* `spn::SumProductNetwork`
* `x::AbstractMatrix`

## Keyword Arguments
* `iterations`
* `batchsize`

"""
function parameterLearnHardEM!(spn::SumProductNetwork, x::AbstractMatrix; iterations=30, batchsize=size(x,1))
	n, d = size(x)

	# normalize all sum nodes:
	normalize!(spn)

	for t in 1:iterations
		# set counts of all sum nodes to 0.0:
		resetCounts!(spn)
		# draw batchsize datapoints at random:
		indices = sample(1:n,batchsize,replace=false)
		for i in indices
			xi = vec(x[i,:])  # get datapoint
			setInput!(spn, xi)
			#initDerivatives!(spn)
			eval!(spn)
			#computeDerivatives!(spn)

			for node in spn.order
				if typeof(node) == SumNode

					iMax = -1
					rMax = -Inf
					for cidx in 1:length(node.children)
						r = node.children[cidx].value * node.weights[cidx]
						if r > rMax
							rMax = r
							iMax = cidx
						end
					end
					
					if iMax == -1
						continue
					end
					node.counts[iMax] += 1.0
				end
			end
		end

		# set weights according to counts:
		for node in spn.order
			if typeof(node) == SumNode
				node.weights = node.counts
                normalize!(node)
			end
		end
	end
end