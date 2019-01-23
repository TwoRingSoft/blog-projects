//
//  Trigonometry.swift
//  FastMath
//
//  Created by Andrew McKnight on 9/11/18.
//

import Foundation

public enum TrigonometricRatio: Int {
    case arc
    case hypotenuse
    case chord
    
    case sine
    case cosine
    case tangent
    
    case sineOpposite
    case cosineOpposite
    
    case secant
    case cosecant
    case cotangent
    
    case versine
    case coversine
    
    case exsecant
    case excosecant
    
    public func shortName() -> String {
        switch self {
        case .arc: return "arc"
        case .hypotenuse: return "hyp"
        case .chord: return "crd"
        case .sine, .sineOpposite: return "sin"
        case .cosine, .cosineOpposite: return "cos"
        case .tangent: return "tan"
        case .secant: return "sec"
        case .cosecant: return "csc"
        case .cotangent: return "cot"
        case .versine: return "siv"
        case .coversine: return "cvs"
        case .exsecant: return "exsec"
        case .excosecant: return "excsc"
        }
    }
    
    public func longName() -> String {
        switch self {
        case .arc: return "Arc"
        case .hypotenuse: return "Hypotenuse"
        case .chord: return "Chord"
        case .sine: return "Sine"
        case .cosine: return "Cosine"
        case .sineOpposite: return "Opposite Sine"
        case .cosineOpposite: return "Opposite Cosine"
        case .tangent: return "Tangent"
        case .secant: return "Secant"
        case .cosecant: return "Cosecant"
        case .cotangent: return "Cotangent"
        case .versine: return "Versine"
        case .coversine: return "Coversine"
        case .exsecant: return "Exsecant"
        case .excosecant: return "Excosecant"
        }
    }
    
    public static func allRatios() -> [TrigonometricRatio] {
        return [
            arc, hypotenuse, chord, sine, sineOpposite, cosineOpposite, cosine, tangent, secant, cosecant, cotangent, versine, coversine, exsecant, excosecant
        ]
    }
}
