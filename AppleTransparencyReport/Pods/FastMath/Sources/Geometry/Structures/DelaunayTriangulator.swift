//
//  DelaunayTriangulator.swift
//  
//
//  Created by Andrew McKnight on 11/9/17.
//

import Foundation

public struct DelaunayTriangulator {
    
    public init() {}

    public func triangulate(points: Set<Vertex>) -> LocationGraphNode? {
        if points.count == 0 {
            log("No points to triangulate.")
            return nil
        }

        let sortedPoints = points.sortedLexicographically(increasing: false)
        log(String(format: "Triangulating points: %@.", String(describing: sortedPoints)))

        guard let highestPoint = sortedPoints.first else {
            log(String(format: "There are points (%@), but could not find the lexicographically largest point.", String(describing: points)))
            return nil
        }

        let superTriangle = Triangle(x: highestPoint, y: ghost1, z: ghost2, name: "Root")
        let triangulation = LocationGraphNode(triangle: superTriangle, parents: [])
        for point in sortedPoints.dropFirst() {
            insertPoint(triangulation: triangulation, point: point)
        }

        return triangulation
    }

}

private extension DelaunayTriangulator {

    func insertPoint(triangulation: LocationGraphNode, point: Vertex) {
        log(String(format: "Inserting point (%@).", String(describing: point)))

        guard let containingNode = triangulation.findNode(containingPoint: point) else {
            log(String(format: "Point (%@) not contained in triangulation (%@).", String(describing: point), String(describing: triangulation)))
            return
        }

        // handle case where the point lies on one of the edges
        let onEdges = containingNode.triangle.edges().filter { point.isIncident(onEdge: $0) }
        if let edge = onEdges.first, let neighbor = triangulation.findTriangle(incidentOnEdge: edge, adjacentToTriangle: containingNode) {
            log(String(format: "Point (%@) lies on edge (%@).", String(describing: point), String(describing: edge)))
            handleColinearPoint(triangulation: triangulation, containingNode: containingNode, neighbor: neighbor, point: point, edge: edge)
            log(String(format: "Triangulation after inserting point (%@): %@", String(describing: point), String(describing: triangulation)))
            return
        }

        // the point lies strictly inside the triangle
        log(String(format: "Point (%@) lies strictly inside triangle (%@).", String(describing: point), String(describing: containingNode.triangle)))
        handleInteriorPoint(triangulation: triangulation, containingNode: containingNode, point: point)
        log(String(format: "Triangulation after inserting point (%@): %@", String(describing: point), String(describing: triangulation)))
    }

    func handleColinearPoint(triangulation: LocationGraphNode, containingNode: LocationGraphNode, neighbor: LocationGraphNode, point: Vertex, edge: Edge) {
        let otherEdges = containingNode.triangle.edges().filter { $0 != edge }
        var i = 0
        otherEdges.forEach { otherTriangleEdge in
            containingNode.children.append(LocationGraphNode(triangle: Triangle(edge: otherTriangleEdge, point: point, name: "\(containingNode.triangle.name):Noncolinear triangle \(i)"), parents: [ containingNode ]))
            i += 1
        }
        let otherNeighborEdges = Set(neighbor.triangle.edges().filter { $0 != edge })
        otherNeighborEdges.forEach { otherNeighborEdge in
            neighbor.children.append(LocationGraphNode(triangle: Triangle(edge: otherNeighborEdge, point: point, name: "\(containingNode.triangle.name):Noncolinear neighbor triangle \(i)"), parents: [ containingNode ]))
        }
        otherNeighborEdges.union(otherEdges).forEach {
            legalize(edge: $0, vertex: point, node: neighbor, triangulation: triangulation)
        }
    }

