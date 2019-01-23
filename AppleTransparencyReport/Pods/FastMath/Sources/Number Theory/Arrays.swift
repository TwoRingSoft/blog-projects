//
//  Arrays.swift
//  ProjectEuler
//
//  Created by Andrew McKnight on 5/20/17.
//  Copyright © 2017 AMProductions. All rights reserved.
//

import Foundation

public extension Array {
    func shuffled(minShuffles: Int = 50, maxShuffles: Int = 250) -> Array {
        var result = Array(self)
        let shuffles = (Int(arc4random()) % (maxShuffles + 1)) + minShuffles
        for _ in 0 ..< shuffles {
            let a = Int(arc4random()) % count
            var b: Int
            repeat {
                b = Int(arc4random()) % count
            } while b == a
            result.swapAt(a, b)
        }
        return result
    }
}

public extension Set where Element: Comparable {

    func combinationsRecursive<T>(combinationSize: Int) -> Set<Set<T>> where T: Comparable, T: Hashable {
        if combinationSize == 0 {
            let emptySet: Set<Set<T>> = [[]]
            return emptySet
        }

        if combinationSize == 1 {
            var setOfSets = Set<Set<T>>()
            self.forEach {
                let nextSet: Set<T> = [$0 as! T]
                setOfSets.insert(nextSet)
            }
            return setOfSets
        }

        if combinationSize == self.count {
            var set: Set<Set<T>> = []
            set.insert(self as! Set<T>)
            return set
        }

        if combinationSize > self.count {
            let nullSet: Set<Set<T>> = []
            return nullSet
        }

        var combos = Set<Set<T>>()

        let indices = Array(0..<self.count)
        let selectedIndices = indices[0..<combinationSize]
        for i in stride(from: combinationSize - 1, through: 0, by: -1) {
            let a = i
            while a < self.count - combinationSize - i {
                var set: Set<T> = Set() as! Set<T>
                for index in selectedIndices {
                    set.insert(index as! T)
                }
                combos.insert(set)
            }
        }

        return combos
    }

}
