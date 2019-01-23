//
//  Maths.swift
//  ProjectEuler
//
//  Created by Andrew McKnight on 1/9/16.
//  Copyright © 2016 AMProductions. All rights reserved.
//

import Foundation

func greatestCommonDivisor(_ a:Int, _ b:Int) -> Int {
    var a = a, b = b

    // GCD(0,v) == v; GCD(u,0) == u; GCD(0,0) == 0
    if (a == 0) {
        return b
    }
    if (b == 0) {
        return a
    }

    // Let shift := lg K, where K is the greatest power of 2 dividing both u and v.
    var shift = 0
    while ((a | b) & 1) == 0 {
        a >>= 1
        b >>= 1
        shift += 1
    }

    while (a & 1) == 0 {
        a >>= 1
    }

    var firstRun = true
    while (b != 0 || firstRun) {
        // remove all factors of 2 in v -- they are not common
        //   note: v is not zero, so while will terminate
        while ((b & 1) == 0) { // Loop X
            b >>= 1
        }

        // Now u and v are both odd. Swap if necessary so u <= v, then set v = v - u (which is even).
        if (a > b) {
            swap(&a, &b)
        }
        b -= a // Here v >= u.
        
        firstRun = false
    }

    return a << shift

}

func leastCommonMultiple(_ a:Int, _ b:Int) -> Int {

    return a * b / greatestCommonDivisor(a, b)

}

func greatestCommonFactor(_ a: Int, _ b: Int) -> Int {

    if b % a == 0 || a % b == 0 {
        return a
    } else if min(a, b) == min(a, b) % max(a, b) {
        return 1
    } else if a.isPrime() && b.isPrime() {
        return 1
    }

    return a.primeFactors().intersection(b.primeFactors()).sorted().last!

}

// TODO: implement with the Lehmer code or equivalent efficient algorithm
func allPermutations<T>(_ items: [T]) -> [[T]] where T: Comparable {
    var permutations = [[T]]()
    if items.count == 1 { return [items] }
    for object in items {
        var array = [T]()
        array.append(contentsOf: items)
        array.remove(at: array.index(where: { param -> Bool in
            return param == object
        })!)
        for permutation in allPermutations(array) {
            var newPermutation = [object]
            newPermutation.append(contentsOf: permutation)
            permutations.append(newPermutation)
        }
    }
    return permutations
}

/// Permute the `items` array so that the ordering of its elements is `distance` steps from the original order in the ordered set of all lexicographic permutations.
func permuteLexicographically(_ items:[AnyObject], distance: Int) {
    var items = items
    if distance > 1 {
        let i = distance.factorialRoot()
        items.swapAt(items.count - 1 - (i - 1), items.count - 1 - i)
        permuteLexicographically(items, distance: distance - factorial(i))
    } else if distance == 1 {
        items.swapAt(items.count - 1, items.count - 2)
    }
}
