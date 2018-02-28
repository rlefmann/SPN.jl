width = 2
height = 3
baseres = 1
nsum = 5

s = structureLearnPoon(width, height, baseres, nsum)
spn = SumProductNetwork(s)
@show spn