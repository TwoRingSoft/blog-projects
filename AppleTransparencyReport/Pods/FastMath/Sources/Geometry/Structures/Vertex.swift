//
//  Vertex.swift
//  Delaunay
//
//  Created by Andrew McKnight on 11/8/17.
//  Copyright © 2017 old dominion university. All rights reserved.
//

import CoreGraphics
import Foundation

let ghost1 = Vertex(x: -1, y: -1, name: "Ghost 1")
let ghost2 = Vertex(x: -2, y: -2, name: "Ghost 2")
let ghosts: Set<Vertex> = Set<Vertex>([ghost1, ghost2])

public class Vertex {

    public var x, y: Double
    
    /// Override value, if one was provided in `init(point:name:)` or `init(x:y:name:)`.
    /// - Seealso: `name`.
    private var _name: String?
    
    /// Used to generate a name for each instance created with `init(point:)` or `init(x:y:)` with no name override.
    /// - Seealso: `name`.
    private static var id: Int = 0
    
    /// Either the overriden value provided in `_name` if one exists, or the `String` representation of `id`.
    /// - Postcondition: `id` is incremented by 1 if `_name` is `nil`.
    /// - Seealso: `_name` and `id`.
    public lazy var name: String = {
        guard let nameOverride = _name else {
            let nextID = Vertex.id
            Vertex.id += 1
            let nextName = String(describing: nextID)
            self._name = nextName
            return nextName
        }
        return nameOverride
    }()

    public init(point: CGPoint, name: String? = nil) {
        self.x = Double(point.x)
        self.y = Double(point.y)
        self._name = name
    }

    init(x: Double, y: Double, name: String? = nil) {
        self.x = x
        self.y = y
        self._name = name
    }

}

extension Vertex: Hashable {

    public var hashValue: Int {
        return String(format: "Vertex: [%f %f]", x, y).hashValue
    }

}

public func ==(lhs: Vertex, rhs: Vertex) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

extension Vertex: CustomStringConvertible {

    public var description: String {
        return String(format: "Vertex “%@”: [%.1f %.1f]", name, x, y)
    }

}
