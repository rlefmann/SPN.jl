function test_marginal_inference_complete_evidence()
	s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s)
    x = [true, false]
    @test marginalInference!(spn, x) ≈ log(0.522)
end


test_marginal_inference_complete_evidence()