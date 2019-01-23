//
//  Exponent.swift
//  ProjectEuler
//
//  Created by Andrew McKnight on 1/11/16.
//  Copyright © 2016 AMProductions. All rights reserved.
//

import Foundation

infix operator **

// Integer case

func **<T>(base: T, power: T) -> T where T: BinaryInteger {
    return exponentiate(base, power)
}

func exponentiate<T>(_ base: T, _ power: T) -> T where T: BinaryInteger {
    var result = base
    var mutablePower = power
    while mutablePower > 1 {
        result *= base
        mutablePower -= 1 as T
    }
    return result
}

// Floating-point cases

/// applies to `Float` and `Float32`
func **(base: Float, power: Float) -> Float {
    return powf(base, power)
}

/// applies to `Double` and `Float64`
func **(base: Double, power: Double) -> Double {
    return pow(base, power)
}
