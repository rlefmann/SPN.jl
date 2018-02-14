function test_addExp()
	# sequence of arguments should not matter:
	@test addExp(3.0, 5.0) ≈ addExp(5.0, 3.0)
	@test addExp(3.0, 5.0) ≈ log(exp(3)+exp(5))
end

test_addExp()