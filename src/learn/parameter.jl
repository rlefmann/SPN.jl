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
		indices = 1:n  # TODO: remove
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
						r = exp(node.children[cidx].logval) * node.weights[cidx]
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

		@show dataLikelihood!(spn, x)
	end
end


"""
Learns the parameters of an SPN using EM.

## Arguments
* `spn::SumProductNetwork`
* `x::AbstractMatrix`

## Keyword Arguments
* `iterations`
* `batchsize`

"""
function parameterLearnEM!(spn::SumProductNetwork, x::AbstractMatrix; iterations=30)
	n, d = size(x)

	# normalize all sum nodes:
	normalize!(spn)

	for t in 1:iterations

		# set counts of all sum nodes to 0.0:
		resetCounts!(spn)

		indices = 1:n
		for i in indices
			xi = vec(x[i,:])  # get datapoint
			setInput!(spn, xi)
			initDerivatives!(spn)
			eval!(spn)
			computeDerivatives!(spn)

			for node in spn.order
				if typeof(node) == SumNode
					for cidx in 1:length(node.children)
						r = exp(node.children[cidx].logval) * node.weights[cidx] / exp(node.logval) * exp(node.logdrv)
						node.counts[cidx] += r
					end
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

		@show dataLikelihood!(spn, x)
	end
end


function parameterLearnGD!(spn::SumProductNetwork, x::AbstractMatrix; iterations=30, learnrate=0.1)
	n,d = size(x)


end