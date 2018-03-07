#####################################################################
# Creates the SPN architecture for images, suggested in
# Poon and Domingos - Sum-Product Networks: A new deep architecture
#####################################################################


mutable struct PoonParameters
    width::Int
    height::Int
    "the size of coarse region is a multiple of this"
    baseres::Int
    "number of nodes that represent each region"
    nsum::Int
    "number of leaf nodes that represent each unit region."
    nleaf::Int
end 


"""
A decomposition describes how a region is split into two parts.
The two parts are represented by their regionIDs `r1_id` and `r2_id`.
"""
mutable struct Decomposition
    "The id of the first region."
    r1_id::Int
    "The id of the second region."
    r2_id::Int

    "Each decomposition has a set of product nodes."
    nodes::Vector{ProdNode}

    """
    Creates a new decompositon object.
    """
    function Decomposition(r1_id::Int, r2_id::Int)
        new(r1_id,r2_id,ProdNode[])
    end
end


"""
A region is a rectangular image patch.
"""
mutable struct Region
    "Top left position."
    a1::Int
    "Top right position"
    a2::Int
    "Bottom left position"
    b1::Int
    "Bottom right position"
    b2::Int

    "Decompositions for this region."
    decompositions::Vector{Decomposition}
    decomposed::Bool

    """
    Each region is represented by a set of sum nodes.
    Single pixel regions are represented by leaf nodes instead.
    """
    nodes::Vector{Node}

    """
    Creates a new Region object.
    """
    function Region(a1::Int, a2::Int, b1::Int, b2::Int)
        decompositions = Vector{Decomposition}()
        new(a1,a2,b1,b2,decompositions,false,Node[])
    end
end


"""
    regionID(a1::Int, a2::Int, b1::Int, b2::Int, ps::PoonParameters) -> Int

Creates a unique id for every region. The region is specified by its top left,
top right, bottom left, and bottom right position.
"""
function regionID(a1::Int, a2::Int, b1::Int, b2::Int, ps::PoonParameters)
    id = ((a1*ps.width + a2 - 1)*ps.height + b1)*ps.height+b2-1
    return id
end


"""
    regionID(a1::Int, a2::Int, b1::Int, b2::Int, ps::PoonParameters) -> Int

Creates a unique id for an existing region object.
"""
regionID(r::Region, ps::PoonParameters) = regionID(r.a1, r.a2, r.b1, r.b2, ps::PoonParameters)


"""
    generateRegionGraph!(ps::PoonParameters) -> Dict{Int,Region}

Creates a graph of regions and decompositions by decomposing an image into rectangular
subregions.
"""
function generateRegionGraph!(ps::PoonParameters)

    # width and height must be multiples of the base resolution for
    # coarse decomposition:
    @assert ps.width % ps.baseres == 0
    @assert ps.height % ps.baseres == 0

    # shorter notation for better readability:
    w = ps.width
    h = ps.height
    br = ps.baseres

    # here we collect all "visited" regions:
    regions = Dict{Int,Region}()

    # coarse regions:
    for width in br:br:w
        for height in br:br:h
            for a1 in 0:br:(w-width)
                a2 = a1 + width
                for b1 in 0:br:(h-height)
                    b2 = b1 + height
                    r = Region(a1,a2,b1,b2)
                    rid = regionID(r, ps)
                    regions[rid] = r
                end
            end
        end
    end

    # fine regions
    # ca is the left boundary of the coarse region
    # cb is the upper boundary of the coarse region
    for width in 1:br
        for height in 1:br
            if !(width==height==br)
                for ca in 0:br:w-br
                    for cb in 0:br:h-br
                        for a1 in ca:ca+br-width
                            a2 = a1 + width
                            for b1 in cb:cb+br-height
                                b2 = b1 + height
                                r = Region(a1,a2,b1,b2)
                                rid = regionID(r, ps)
                                regions[rid] = r
                            end
                        end
                    end
                end
            end
        end
    end

    # decompositions:
    for r in values(regions)  
        if r.a2 - r.a1 <= br && r.b2 - r.b1 <= br
            splitres = 1  # fine decomposition
        else
            splitres = br  # coarse decomposition
        end

        # vertical splits:
        for splitpos in r.a1+splitres:splitres:r.a2-splitres
            # left region:
            r1_id = regionID(r.a1, splitpos, r.b1, r.b2, ps)
            # right region:
            r2_id = regionID(splitpos, r.a2, r.b1, r.b2, ps)
            # add decomposition to r's list of decompositions:
            d = Decomposition(r1_id, r2_id)
            push!(r.decompositions, d)
        end


        # horizontal splits:
        for splitpos in r.b1+splitres:splitres:r.b2-splitres
            # top region:
            r1_id = regionID(r.a1, r.a2, r.b1, splitpos, ps)
            # bottom region:
            r2_id = regionID(r.a1, r.a2, splitpos, r.b2, ps)
            # add decomposition to r's list of decompositions:
            d = Decomposition(r1_id, r2_id)
            push!(r.decompositions, d)
        end
    end

    return regions