    func handleInteriorPoint(triangulation: LocationGraphNode, containingNode: LocationGraphNode, point: Vertex) {
        let edgeA = containingNode.triangle.a
        let edgeB = containingNode.triangle.b
        let edgeC = containingNode.triangle.c
        
        let triangleA = Triangle(edge: edgeA, point: point, name: "\(containingNode.triangle.name):A")
        let triangleB = Triangle(edge: edgeB, point: point, name: "\(containingNode.triangle.name):B")
        let triangleC = Triangle(edge: edgeC, point: point, name: "\(containingNode.triangle.name):C")

        let nodeA = LocationGraphNode(triangle: triangleA, parents: [ containingNode ])
        let nodeB = LocationGraphNode(triangle: triangleB, parents: [ containingNode ])
        let nodeC = LocationGraphNode(triangle: triangleC, parents: [ containingNode ])

        assignNewTriangleNeighbors(newNode: nodeA, neighbor1: nodeB, neighbor2: nodeC, edge: edgeA, parentNeighbor: containingNode.neighborA)
        assignNewTriangleNeighbors(newNode: nodeB, neighbor1: nodeC, neighbor2: nodeA, edge: edgeB, parentNeighbor: containingNode.neighborB)
        assignNewTriangleNeighbors(newNode: nodeC, neighbor1: nodeA, neighbor2: nodeB, edge: edgeC, parentNeighbor: containingNode.neighborC)

        [nodeA, nodeB, nodeC].forEach {
            log(String(format: "New triangle's (%@) neighbors: \n\ta: %@\n\tb: %@\n\tc: %@", String(describing: $0.triangle), String(describing: $0.neighborA?.triangle), String(describing: $0.neighborB?.triangle), String(describing: $0.neighborC?.triangle)))
        }

        containingNode.children.append(contentsOf: [ nodeA, nodeB, nodeC ])

        legalize(edge: edgeA, vertex: point, node: nodeA, triangulation: triangulation)
        legalize(edge: edgeB, vertex: point, node: nodeB, triangulation: triangulation)
        legalize(edge: edgeC, vertex: point, node: nodeC, triangulation: triangulation)
    }
    
    /// Assign the three neighbors for a new `Triangle`'s `LocationGraphNode` across each of its edges, and set it as the neighbor for each of the parent `LocationGraphNode`'s neighbors.
    ///
    /// - Parameters:
    ///   - newNode: The `LocationGraphNode` for the new `Triangle` inserted into the triangulation.
    ///   - neighbor1: The `LocationGraphNode` for the `Triangle` across from the `Edge` whose `a` `Vertex` is the `b` `Vertex` of the provided edge.
    ///   - neighbor2: The `LocationGraphNode` for the `Triangle` across from the `Edge` whose `a` `Vertex` is the `b` `Vertex` of the edge corresponding to `neighbor1`.
    ///   - edge: The `Edge` of the parent `LocationGraphNode`'s `Triangle` that was used to create the `Triangle` in `newNode`.
    ///   - parentNeighbor: The `newNode`'s parent `LocationGraphNode`'s neighbor across `edge`, which will become the neighbor of `newNode` across `edge`.
    ///
    /// - Note: The geometrical representation. `edge` is labeled, as is the inserted point that caused the new `Triangle` to be inserted. Note the counterclockwise direction of `newNode`'s `Triangle`'s edges means we immediately know which edges `neighbor1` and `neighbor2` are adjacent across, since neighbor references are specific to edges.
    ///```
    ///    _________________________
    ///   |                        /↑\
    ///   |                       / | \
    ///   |                      /  |  \
    ///   |                     /   |   \
    ///   |                    /    |    \
    ///   |  parentNeighbor   /     |     \
    ///   |                  /      |      \
    ///   |                 /       |       \
    ///   |                /        |        \
    ///   |               /         |         \
    ///   |             edge        |          \
    ///   |             /           |           \
    ///   |            /            |            \
    ///   |           /             |             \
    ///   |          /              |              \
    ///   |         /    newNode    |   neighbor2   \
    ///   |        /               ↗*.               \
    ///   |       /            ,/   ↑  \ .            \
    ///   |      /          ,/      |      \.          \
    ///   |     /       , /     inserted      \.        \
    ///   |    /    , /          point           \ .     \
    ///   |   /  ,/                                 \.    \
    ///   |  / /            neighbor1                  \ . \
    ///   |.↙______________________________________________\\
    ///```
    func assignNewTriangleNeighbors(newNode: LocationGraphNode, neighbor1: LocationGraphNode, neighbor2: LocationGraphNode, edge: Edge, parentNeighbor: LocationGraphNode?) {
        if newNode.triangle.a == edge {
            newNode.neighborA = parentNeighbor
            newNode.neighborB = neighbor1
            newNode.neighborC = neighbor2
        } else if newNode.triangle.b == edge {
            newNode.neighborA = neighbor2
            newNode.neighborB = parentNeighbor
            newNode.neighborC = neighbor1
        } else if newNode.triangle.c == edge {
            newNode.neighborA = neighbor1
            newNode.neighborB = neighbor2
            newNode.neighborC = parentNeighbor
        }
        
        // assign the parent container's neighbor's appropriate neighbor (according to the specified edge) property to the new node
        if let parentNeighbor = parentNeighbor {
            if parentNeighbor.triangle.a == edge {
                parentNeighbor.neighborA = newNode
            } else if parentNeighbor.triangle.b == edge {
                parentNeighbor.neighborB = newNode
            } else if parentNeighbor.triangle.c == edge {
                parentNeighbor.neighborC = newNode
            }
        }
    }

