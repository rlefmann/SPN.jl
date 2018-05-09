################################################################
# PARAMETER LEARNING OF SPNs
################################################################

using StatsBase

#=
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

	llhvals = Vector{Float64}(iterations)

	for t in 1:iterations
		# set counts of all sum nodes to 0.0:
		resetCounts!(spn)
		# draw batchsize datapoints at random:
		indices = sample(1:n,batchsize,replace=false)
		indices = 1:n  # TODO: remove
		for i in indices
			xi = vec(x[i,:])  # get datapoint
			setInput!(spn, xi)
			eval!(spn, max=true)

			for node in spn.order
				if isa(node, SumNode)
					#=
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
					=#
					node.counts[node.maxidx] += 1.0
				end
			end
		end

		# set weights according to counts:
		for node in spn.order
			if isa(node, SumNode)
				@assert sum(node.counts) == n
				println(node.counts)
				node.weights = node.counts
                normalize!(node)
			end
		end

		llhvals[t] = dataLikelihood!(spn, x)
		@printf "iteration %d:\t llh=%d\n" t llhvals[t]
	end

	return llhvals
end
=#


#=
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

	llhvals = Vector{Float64}(iterations)

	for t in 1:iterations

		# set counts of all sum nodes to 0.0:
		resetCounts!(spn)

		indices = 1:n
		for i in indices
			xi = vec(x[i,:])  # get datapoint
			setInput!(spn, xi)
			initDerivatives!(spn)
			eval!(spn, max=true)
			computeDerivatives!(spn)

			for node in spn.order
				if typeof(node) == SumNode
					for cidx in 1:length(node.children)
						r = exp(node.children[cidx].logval) * node.weights[cidx] / exp(node.logval) * exp(node.logdrv)  # TODO: are the last two terms important?
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

		llhvals[t] = dataLikelihood!(spn, x)
		@printf "iteration %d:\t llh=%d\n" t llhvals[t]
	end

	return llhvals
end
=#


function parameterLearnEM!(spn::SumProductNetwork, x::AbstractMatrix; iterations=30)
	n, d = size(x)
	m = numNodes(spn)

	# normalize all sum nodes:
	normalize!(spn)
	setIDs!(spn)

	# the loglikelihood of the data under the current model:
	model_llhvals = Vector{Float64}(iterations)


	llhvals = Matrix{Float64}(m, n)
	logdrvs = Matrix{Float64}(m, n)
	counts = Dict{Int, Vector{Float64}}()
	
	for node in spn.order
		if isa(node, SumNode)
			counts[node.id] = zeros(length(node.children))
		end
	end

	
	for t in 1:iterations

		# set counts of all sum nodes to 0.0:
		#resetCounts!(spn)

		#indices = 1:n

		eval!(spn, x, llhvals)
		computeDerivatives!(spn, x, llhvals, logdrvs)
		for node in spn.order
			if isa(node, SumNode)
				childids = [child.id for child in node.children]
				r = exp.(llhvals[childids,:]) .* node.weights ./ exp.(llhvals[node.id,:])' .* exp.(logdrvs[node.id,:])'
				counts[node.id] = vec(sum(r,2))
			end
		end

		# set weights according to counts:
		for node in spn.order
			if isa(node, SumNode)
				#node.weights = node.counts
				node.weights = counts[node.id]
                normalize!(node)
                # reset counts:
                counts[node.id] = zeros(length(node.children))
			end
		end

		model_llhvals[t] = dataLikelihood!(spn, x)
		@printf "iteration %d:\t llh=%d\n" t model_llhvals[t]
	end

	return model_llhvals
end



#=
function parameterLearnGD!(spn::SumProductNetwork, x::AbstractMatrix; iterations=30, learnrate=0.1)
	n,d = size(x)

	# normalize all sum nodes:
	normalize!(spn)

	llhvals = Vector{Float64}(iterations)

	for t in 1:iterations
		indices = 1:n
		for i in indices
			xi = vec(x[i,:])
			setInput!(spn, xi)
			initDerivatives!(spn)
			eval!(spn)
			computeDerivatives!(spn)

			for node in spn.order
				if isa(node, SumNode)
					for i in 1:length(node.weights)
						node.weights[i] += learnrate * node.logdrv * node.children[i].logval
					end
		            normalize!(node)
				end
			end
				
		end

		llhvals[t] = dataLikelihood!(spn, x)
		@printf "iteration %d:\t llh=%f\n" t llhvals[t]
	end
end
=#