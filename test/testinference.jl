function test_marginal_inference_complete_evidence()
	s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s)
    x = [true, false]
    @test marginalInference!(spn, x) ≈ log(0.522)
end


function test_marginal_inference_incomplete_evidence()
	s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s)
    x = [true, false]
    e = BitVector([true, false])
    @test marginalInference!(spn, x, e) ≈ log(0.6*0.5 + 0.6*0.2 + 0.9*0.3)

    # no evidence at all should lead to log(1)=0
    e = BitVector([false, false])
    p = marginalInference!(spn, x, e)
    # we cannot use ≈ here, because the difference is
    # slightly bigger than the default atol:
    @test isapprox(p, 0; atol=10e-6) == true
end


test_marginal_inference_complete_evidence()
test_marginal_inference_incomplete_evidence()