    /// Test an edge for the Delaunay property and if it fails, flip it.
    ///
    /// - Parameters:
    ///   - edge: An `Edge` of a newly inserted `Triangle`, to test for the Delaunay property.
    ///   - vertex: The new point being inserted into the triangulation.
    ///   - node: The `LocationGraphNode` containing the new `Triangle` created after inserting the point, whose edges must be tested for the Delaunay property.
    ///   - triangulation: The root `LocationGraphNode` that references the full triangulation being maintained.
    ///   - callDepth: The current level of recursion, for logs.
    func legalize(edge: Edge, vertex: Vertex, node: LocationGraphNode, triangulation: LocationGraphNode, callDepth: Int = 0) {
        let depthMarker = String(repeating: "*", count: callDepth + 1)
        log(String(format: "%@ Legalizing edge (%@) with vertex (%@).", depthMarker, String(describing: edge), String(describing: vertex)))

        // get the point on the neighboring triangle that isn't an endpoint of the edge
        guard let neighbor = node.triangle.a == edge ? node.neighborA : node.triangle.b == edge ? node.neighborB : node.neighborC else {
            log(String(format: "%@ Current triangle (%@) has no neighbor across edge %@, so it is legal.", depthMarker, String(describing: node.triangle), String(describing: edge)))
            return
        }

        let x = neighbor.triangle.a.a
        let y = neighbor.triangle.a.b
        let z = neighbor.triangle.b.b
        let otherPoint = edge.a == x || edge.b == x ? (edge.a == y || edge.b == y ? z : y) : x

        if isEdgeLegal(triangulation: triangulation, node: node, edge: edge, vertex: vertex, otherPoint: otherPoint, callDepth: callDepth) {
            return
        }

        let legalEdge = Edge(x: otherPoint, y: vertex, name: "Flipped(\(edge.name), \(node.triangle.name), \(neighbor.triangle.name)")
        log(String(format: "%@ Edge %@ is illegal because the neighboring triangle's opposing point %@ lies inside the circumcircle of the new triangle %@. New legal edge: %@.", depthMarker, String(describing: edge), String(describing: otherPoint), String(describing: node.triangle), String(describing: legalEdge)))

        // construct the new triangles replacing the old ones that met on the flipped edge
        let A = Triangle(edge: legalEdge, point: edge.a, name: "\(legalEdge.name).A")
        let B = Triangle(edge: legalEdge, point: edge.b, name: "\(legalEdge.name).B")
        let nodeA = LocationGraphNode(triangle: A, parents: [ node, neighbor ])
        let nodeB = LocationGraphNode(triangle: B, parents: [ node, neighbor ])

        assignNeighborsAfterEdgeFlip(node: node, neighbor: neighbor, nodeA: nodeA, nodeB: nodeB, legalEdge: legalEdge, edge: edge, callDepth: callDepth)

        // Insert new nodes in the data structure, at a new level under the nodes whose triangles were invalidated by the edge flip. Since the new triangles occupy the same space, and each intersects with both old triangles, then assign them both as children of each old triangle.
        let newNodes = [nodeA, nodeB]
        node.children.append(contentsOf: newNodes)
        neighbor.children.append(contentsOf: newNodes)

        // MARK: RECURSION - propogate edge legalization
        legalize(edge: Edge(x: edge.a, y: otherPoint, name: "RecursivelyLegalized_A"), vertex: vertex, node: nodeA, triangulation: triangulation, callDepth: callDepth + 1)
        legalize(edge: Edge(x: edge.a, y: vertex, name: "RecursivelyLegalized_B"), vertex: otherPoint, node: nodeA, triangulation: triangulation, callDepth: callDepth + 1)
        legalize(edge: Edge(x: edge.b, y: otherPoint, name: "RecursivelyLegalized_C"), vertex: vertex, node: nodeB, triangulation: triangulation, callDepth: callDepth + 1)
        legalize(edge: Edge(x: edge.b, y: vertex, name: "RecursivelyLegalized_D"), vertex: otherPoint, node: nodeB, triangulation: triangulation, callDepth: callDepth + 1)

        log(String(format: "%@ Finished legalizing edge (%@) with vertex (%@).", depthMarker, String(describing: edge), String(describing: vertex)))
    }

