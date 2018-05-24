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
    @test p ≈ 0 atol=10e-6
end


function test_conditional_inference()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s)
    x = [true, false]

    # empty query and evidence should lead to log(1)=0
    q = e = falses(2)
    p = conditionalInference!(spn, x, q, e)
    @test p ≈ 0 atol=10e-6

    # if the evidence contains variables of the query an error is thrown

    # compute P(X_2 = false | X_1 = true):
    x = [true, false]
    e = BitVector([true,false])
    q = BitVector([false,true])
    # Expected result:
    # P(X_1=t,x_2=f) = 0.522
    # P(X_1=t) = 0.6*0.5 + 0.6*0.2 + 0.9*0.3 (see above)
    expected = log(0.522 / (0.6*0.5 + 0.6*0.2 + 0.9*0.3))
    @test conditionalInference!(spn, x, q, e) ≈ expected


    x = [ true false; false false; false true; true true]
    @test conditionalInference!(spn, x, q, e)[1] ≈ expected
end


function test_mpe_inference()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)

    x = [ true false; false false; false true; true true]
    x = float(x)
    x[:, 2] = NaN  # variable x2 is unknown
    expected = [1.0 0.0; 0.0 0.0; 0.0 0.0; 1.0 0.0]

    mpeInference!(spn, x)
    @test x ≈ expected

    x = [ true false; false false; false true; true true]
    x = float(x)
    x[:, 1] = NaN  # variable x1 is unknown
    expected = [1.0 0.0; 1.0 0.0; 1.0 1.0; 1.0 1.0]

    mpeInference!(spn, x)
    @test x ≈ expected
end


test_marginal_inference_complete_evidence()
test_marginal_inference_incomplete_evidence()
test_conditional_inference()
test_mpe_inference()
