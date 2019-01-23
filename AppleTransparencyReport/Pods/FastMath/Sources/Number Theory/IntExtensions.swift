//
//  IntExtensions.swift
//  ProjectEuler
//
//  Created by Andrew McKnight on 1/11/16.
//  Copyright © 2016 AMProductions. All rights reserved.
//

import Foundation

public extension Int {

    /// Return sorted array of integer divisors in `[1,n]`.
    func divisors() -> Set<Int> {
        let end = Int(sqrt(Double(self)))
        let range = Set((1 ..< end + 1))
        let zeroMods = range.filter({self % $0 == 0})
        var quotients:[Int] = zeroMods.map({self / $0}) + zeroMods
        quotients.sort()
        return Set<Int>(quotients)
    }

    /// Return sorted array of integer divisors in `[1,n)`
    func properDivisors() -> Set<Int> {
        return Set<Int>(self.divisors().filter({$0 != self}))
    }

    /// Return sorted array of prime integer divisors in `[1,n)`
    func primeFactors() -> Set<Int> {
        return Set<Int>(self.properDivisors().filter({$0.isPrime()}))
    }

    func isPrime() -> Bool {
        return self.divisors().count == 2
    }
    
    /// - Returns: all primes lesser than caller's numeric value
    func primesUnder() -> Set<Int> {
        var allNumbers = Array<Bool>(repeating: true, count: self)
        for prime in 2..<self {
            if allNumbers[prime] {
                var composite = prime * prime
                while composite < self {
                    allNumbers[composite] = false
                    composite += prime
                }
            }
        }
        var primes = Set<Int>()
        for prime in 2..<self {
            if allNumbers[prime] {
                primes.insert(prime)
            }
        }
        return primes
    }

    func totient() -> Int {
        let factors = self.primeFactors()
        let denominator = factors.reduce(1, {$0 * $1})
        return self * factors.reduce(1, {$0 * ($1 - 1) / denominator})
    }

    /// Returns `i` such that `i! <= self < (i + 1)!`
    func factorialRoot() -> Int {
        if self == 0 { return 1 }

        var i = 1
        while i > self {
            i *= i + 1
        }
        
        return i
    }
    
}