    func isEdgeLegal(triangulation: LocationGraphNode, node: LocationGraphNode, edge: Edge, vertex: Vertex, otherPoint: Vertex, callDepth: Int) -> Bool {
        let depthMarker = String(repeating: "*", count: callDepth + 1)
        let rootEdge = triangulation.triangle.edges().contains(edge)
        guard !rootEdge else {
            log(String(format: "%@ Skipping edge on root triangle.", depthMarker))
            return true
        }

        let hasGhostPoint = ghosts.intersection(Set(edge.endpoints())).count > 0
        guard !hasGhostPoint else {
            return !isIllegalGhostEdge(edge: edge, vertex: vertex, otherPoint: otherPoint, callDepth: callDepth)
        }
        
        guard !ghosts.contains(otherPoint) else {
            log(String(format: "%@ otherPoint (%@) is a ghost point, and cannot lie within any circumcircle", depthMarker, String(describing: otherPoint)))
            return true
        }

        let passesIncircleTest = !node.triangle.circumcircleContains(vertex: otherPoint)
        log(String(format: "%@ Other point %@ lies %@ circumcircle of triangle %@. Edge %@ is %@.", depthMarker, String(describing: otherPoint), passesIncircleTest ? "outside" : "inside or on", String(describing: node.triangle), String(describing: edge), passesIncircleTest ? "legal" : "illegal"))
        return passesIncircleTest
    }

    func isIllegalGhostEdge(edge: Edge, vertex: Vertex, otherPoint: Vertex, callDepth: Int) -> Bool {
        let depthMarker = String(repeating: "*", count: callDepth + 1)
        // ghost points never lie inside a circumcircle
        if ghosts.contains(otherPoint) {
            log(String(format: "%@ Edge is legal due to ghost point rule: Test point is a ghost point.", depthMarker))
            return false
        }

        // if vertex is ghost2 and ghost1 is an endopint of the edge
        if vertex == ghost1 && edge.endpoints().contains(ghost2) {
            log(String(format: "%@ Edge is illegal due to ghost point rule: Original point is ghost1 and edge contains ghost2.", depthMarker))
            return true
        }

        let testEdge = Edge(x: otherPoint, y: vertex, name: "Illegal ghost test edge")
        let otherLargerThanVertex = otherPoint.lexicographicallyLargerThan(otherPoint: vertex)
        let bLeftOfTestEdge = edge.b.liesToLeft(ofEdge:testEdge)

        if edge.a == ghost1 && otherLargerThanVertex && !bLeftOfTestEdge {
            log(String(format: "%@ Edge is illegal due to ghost point rule: edge.a == ghost1 && otherLargerThanVertex && !bLeftOfTestEdge", depthMarker))
            return true
        }
        if edge.a == ghost1 && !otherLargerThanVertex && bLeftOfTestEdge {
            log(String(format: "%@ Edge is illegal due to ghost point rule: edge.a == ghost1 && !otherLargerThanVertex && bLeftOfTestEdge", depthMarker))
            return true
        }

        if edge.a == ghost2 && otherLargerThanVertex && bLeftOfTestEdge {
            log(String(format: "%@ Edge is illegal due to ghost point rule: edge.a == ghost2 && otherLargerThanVertex && bLeftOfTestEdge", depthMarker))
            return true
        }
        if edge.a == ghost2 && !otherLargerThanVertex && !bLeftOfTestEdge {
            log(String(format: "%@ Edge is illegal due to ghost point rule: edge.a == ghost2 && !otherLargerThanVertex && !bLeftOfTestEdge", depthMarker))
            return true
        }

        let aLeftOfTestEdge = edge.a.liesToLeft(ofEdge:testEdge)

        if edge.b == ghost1 && otherLargerThanVertex && !aLeftOfTestEdge {
            log(String(format: "%@ Edge is illegal due to ghost point rule: edge.b == ghost1 && otherLargerThanVertex && !aLeftOfTestEdge", depthMarker))
            return true
        }
        if edge.b == ghost1 && !otherLargerThanVertex && aLeftOfTestEdge {
            log(String(format: "%@ Edge is illegal due to ghost point rule: edge.b == ghost1 && !otherLargerThanVertex && aLeftOfTestEdge", depthMarker))
            return true
        }

        if edge.b == ghost2 && otherLargerThanVertex && aLeftOfTestEdge {
            log(String(format: "%@ Edge is illegal due to ghost point rule: edge.b == ghost2 && otherLargerThanVertex && aLeftOfTestEdge", depthMarker))
            return true
        }
        if edge.b == ghost2 && !otherLargerThanVertex && !aLeftOfTestEdge {
            log(String(format: "%@ Edge is illegal due to ghost point rule: edge.b == ghost2 && !otherLargerThanVertex && !aLeftOfTestEdge", depthMarker))
            return true
        }

        log(String(format: "%@ Edge is legal due to ghost point rules", depthMarker))
        return false
    }

