s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()

# set the ids of the SPN nodes:
node_vector = [s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4]
for i in 1:length(node_vector)
	node_vector[i].id = i
end

x = float([ true false; false false; false true; true true])

n,d = size(x)
m = length(node_vector)

llhvals = Matrix{Float64}(m,n)

for node in reverse(node_vector)
	eval!(node, x, llhvals)
end

drvs_exp = zeros(Float64,m,n)
drvs_exp[1,:] = ones(n)
drvs_exp[2,:] = s.weights[1] * ones(n)  # p1
drvs_exp[3,:] = s.weights[2] * ones(n)  # p2
drvs_exp[4,:] = s.weights[3] * ones(n)  # p3
# the parents of s1 are p1 and p2:
drvs_exp[5,:] += exp.(llhvals[2,:]) ./ exp.(llhvals[5,:]) .* drvs_exp[2,:]
drvs_exp[5,:] += exp.(llhvals[3,:]) ./ exp.(llhvals[5,:]) .* drvs_exp[3,:]
# the parent of s2 is p3:
drvs_exp[6,:] = exp.(llhvals[4,:]) ./ exp.(llhvals[6,:]) .* drvs_exp[4,:]
# the parent of s3 is p1:
drvs_exp[7,:] = exp.(llhvals[2,:]) ./ exp.(llhvals[7,:]) .* drvs_exp[2,:]
# the parents of s4 are p2 and p3:
drvs_exp[8,:] += exp.(llhvals[3,:]) ./ exp.(llhvals[8,:]) .* drvs_exp[3,:]
drvs_exp[8,:] += exp.(llhvals[4,:]) ./ exp.(llhvals[8,:]) .* drvs_exp[4,:]
# the parents of i1 are s1 and s2:
drvs_exp[9,:] += s1.weights[1] .* drvs_exp[5,:]
drvs_exp[9,:] += s2.weights[1] .* drvs_exp[6,:]
# the parents of i2 are s1 and s2:
drvs_exp[10,:] += s1.weights[2] .* drvs_exp[5,:]
drvs_exp[10,:] += s2.weights[2] .* drvs_exp[6,:]
# i3:
drvs_exp[11,:] += s3.weights[1] .* drvs_exp[7,:]
drvs_exp[11,:] += s4.weights[1] .* drvs_exp[8,:]
# i4:
drvs_exp[12,:] += s3.weights[2] .* drvs_exp[7,:]
drvs_exp[12,:] += s4.weights[2] .* drvs_exp[8,:]

#=
logdrvs = -Inf * ones(Float64, m, n)

# LAYER 1
logdrvs[1,:] = zeros(n)
# TODO: remove

# LAYER 2
logdrvs[2,:] = log(s.weights[1]) + logdrvs[1,:]  # p1
logdrvs[3,:] = log(s.weights[2]) + logdrvs[1,:]  # p2
logdrvs[4,:] = log(s.weights[3]) + logdrvs[1,:]  # p3
# besser:
logdrvs[[2,3,4],:] = repeat(log.(s.weights), inner=(1,n)) .+ logdrvs[1,:]'

# LAYER 3
# parent p1 (idx 2). Children s1 (idx 5) and s3 (idx 7):
logdrvs[5,:] = exp.(llhvals[2,:] .- llhvals[5,:] .+ logdrvs[2,:])
logdrvs[7,:] = exp.(llhvals[2,:] .- llhvals[7,:] .+ logdrvs[2,:])
# parent p2 (idx 3). Children s1 (idx 5) and s4 (idx 8):
logdrvs[5,:] += exp.(llhvals[3,:] .- llhvals[5,:] .+ logdrvs[3,:])
logdrvs[8,:] = exp.(llhvals[3,:] .- llhvals[8,:] .+ logdrvs[3,:])
# parent p3 (idx 4). Children s2 (idx 6) and s4 (idx 8)
logdrvs[6,:] = exp.(llhvals[4,:] .- llhvals[6,:] .+ logdrvs[4,:])
logdrvs[8,:] += exp.(llhvals[4,:] .- llhvals[8,:] .+ logdrvs[4,:])
logdrvs[[5,6,7,8],:] = log.(logdrvs[[5,6,7,8],:])

# faster:
# parent p1:
logdrvs[[5,6,7,8],:] = -Inf .* ones(4,4)
logdrvs[[5,7],:] = addExp.(logdrvs[[5,7],:], llhvals[2,:]' .- llhvals[[5,7],:] .+ logdrvs[2,:]')
logdrvs[[5,8],:] = addExp.(logdrvs[[5,8],:], llhvals[3,:]' .- llhvals[[5,8],:] .+ logdrvs[3,:]')
logdrvs[[6,8],:] = addExp.(logdrvs[[6,8],:], llhvals[4,:]' .- llhvals[[6,8],:] .+ logdrvs[4,:]')

=#

# LAYER 4
# parent s1 (idx 5). children i1 (idx 9) and i2 (idx 10)
#logdrvs[[9,10],:] = exp.(repeat(log.(s.weights), inner=(1,n)) .+ )


logdrvs = -Inf * ones(Float64, m, n)
logdrvs[1,:] = zeros(n)
# end remove
for node in node_vector
	if typeof(node) <: InnerNode
		passDerivative!(node, x, llhvals, logdrvs)
    end
end

@test logdrvs ≈ log.(drvs_exp)