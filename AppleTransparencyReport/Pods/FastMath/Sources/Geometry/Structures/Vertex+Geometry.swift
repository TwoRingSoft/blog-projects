//
//  Vertex+Geometry.swift
//  FastMath
//
//  Created by Andrew McKnight on 9/11/18.
//

import Foundation

extension Vertex {
    
    /**
     `ghost2` > all points > `ghost1`
     */
    func lexicographicallyLargerThan(otherPoint: Vertex) -> Bool {
        if self == ghost2 { return true }
        if otherPoint == ghost1 { return true }
        
        let result = self.y != otherPoint.y ? self.y > otherPoint.y : self.x > otherPoint.x
        return result
    }
    
    func isIncident(onEdge edge: Edge) -> Bool {
        // impossible for vertices to fall on an edge containing a ghost point
        if edge.containsGhostPoint() {
            return false
        }
        
        return planarOrientation(a: edge.a, b: edge.b, c: self) == .colinear
    }
    
    /**
     - returns: `true` if point lies strictly to the left, `false` if point falls on edge or to the right
     */
    func liesToLeft(ofEdge edge: Edge) -> Bool {
        if self == ghost1 {
            return edge.a.lexicographicallyLargerThan(otherPoint: edge.b)
        }
        
        if self == ghost2 {
            return edge.b.lexicographicallyLargerThan(otherPoint: edge.a)
        }
        
        if edge.a == ghost1 && edge.b == ghost2 {
            log(String(format: "Edge (%@) is oriented so that all points lie to the right.", String(describing: edge)))
            return false
        }
        
        if (edge.a == ghost2 && edge.b == ghost1) {
            log(String(format: "Edge (%@) is oriented so that all points lie to the left.", String(describing: edge)))
            return true
        }
        
        if (edge.b == ghost1) {
            let liesLeft = self.lexicographicallyLargerThan(otherPoint: edge.a)
            log(String(format: "Edge's (%@) destination point is ghost1. Because the test point (%@) is lexicographically %@ than its source point, the test point %@ to the left of the edge.", String(describing: edge), String(describing: self), liesLeft ? "larger" : "smaller", liesLeft ? "lies" : "does not lie"))
            return liesLeft
        } else if (edge.a == ghost1) {
            let liesLeft = edge.b.lexicographicallyLargerThan(otherPoint: self)
            log(String(format: "Edge's (%@) source point is ghost1. Because its destination point is lexicographically %@ than the test point (%@), the test point %@ to the left of the edge.", String(describing: edge), liesLeft ? "larger" : "smaller", String(describing: self), liesLeft ? "lies" : "does not lie"))
            return liesLeft
        }
        
        if (edge.a == ghost2) {
            let liesLeft = self.lexicographicallyLargerThan(otherPoint: edge.b)
            log(String(format: "Edge's (%@) source point is ghost2. Because the test point (%@) is lexicographically %@ than its destination point, the test point %@ to the left of the edge.", String(describing: edge), String(describing: self), liesLeft ? "larger" : "smaller", liesLeft ? "lies" : "does not lie"))
            return liesLeft
        } else if(edge.b == ghost2) {
            let liesLeft = edge.a.lexicographicallyLargerThan(otherPoint: self)
            log(String(format: "Edge's (%@) destination point is ghost2. Because the source point is lexicographically %@ than the test point (%@), the test point %@ to the left of the edge.", String(describing: edge), liesLeft ? "larger" : "smaller", String(describing: self), liesLeft ? "lies" : "does not lie"))
            return liesLeft
        }
        
        let liesLeft = planarOrientation(a: edge.a, b: edge.b, c: self) == .counterclockwise
        
        log(String(format: "Point (%@) %@ to the left of the edge (%@).", String(describing: self), liesLeft ? "lies" : "does not lie", String(describing: edge)))
        return liesLeft
    }
    
}