    /// After an edge flip, the two triangles adjacent on the old illegal edge are replaced by two new triangles adjecent on the new legal edge are created and inserted in the old ones' places. Get the old triangles' location graph nodes' neighbors and assign them as the new ones' neighbors across the appropriate edges.
    ///
    /// - Parameters:
    ///   - node: The `Triangle` formed by the `Edge` that was flipped and the `Vertex` being inserted into the triangulation.
    ///   - neighbor: The `Triangle` neighboring `node`'s `Triangle`, incident on `Edge`.
    ///   - nodeA: The new `Triangle` formed after edge flipping by the start `Vertex` of the flipped edge, the inserted `Vertex` and the `Vertex` in `neighbor` not incident on `edge`.
    ///   - nodeB: The new `Triangle` formed after edge flipping by the end `Vertex` of the flipped edge, the inserted `Vertex` and the `Vertex` in `neighbor` not incident on `edge`.
    ///   - legalEdge: The new `Edge` formed after flipping `edge`.
    ///   - edge: The illegal `Edge` failing the Delaunay property.
    ///   - callDepth: The current level of recursion, for logs.
    ///
    /// - Note: Configuration before and after:
    /// ```
    ///               ^                                ^
    ///              /|\                              /|\
    ///             / | \                            / | \
    ///            /  |  \                          /  |  \
    ///           /   |   \                        /   |   \
    ///          / W  ^  X \                      / W  ^  X \
    ///         /   /   \   \                    /   / | \   \
    ///        /  /eW   eX\  \                  /  /   |   \  \
    ///       / /           \ \                / /eW   |   eX\ \
    ///      //      node     \\              //       |       \\
    ///      --illegal-edge-----    ---->     /  nodeA | nodeB  \
    ///      \\    neighbor   //              \\       |       //
    ///       \ \           / /                \ \eY   |   eZ/ /
    ///        \  \eY   eZ/  /                  \  \   |↖  /  /
    ///         \   \   /   /                    \legal|edge /
    ///          \    v    /                      \    v    /
    ///           \ Y | Z /                        \ Y | Z /
    ///            \  |  /                          \  |  /
    ///             \ | /                            \ | /
    ///              \|/                              \|/
    ///               v                                v
    /// ```
    func assignNeighborsAfterEdgeFlip(node: LocationGraphNode, neighbor: LocationGraphNode, nodeA: LocationGraphNode, nodeB: LocationGraphNode, legalEdge: Edge, edge: Edge, callDepth: Int) {
        let depthMarker = String(repeating: "*", count: callDepth + 1)
        // determine new neighbors after the edge flip, and the edges they meet at
        var W, X, Y, Z: LocationGraphNode?
        var eW, eX, eY, eZ: Edge

        ((W, X), (eW, eX)) = findNewNeighborsAndEdgesAfterEdgeFlip(target: node, edge: edge, callDepth: callDepth)
        ((Y, Z), (eY, eZ)) = findNewNeighborsAndEdgesAfterEdgeFlip(target: neighbor, edge: edge, callDepth: callDepth)

        // set all the new neighbor relationships
        setSurroundingNeighborsAfterEdgeFlip(newNodeA: nodeA, newNodeB: nodeB, newNeighbor: W, edge: eW, oldNode: node, oldNeighbor: neighbor, callDepth: callDepth)
        setSurroundingNeighborsAfterEdgeFlip(newNodeA: nodeA, newNodeB: nodeB, newNeighbor: X, edge: eX, oldNode: node, oldNeighbor: neighbor, callDepth: callDepth)
        setSurroundingNeighborsAfterEdgeFlip(newNodeA: nodeA, newNodeB: nodeB, newNeighbor: Y, edge: eY, oldNode: node, oldNeighbor: neighbor, callDepth: callDepth)
        setSurroundingNeighborsAfterEdgeFlip(newNodeA: nodeA, newNodeB: nodeB, newNeighbor: Z, edge: eZ, oldNode: node, oldNeighbor: neighbor, callDepth: callDepth)

        // set each new triangle as the other's neighbor
        setNeighborsAcrossFlippedEdge(from: nodeA, to: nodeB, acrossEdge: legalEdge, callDepth: callDepth)
        setNeighborsAcrossFlippedEdge(from: nodeB, to: nodeA, acrossEdge: legalEdge, callDepth: callDepth)

        [nodeA, nodeB].forEach {
            log(String(format: "%@ New triangle's (%@) neighbors: \n\ta: %@\n\tb: %@\n\tc: %@", depthMarker, String(describing: $0.triangle), String(describing: $0.neighborA?.triangle), String(describing: $0.neighborB?.triangle), String(describing: $0.neighborC?.triangle)))
        }
    }

