//
//  Quadrant.swift
//  FastMath
//
//  Created by Andrew McKnight on 9/11/18.
//

import Foundation

public enum Quadrant {
    case first
    case second
    case third
    case fourth
    
    public init(angle: Angle) {
        let cc = angle.counterclockwise.radians
        if cc <= .pi / 2 {
            self = .first
        } else if cc <= .pi {
            self = .second
        } else if cc <= 3 * .pi / 2 {
            self = .third
        } else {
            self = .fourth
        }
    }
    
    public func isPositiveX() -> Bool {
        return self == .first || self == .fourth
    }
    
    public func isPositiveY() -> Bool {
        return self == .first || self == .second
    }
}
