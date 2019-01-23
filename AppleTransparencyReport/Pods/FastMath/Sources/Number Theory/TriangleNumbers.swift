//
//  TriangleNumbers.swift
//  FastMath
//
//  Created by Andrew McKnight on 8/1/18.
//

import Foundation

public extension BinaryInteger {

    /// The `n`th triangular number is the sum of all numbers between `1` and `n` inclusive.
    ///
    /// - Returns: the `n`th triangular number, where `n` is the value of the caller.
    func triangularNumber<T>() -> T where T: BinaryInteger {
        return T(self) * ( T(self) + T(1) ) / T(2)
    }
    
}