    func findNewNeighborsAndEdgesAfterEdgeFlip(target: LocationGraphNode, edge: Edge, callDepth: Int) -> (neighbors: (LocationGraphNode?, LocationGraphNode?), edges: (Edge, Edge)) {
        let depthMarker = String(repeating: "*", count: callDepth + 1)
        var neighborEdge: Edge
        var neighbor: LocationGraphNode?

        if target.triangle.a != edge {
            neighbor = target.neighborA
            neighborEdge = target.triangle.a
        } else if target.triangle.b != edge {
            neighbor = target.neighborB
            neighborEdge = target.triangle.b
        } else {
            neighbor = target.neighborC
            neighborEdge = target.triangle.c
        }

        log(String(format: "%@ Found neighbor (%@) across edge (%@).", depthMarker, String(describing: neighbor), String(describing: neighborEdge)))

        if !(target.triangle.a == edge || target.triangle.a == neighborEdge) {
            log(String(format: "%@ Found other neighbor (%@) across edge (%@).", depthMarker, String(describing: target.neighborA), String(describing: target.triangle.a)))
            return ((neighbor, target.neighborA), (neighborEdge, target.triangle.a))
        } else if !(target.triangle.b == edge || target.triangle.b == neighborEdge) {
            log(String(format: "%@ Found other neighbor (%@) across edge (%@).", depthMarker, String(describing: target.neighborB), String(describing: target.triangle.b)))
            return ((neighbor, target.neighborB), (neighborEdge, target.triangle.b))
        } else {
            log(String(format: "%@ Found other neighbor (%@) across edge (%@).", depthMarker, String(describing: target.neighborC), String(describing: target.triangle.c)))
            return ((neighbor, target.neighborC), (neighborEdge, target.triangle.c))
        }
    }

