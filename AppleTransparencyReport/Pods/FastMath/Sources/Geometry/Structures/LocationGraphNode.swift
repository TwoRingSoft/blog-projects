//
//  LocationGraphNode.swift
//  Delaunay
//
//  Created by Andrew McKnight on 11/8/17.
//  Copyright © 2017 old dominion university. All rights reserved.
//

import Foundation

public class LocationGraphNode: NSObject {

    public var triangle: Triangle
    public var parents: [LocationGraphNode]
    public var children: [LocationGraphNode] = []
    var visited: Bool = false
    public var color: Int?
    public var neighborA, neighborB, neighborC: LocationGraphNode?

    init(triangle: Triangle, parents: [LocationGraphNode] = []) {
        self.triangle = triangle
        self.parents = parents
    }

}

// MARK: Public
public extension LocationGraphNode {
    override var description: String {
        return toString(depth: 0)
    }
    
    /// - Returns: An array with all the `Triangle`s' `LocationGraphNode`s adjacent on an edge in this node's triangle.
    func neighbors() -> [LocationGraphNode] {
        var neighbors = [LocationGraphNode]()
        if let a = neighborA { neighbors.append(a) }
        if let b = neighborB { neighbors.append(b) }
        if let c = neighborC { neighbors.append(c) }
        return neighbors
    }
    
    /// - Returns: Set of `Triangle`s in the Delaunay triangulation contained within the current node.
    func getTriangles() -> Set<Triangle> {
        return Set<Triangle>(getLeafNodes().map { $0.triangle })
    }
    
    /// - Returns: `LocationGraphNode` instances containing the triangles with edges defining the triangulation within the node's area.
    func getLeafNodes() -> Set<LocationGraphNode> {
        let allTriangles = LocationGraphNode.collectLeafNodes(startingNode: self)
        LocationGraphNode.resetVisitedStates(node: self)
        return Set<LocationGraphNode>(allTriangles.filter({ !$0.triangle.hasGhostPoint() }))
    }
    
    /// Walk through the current leaf nodes and assign a color to each triangle so that no two triangles adjacent on a common edge have the same color.
    func fourColor() {
        let leafNodes = getLeafNodes()
        LocationGraphNode.resetVisitedStates(node: self)
        leafNodes.forEach {
            LocationGraphNode.color(node: $0)
        }
        LocationGraphNode.resetVisitedStates(node: self)
    }

    
    /// Search for the deepest node whose `Triangle` contains a point. Recursively called on root and subsequently on child nodes
    ///
    /// - Warning: Recursive.
    /// - Parameter point: The point being inserted into the triangulation, for which we must find a containing `Triangle`.
    /// - Returns: The `LocationGraphNode` whose `Triangle` contains the specified point, or `nil` if there aren't yet any `Triangle`s in the triangulation, or if the point lies outside the current `Triangle`'s area.
    func findNode(containingPoint point: Vertex) -> LocationGraphNode? {
        return findNode(containingPoint: point, currentTriangle: self)
    }
    
    /// Search for the deepest node whose `Triangle` contains the specified edge across which it neighbors a particular triangle.
    ///
    /// - Warning: Recusive.
    /// - Parameters:
    ///   - edge: The edge across which we'd like to find a neighboring `Triangle`'.
    ///   - triangle: The `Triangle` for whom we'd like to find a neighbor.
    /// - Returns: The `LocationGraphNode` containing the neighbor `Triangle`, if one exists.
    func findTriangle(incidentOnEdge edge: Edge, adjacentToTriangle triangle: LocationGraphNode) -> LocationGraphNode? {
        log(String(format: "Searching for leaf triangle adjacent to triangle %@ across edge %@.", String(describing: triangle.triangle), String(describing: edge)))
        var siblings = [LocationGraphNode]()
        triangle.parents.forEach { parent in
            siblings.append(contentsOf: parent.children)
        }
        
        if let originalTriangleIndex = siblings.index(of: triangle) {
            siblings.remove(at: originalTriangleIndex)
        }
        
        for sibling in siblings {
            if edge == sibling.triangle.a || edge == sibling.triangle.b || edge == sibling.triangle.c {
                log(String(format: "Edge %@ is part of sibling triangle: %@; recurse into its children", String(describing: edge), String(describing: sibling.triangle)))
                return findSubtriangle(incidentOnEdge: edge, adjacentToTriangle:sibling)
            }
        }
        
        /*
         If we're here, then none of the sibling nodes in the tree reference a
         triangle that is incident on the provided edge. This is because the
         input edge is a new one created by an edge flip, so we need to ascend
         to the grandparent of the input triangle to find the newly created ones
         incident on it.
         */
        let grandParents = triangle.parents.reduce(into: [LocationGraphNode](), { (grandparents, parent) in
            grandparents.append(contentsOf: parent.parents)
        })
        let parentSiblings = grandParents.reduce(into: [LocationGraphNode](), { (siblings, grandparent) in
            siblings.append(contentsOf: grandparent.children)
        }).filter { (parentSibling) -> Bool in
            return !triangle.parents.contains(where: { (node) -> Bool in
                parentSibling == node
            })
        }
        
        guard let match = parentSiblings.filter({ (parentSibling)  -> Bool in
            return edge == parentSibling.triangle.a || edge == parentSibling.triangle.b || edge == parentSibling.triangle.c
        }).first else {
            log(String(format: "No parent siblings adjacent to triangle %@ on edge %@.", String(describing: triangle.triangle), String(describing: edge)))
            return nil
        }
        
        log(String(format: "Edge %@ is part of parent's sibling triangle: %@.", String(describing: edge), String(describing: match.triangle)))
        
        return match
    }

}

