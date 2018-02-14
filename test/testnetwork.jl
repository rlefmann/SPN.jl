"""
Tests the computation of the evaluation order using DFS
on the toy SPN.
"""
function test_compute_order_recursive()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s)
    expected_order = [i1, i2, s1, i3, i4, s3, p1, s4, p2, s2, p3, s]
    for i in 1:length(expected_order)
        @test spn.order[i] == expected_order[i]
    end
end


function test_compute_order_stack()
    s, p1, p2, p3, s1, s2, s3, s4, i1, i2, i3, i4 = create_toy_spn()
    spn = SumProductNetwork(s, recursive=false)
    expected_order = [i4, i3, s4, i2, i1, s2, p3, s1, p2, s3, p1, s]
    for i in 1:length(expected_order)
        @test spn.order[i] == expected_order[i]
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

test_compute_order_recursive()
test_compute_order_stack()
test_compute_order_recursive_cycles()