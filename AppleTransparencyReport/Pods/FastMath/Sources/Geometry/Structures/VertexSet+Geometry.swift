//
//  VertexSet+Geometry.swift
//  Delaunay
//
//  Created by Andrew McKnight on 11/19/17.
//  Copyright © 2017 old dominion university. All rights reserved.
//

import Foundation

extension Set where Element == Vertex {

    func centerPoint() -> Vertex {
        let nonghosts = Set(self.filter { !ghosts.contains($0) })
        let sortedX = nonghosts.sortedByX()
        let sortedY = nonghosts.sortedByY()
        let centerX = (sortedX.last!.x - sortedX.first!.x) / 2.0
        let centerY = (sortedY.last!.y - sortedY.first!.y) / 2.0
        return Vertex(x: centerX, y: centerY, name: "CenterPoint(\(String(describing: self))")
    }

    func convexHull() -> [Vertex]? {
        let nonghosts = Set(self.filter { !ghosts.contains($0) })
        if nonghosts.count < 3 { return nil }

        let sortedPoints = nonghosts.sortedByX()

        let minmin = 0
        let minXPoints = Set(sortedPoints.filter { $0.x == sortedPoints.first!.x })
        guard let minmax = sortedPoints.index(of: minXPoints.sortedByY().last!) else { return nil }
        let maxXs = sortedPoints.filter { $0.x == sortedPoints.last!.x }
        guard let maxmin = sortedPoints.index(of: maxXs.first!) else { return nil }
        guard let maxmax = sortedPoints.index(of: maxXs.last!) else { return nil }

        var hullPoints = [Vertex]()
        hullPoints.append(sortedPoints[minmin])
        for i in (minmax + 1) ..< maxmin {
            let edge = Edge(x: sortedPoints[minmin], y: sortedPoints[maxmin], name: "Lower Edge \(i)")
            let vertex = sortedPoints[i]
            if vertex.liesToLeft(ofEdge:edge) || vertex.isIncident(onEdge: edge) {
                continue
            }

            while hullPoints.count > 1 {
                let a = hullPoints[hullPoints.count - 1]
                let b = hullPoints[hullPoints.count - 2]
                if vertex.liesToLeft(ofEdge:Edge(x: b, y: a, name: "Rectifying Lower Edge \(i)")) {
                    break
                }
                hullPoints.removeLast()
            }

            hullPoints.append(vertex)
        }

        hullPoints.append(sortedPoints[maxmin])
        let lowerHullCount = hullPoints.count

        if maxmax != maxmin {
            hullPoints.append(sortedPoints[maxmax])
        }

        for i in ((minmax + 1) ... maxmin).reversed() {
            let edge = Edge(x: sortedPoints[maxmax], y: sortedPoints[minmax], name: "Upper Edge \(i)")
            let vertex = sortedPoints[i]
            if vertex.liesToLeft(ofEdge:edge) || vertex.isIncident(onEdge: edge) {
                continue
            }

            while hullPoints.count - lowerHullCount > 1 {
                let a = hullPoints[hullPoints.count - 1]
                let b = hullPoints[hullPoints.count - 2]
                if vertex.liesToLeft(ofEdge:Edge(x: b, y: a, name: "Rectifying Upper Edge \(i)")) {
                    break
                }
                hullPoints.removeLast()
            }

            hullPoints.append(vertex)
        }

        if minmax != minmin {
            hullPoints.append(sortedPoints[minmin])
        }

        return hullPoints
    }

}
