//
//  Distance.swift
//  FastMath
//
//  Created by Andrew McKnight on 9/11/18.
//

import CoreGraphics
import Foundation

public extension CartesianCoordinate2D {
    func distance(to coordinate: CartesianCoordinate2D) -> Double {
        return sqrt(pow(x - coordinate.x, 2) + pow(y - coordinate.y, 2))
    }
}

public extension CGPoint {
    func distance(to coordinate: CGPoint) -> Double {
        return sqrt(pow(Double(x - coordinate.x), 2) + pow(Double(y - coordinate.y), 2))
    }
}
