# Run tests by typing `Pkg.test("SPN")`.

using SPN
using Base.Test


tests = ["architecture/testnodes",
         "architecture/testnetwork",
         "inference/testeval",
         "inference/testderivative",
         "inference/testinference",
         "learn/testpoon",
         "testutils"]

for t in tests
	println(" * $(t)")
	include("$(t).jl")
end