    /// Sets `to` as `from`'s neighbor across `edge`
    /// - Warning: Not commutative. Must call one time each for a pair of neighbors.
    func setNeighborsAcrossFlippedEdge(from: LocationGraphNode, to: LocationGraphNode, acrossEdge edge: Edge, callDepth: Int) {
        let depthMarker = String(repeating: "*", count: callDepth + 1)
        if from.triangle.a == edge {
            log(String(format: "%@ Setting triangle's (%@) A neighbor to (%@) across edge (%@).", depthMarker, String(describing: from.triangle), String(describing: to.triangle), String(describing: edge)))
            from.neighborA = to
        }
        else if from.triangle.b == edge {
            log(String(format: "%@ Setting triangle's (%@) B neighbor to (%@) across edge (%@).", depthMarker, String(describing: from.triangle), String(describing: to.triangle), String(describing: edge)))
            from.neighborB = to
        }
        else if from.triangle.c == edge {
            log(String(format: "%@ Setting triangle's (%@) C neighbor to (%@) across edge (%@).", depthMarker, String(describing: from.triangle), String(describing: to.triangle), String(describing: edge)))
            from.neighborC = to
        }
    }

    func setSurroundingNeighborsAfterEdgeFlip(newNodeA: LocationGraphNode, newNodeB: LocationGraphNode, newNeighbor: LocationGraphNode?, edge: Edge, oldNode: LocationGraphNode, oldNeighbor: LocationGraphNode, callDepth: Int) {
        let depthMarker = String(repeating: "*", count: callDepth + 1)
        if newNodeA.triangle.a == edge {
            log(String(format: "%@ Setting triangle's (%@) A neighbor to (%@) across edge (%@).", depthMarker, String(describing: newNodeA.triangle), String(describing: newNeighbor?.triangle), String(describing: edge)))
            newNodeA.neighborA = newNeighbor
        }
        else if newNodeA.triangle.b == edge {
            log(String(format: "%@ Setting triangle's (%@) B neighbor to (%@) across edge (%@).", depthMarker, String(describing: newNodeA.triangle), String(describing: newNeighbor?.triangle), String(describing: edge)))
            newNodeA.neighborB = newNeighbor
        }
        else if newNodeA.triangle.c == edge {
            log(String(format: "%@ Setting triangle's (%@) C neighbor to (%@) across edge (%@).", depthMarker, String(describing: newNodeA.triangle), String(describing: newNeighbor?.triangle), String(describing: edge)))
            newNodeA.neighborC = newNeighbor
            
        }
        else if newNodeB.triangle.a == edge {
            log(String(format: "%@ Setting triangle's (%@) A neighbor to (%@) across edge (%@).", depthMarker, String(describing: newNodeB.triangle), String(describing: newNeighbor?.triangle), String(describing: edge)))
            newNodeB.neighborA = newNeighbor

        }
        else if newNodeB.triangle.b == edge {
            log(String(format: "%@ Setting triangle's (%@) B neighbor to (%@) across edge (%@).", depthMarker, String(describing: newNodeB.triangle), String(describing: newNeighbor?.triangle), String(describing: edge)))
            newNodeB.neighborB = newNeighbor

        }
        else if newNodeB.triangle.c == edge {
            log(String(format: "%@ Setting triangle's (%@) C neighbor to (%@) across edge (%@).", depthMarker, String(describing: newNodeB.triangle), String(describing: newNeighbor?.triangle), String(describing: edge)))
            newNodeB.neighborC = newNeighbor

        }

        let neighborNode = newNodeA.triangle.edges().contains(edge) ? newNodeA : newNodeB
        if let neighborA = newNeighbor?.neighborA, neighborA.triangle == oldNode.triangle || neighborA.triangle == oldNeighbor.triangle {
            log(String(format: "%@ Setting neighboring triangle's (%@) A neighbor to (%@) across edge (%@).", depthMarker, String(describing: newNeighbor?.triangle), String(describing: neighborNode.triangle), String(describing: edge)))
            newNeighbor?.neighborA = neighborNode
        } else if let neighborB = newNeighbor?.neighborB, neighborB.triangle == oldNode.triangle || neighborB.triangle == oldNeighbor.triangle {
            log(String(format: "%@ Setting neighboring triangle's (%@) B neighbor to (%@) across edge (%@).", depthMarker, String(describing: newNeighbor?.triangle), String(describing: neighborNode.triangle), String(describing: edge)))
            newNeighbor?.neighborB = neighborNode
        } else {
            log(String(format: "%@ Setting neighboring triangle's (%@) C neighbor to (%@) across edge (%@).", depthMarker, String(describing: newNeighbor?.triangle), String(describing: neighborNode.triangle), String(describing: edge)))
            newNeighbor?.neighborC = neighborNode
        }
    }

}