// MARK: Private
private extension LocationGraphNode {

    static func collectLeafNodes(startingNode: LocationGraphNode) -> Set<LocationGraphNode> {
        if startingNode.children.count == 0 {
            return Set<LocationGraphNode>([ startingNode ])
        }

        var result = Set<LocationGraphNode>()
        startingNode.children.forEach { child in
            if !child.visited {
                child.visited = true
                result.formUnion(collectLeafNodes(startingNode: child))
            }
        }

        return result
    }
    
    static func resetVisitedStates(node: LocationGraphNode) {
        node.children.forEach { child in
            child.visited = false
            resetVisitedStates(node: child)
        }
    }
    
    static func color(node: LocationGraphNode) {
        guard !node.visited else { return }
        node.visited = true
        
        func neighborColors(node: LocationGraphNode) -> [Int] {
            var colors = [Int]()
            if let a = node.neighborA?.color { colors.append(a) }
            if let b = node.neighborB?.color { colors.append(b) }
            if let c = node.neighborC?.color { colors.append(c) }
            return colors
        }
        
        func availableColor(forNode node: LocationGraphNode) -> Int {
            var usedColors = neighborColors(node: node)
            if let color = node.color {
                usedColors.append(color)
            }
            let availableColors = Array<Int>(Set<Int>([0, 1, 2, 3]).subtracting(usedColors))
            return availableColors[Int(arc4random()) % availableColors.count]
        }
        
        if nil == node.color {
            let color = availableColor(forNode: node)
            log(String(format: "Setting triangle %@ color to %i", String(describing: node.triangle), color))
            node.color = color
        }
        
        if let neighborA = node.neighborA, !neighborA.visited, !neighborA.triangle.hasGhostPoint() {
            self.color(node: neighborA)
        }
        if let neighborB = node.neighborB, !neighborB.visited, !neighborB.triangle.hasGhostPoint() {
            self.color(node: neighborB)
        }
        if let neighborC = node.neighborC, !neighborC.visited, !neighborC.triangle.hasGhostPoint() {
            self.color(node: neighborC)
        }
    }
    
    func toString(depth: Int) -> String {
        let padding = String(repeating: "\t", count: depth)
        var childrenString = children.map { $0.toString(depth: depth + 1) }.joined(separator: "\n")
        if childrenString.count > 0 {
            childrenString = "\n" + childrenString
        }
        return String(format: "%@tri: %@%@", padding, String(describing: triangle), childrenString)
    }

    // find the deepest child sharing the edge
    func findSubtriangle(incidentOnEdge edge: Edge, adjacentToTriangle triangle: LocationGraphNode, callDepth: Int = 0) -> LocationGraphNode? {
        // leaf node, recursion termination
        if triangle.children.count == 0 {
            log(String(format: "%@ Triangle %@ is a leaf node, so it is the adjacent triangle across edge %@.", String(repeating: "*", count: callDepth + 1), String(describing: triangle), String(describing: edge)))
            return triangle
        }

        for child in triangle.children {
            if edge == triangle.triangle.a || edge == triangle.triangle.b || edge == triangle.triangle.c {
                log(String(format: "%@ Child triangle %@ shares edge %@; recursing children.", String(repeating: "*", count: callDepth + 1), String(describing: child), String(describing: edge)))
                return findSubtriangle(incidentOnEdge:edge, adjacentToTriangle:child, callDepth: callDepth + 1)
            }
        }

        log(String(format: "%@ No triangle shares edge %@.", String(repeating: "*", count: callDepth + 1), String(describing: edge)))
        return nil
    }

    func findNode(containingPoint point: Vertex, currentTriangle: LocationGraphNode, callDepth: Int = 0) -> LocationGraphNode? {
        log(String(format: "%@ Testing if point (%@) lies inside triangle (%@).", String(repeating: "*", count: callDepth + 1), String(describing: point), String(describing: currentTriangle.triangle)))

        // leaf node, recursion termination
        if currentTriangle.children.count == 0 {
            log(String(format: "%@ Triangle has 0 children, returning itself.", String(repeating: "*", count: callDepth + 1)))
            return currentTriangle
        }

        log(String(format: "%@ Triangle has children, iterating through them.", String(repeating: "*", count: callDepth + 1)))
        
        for child in currentTriangle.children {
            log(String(format: "%@ Testing if point (%@) lies inside child triangle (%@).", String(repeating: "*", count: callDepth + 1), String(describing: point), String(describing: child.triangle)))
            if child.triangle.contains(vertex: point) {
                log(String(format: "%@ Point (%@) lies inside triangle (%@), recursing into its children.", String(repeating: "*", count: callDepth + 1), String(describing: point), String(describing: child.triangle)))
                return findNode(containingPoint:point, currentTriangle:child, callDepth: callDepth + 1)
            } else {
                log(String(format: "%@ Point (%@) lies outside triangle (%@).", String(repeating: "*", count: callDepth + 1), String(describing: point), String(describing: child.triangle)))
            }
        }

        return nil
    }

}
