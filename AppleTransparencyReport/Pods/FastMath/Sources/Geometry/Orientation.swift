//
//  Orientation.swift
//  Delaunay
//
//  Created by Andrew McKnight on 11/9/17.
//  Copyright © 2017 old dominion university. All rights reserved.
//

import Foundation

public enum AngleOrientation {
    case clockwise
    case counterclockwise
}

enum PlanarOrientation {
    case clockwise
    case colinear
    case counterclockwise
}

enum IncircleOrientation {
    case outside
    case on
    case inside
}

func incircleOrientation(vertex: Vertex, triangle: Triangle) -> IncircleOrientation {
    // Shewchuck's robust incircle test
    exactinit()
    let _a = [ triangle.a.a.x, triangle.a.a.y ]
    let a = UnsafeMutablePointer<Double>(mutating: _a)

    let _b = [ triangle.a.b.x, triangle.a.b.y ]
    let b = UnsafeMutablePointer<Double>(mutating: _b)

    let _c = [ triangle.b.b.x, triangle.b.b.y ]
    let c = UnsafeMutablePointer<Double>(mutating: _c)

    let _d = [ vertex.x, vertex.y ]
    let d = UnsafeMutablePointer<Double>(mutating: _d)
    let result = incircle(a, b, c, d)

    if result > 0 { return .inside }
    else if result == 0 { return .on }
    else { return .outside }
}

func planarOrientation(a: Vertex, b: Vertex, c: Vertex) -> PlanarOrientation {
    exactinit()
    let _a = [ a.x, a.y ]
    let a = UnsafeMutablePointer<Double>(mutating: _a)

    let _b = [ b.x, b.y ]
    let b = UnsafeMutablePointer<Double>(mutating: _b)

    let _c = [ c.x, c.y ]
    let c = UnsafeMutablePointer<Double>(mutating: _c)

    let result = orient2d(a, b, c)

    if result > 0 { return .counterclockwise }
    else if result < 0 { return .clockwise }
    else { return .colinear }
}