end


"""
    generateSPN!(regions::Dict{Int,Region}, nsum::Int)

Generates an SPN from a region graph by adding sum nodes
to regions and product nodes to decompositions.

## Arguments
* `regions::Dict{Int,Region}`: region graph
* `nsum::Int`: number of sum nodes per region
"""
function generateSPN!(regions::Dict{Int,Region}, ps::PoonParameters)
    # first phase. Generate sum nodes:
    for r in values(regions)
        if isRootRegion(r, ps)
            # node is root, create only one sum node:
            push!(r.nodes, SumNode())
        elseif isUnitRegion(r)
            # TODO: create Gaussian leaf node
            for _ in 1:ps.nleaf
                push!(r.nodes, GaussianNode(1, 0.0, 1.0))
            end
        else
            for _ in 1:ps.nsum
                push!(r.nodes, SumNode())
            end
        end
    end

    # Second phase. Generate product nodes and connect them to sum nodes:
    for r in values(regions)
        for d in r.decompositions
            # a product node for every possible pairing of sum nodes, one from each subregion:
            
            # get nodes from decomposition:
            r1 = regions[d.r1_id]
            r2 = regions[d.r2_id]
            for i in 1:length(r1.nodes)#ps.nsum
                for j in 1:length(r2.nodes)
                    p = ProdNode()
                    # add as a child to all of r's sum nodes:
                    for node in r.nodes
                        connect!(node,p)
                    end
                    
                    connect!(p, r1.nodes[i])
                    connect!(p, r2.nodes[j])

                    push!(d.nodes, p)
                end
            end
        end
    end
end


"""
    isRootRegion(r::Region, ps::PoonParameters) -> Bool

Checks, whether a region is the root region, i.e. the whole image.
"""
function isRootRegion(r::Region, ps::PoonParameters)
    return r.a1==0 && r.a2==ps.width && r.b1==0 && r.b2==ps.height
end


"""
    isUnitRegion(r::Region) -> Bool

Checks, whether a region is a unit region, i.e. a single pixel.
"""
function isUnitRegion(r::Region)
    return r.a2-r.a1==1 && r.b2-r.b1==1
end


"""
    generatePoonStructure() -> SumProductNetwork

Creates a SPN with the architecture suggested in
Poon and Domingos - Sum-Product Networks: A new deep architecture.
"""
function structureLearnPoon(x::AbstractMatrix, width::Int, height::Int; baseres::Int=1, nsum::Int=5, nleaf::Int=4)
    # Test validity of arguments:
    width > 0 || throw(DomainError())
    height > 0 || throw(DomainError())
    nsum > 0 || throw(DomainError())
    nleaf > 0 || throw(DomainError())
    baseres > 0 || throw(DomainError())
    width * height == size(x,2) || throw(DomainError())
    width % baseres == 0 || throw(DomainError())
    height % baseres == 0 || throw(DomainError())

    ps = PoonParameters(width, height, baseres, nsum, nleaf)
    
    print("Generating decompositions ... ")
    rs = generateRegionGraph!(ps)
    println("done")

    print("Generating SPN ...")
    generateSPN!(rs, ps)
    println("done")    
    
    rootid = regionID(0, ps.width, 0, ps.height, ps)
    r = rs[rootid]
    
    return SumProductNetwork(r.nodes[1])  # turn the root node into an SPN
end