"""
Tests the computation of the evaluation order using DFS
on the toy SPN.
"""
function test_compute_order_recursive()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=true)
    expected_order = [i1, i2, s1, i3, i4, s3, p1, s4, p2, s2, p3, s]
    for i in 1:length(expected_order)
        @test spn.order[i] == expected_order[i]
        @test spn.order[i].id == i
    end
end


function test_compute_order_stack()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)
    expected_order = [i4, i3, s4, i2, i1, s2, p3, s1, p2, s3, p1, s]
    for i in 1:length(expected_order)
        @test spn.order[i] == expected_order[i]
        @test spn.order[i].id == i
    end
end


"""
Tests wether the algorithms detect cycles correctly.
"""
function test_compute_order_recursive_cycles()

    function create_spn_with_cycle()
        s1 = ProdNode()
        s2 = ProdNode()
        s3 = ProdNode()
        i1 = IndicatorNode(1, 1.0)
        connect!(s1, s2)
        connect!(s2, s3)
        connect!(s3, s1)
        connect!(s3, i1)
        
        return s1
    end

    s1 = create_spn_with_cycle()
    @test_throws ErrorException SumProductNetwork(s1, recursive=true)

    s1 = create_spn_with_cycle()
    @test_throws ErrorException SumProductNetwork(s1, recursive=false)
end


function test_eval()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)

    x = [true, false]
    setInput!(spn, x)
    eval!(spn)

    @test i1.logval ≈ log(1)
    @test i2.logval ≈ log(0)
    @test i3.logval ≈ log(0)
    @test i4.logval ≈ log(1)

    @test s1.logval ≈ log(0.6)
    @test s2.logval ≈ log(0.9)
    @test s3.logval ≈ log(0.7)
    @test s4.logval ≈ log(0.8)

    @test p1.logval ≈ log(0.42)
    @test p2.logval ≈ log(0.48)
    @test p3.logval ≈ log(0.72)

    @test s.logval ≈ log(0.522)
end


function test_eval1()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)
    setIDs!(spn)
    x = [ true false; false false; false true; true true]
    llhvals = eval!(spn, x)
    @test llhvals[1] ≈ log(0.522)
end


function test_computeDerivatives()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)

    x = [true, false]
    setInput!(spn, x)
    eval!(spn)

    computeDerivatives!(spn)

    @test s.logdrv ≈ 0

    @test p1.logdrv ≈ log(0.5)
    @test p2.logdrv ≈ log(0.2)
    @test p3.logdrv ≈ log(0.3)

    @test s1.logdrv ≈ log(0.5*0.7 + 0.2*0.8)
    @test s2.logdrv ≈ log(0.3*0.8)
    @test s3.logdrv ≈ log(0.5*0.6)
    @test s4.logdrv ≈ log(0.2*0.6 + 0.3*0.9)

    @test i1.logdrv ≈ log((0.5*0.7 + 0.2*0.8)*0.6 + (0.3*0.8)*0.9)
    @test i2.logdrv ≈ log((0.5*0.7 + 0.2*0.8)*0.4 + (0.3*0.8)*0.1)
    @test i3.logdrv ≈ log((0.5*0.6)*0.3 + (0.2*0.6 + 0.3*0.9)*0.2)
    @test i4.logdrv ≈ log((0.5*0.6)*0.7 + (0.2*0.6 + 0.3*0.9)*0.8) 
end


function test_normalize()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)

    s.weights *= 3
    s1.weights *= 5

    normalize!(spn)
    @test s.weights[1] ≈ 0.5
    @test s.weights[2] ≈ 0.2
    @test s.weights[3] ≈ 0.3
    @test s1.weights[1] ≈ 0.6
    @test s1.weights[2] ≈ 0.4
end


function test_number_of_nodes()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)

    @test numNodes(spn) == 12
    @test length(spn) == 12
    @test numSumNodes(spn) == 5
    @test numProdNodes(spn) == 3
    @test numLeafNodes(spn) == 4
    @test numNodes(spn, IndicatorNode) == 4
    @test numNodes(spn, GaussianNode) == 0
end


test_compute_order_recursive()
test_compute_order_stack()
test_compute_order_recursive_cycles()
#test_eval()
test_eval1()
#test_computeDerivatives()
test_normalize()
test_number_of_nodes()