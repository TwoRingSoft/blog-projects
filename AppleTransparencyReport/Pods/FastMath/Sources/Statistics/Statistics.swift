//
//  Statistics.swift
//  ProjectEuler
//
//  Created by Andrew McKnight on 1/12/16.
//  Copyright © 2016 AMProductions. All rights reserved.
//

import Foundation

/// return number of combinations possible from combining r objects from a domain of d objects
func combinations(_ d: Int, _ r: Int) -> Int {

    if d < r { return 0 }
    if d == r { return 1 }
    return d*! / ( r*! * (d - r)*! )

}

func permutations(_ n: Int, _ l: Int, withReplacement: Bool) -> Int {

    if withReplacement { return n**l }
    if l > n { return 0 }
    return n*! / (n - l)*!

}

/**
 Compute the hypergeometric distribution for p out of q objects from n objects of
	one of two dichotomous types, where m is the total amount of objects.

 Example:
 in a pond with 50 (`m`) fish, 10 (`n`) are tagged. if a fisherman catches 7 (`q`) random fish
 without replacement, and X is the number of tagged fish caught, the probability that
 2 (`p`) fish are tagged is given by the expression

 ```

                  / 10 \   / 40 \
                 |      | |      |
                  \ 2  /   \  5 /    (45)(658,008)   246,753
 P( X = 2 )  =   --------------- =   ------------- = ------- ~ 0.2964
                      / 50 \           99,884,400    832,370
                     |      |
                      \  7 /

 ```

 The analogous function call for this example would be `hypergeometricDistribution(2, 7, 10, 50)`
 */
func hypergeometricDistribution(p: Int, q: Int, n: Int, m: Int) -> Double {

    return Double(combinations(n, p) * combinations((m - n), (q - p))) / Double(combinations(m, q))

}

func variance(n: Int, p: Int, q: Int) -> Double {
    return Double(n) * ( Double(p) / Double(p + q) ) * ( Double(q) / Double(p + q) ) * ( Double(q + p) - Double(n) ) / ( Double(q + p) - 1.0 )
}

func standardDeviation(n: Int, p: Int, q: Int) -> Double {
    return sqrt(variance(n: n, p: p, q: q))
}

func mean(n: Int, p: Int, q: Int) -> Double {
    return Double(n) * ( Double(p) / Double(p + q) )
}

public extension Collection where Iterator.Element == Float {
    func mean() -> Float {
        guard count > 0 else { return 0 }
        return sum() / Float(count)
    }
    
    func variance() -> Float {
        let mean = self.mean()
        return map({ (next) -> Float in
            return pow(next - mean, 2)
        }).mean()
    }
    
    func standardDeviation() -> Float {
        return sqrt(variance())
    }
    
    func zScores() -> [Float] {
        let standardDeviation = self.standardDeviation()
        guard standardDeviation != 0 else { return Array(repeating: 0, count: count) }
        
        let mean = self.mean()
        return map({ (next) -> Float in
            return (next - mean) / standardDeviation
        })
    }
    
    func histogram(buckets: [Range<Float>]) -> HistogramCount {
        guard count > 0 else { return [:] }
        return buckets.reduce(into: HistogramCount(), { (result, bucket) in
            result[String(describing: bucket)] = filter({ (value) -> Bool in
                return bucket.contains(value)
            }).count
        })
    }
    
    func normalDistribution() -> HistogramCount {
        guard count > 0 else { return [:] }
        let zScores = self.zScores()
        let maxZ = ceil(zScores.max()!)
        let minZ = floor(zScores.min()!)
        let maxDistanceFromMean = Swift.max(abs(maxZ), abs(minZ))
        let buckets = stride(from: -maxDistanceFromMean, through: maxDistanceFromMean, by: 1).map({ (bucket) -> Range<Float> in
            return Range(uncheckedBounds: (lower: bucket, upper: bucket + 1))
        })
        return zScores.histogram(buckets: buckets)
    }
}

public extension Collection where Iterator.Element == Double {
    func mean() -> Double {
        guard count > 0 else { return 0 }
        return sum() / Double(count)
    }
    
    func variance() -> Double {
        let mean = self.mean()
        return map({ (next) -> Double in
            return pow(next - mean, 2)
        }).mean()
    }
    
    func standardDeviation() -> Double {
        return sqrt(variance())
    }
    
    func zScores() -> [Double] {
        let standardDeviation = self.standardDeviation()
        guard standardDeviation != 0 else { return Array(repeating: 0, count: count) }
        
        let mean = self.mean()
        return map({ (next) -> Double in
            return (next - mean) / standardDeviation
        })
    }
    
    func histogram(buckets: [Range<Double>]) -> HistogramCount {
        guard count > 0 else { return [:] }
        return buckets.reduce(into: HistogramCount(), { (result, bucket) in
            result[String(describing: bucket)] = filter({ (value) -> Bool in
                return bucket.contains(value)
            }).count
        })
    }
    
    func normalDistribution() -> HistogramCount {
        guard count > 0 else { return [:] }
        let zScores = self.zScores()
        let maxZ = ceil(zScores.max()!)
        let minZ = floor(zScores.min()!)
        let maxDistanceFromMean = Swift.max(abs(maxZ), abs(minZ))
        let buckets = stride(from: -maxDistanceFromMean, through: maxDistanceFromMean, by: 1).map({ (bucket) -> Range<Double> in
            return Range(uncheckedBounds: (lower: bucket, upper: bucket + 1))
        })
        return zScores.histogram(buckets: buckets)
    }
}

public extension Collection where Iterator.Element == Int {
    func mean() -> Double {
        guard count > 0 else { return 0 }
        return Double(sum()) / Double(count)
    }
    
    func variance() -> Double {
        let mean = self.mean()
        let squaredDifferences = map({ (next) -> Double in
            return pow(Double(next) - mean, 2)
        })
        let variance = squaredDifferences.mean()
        return variance
    }
    
    func standardDeviation() -> Double {
        return sqrt(variance())
    }
    
    func zScores() -> [Double] {
        let standardDeviation = self.standardDeviation()
        guard standardDeviation != 0 else { return Array(repeating: 0, count: count) }

        let mean = self.mean()
        return map({ (next) -> Double in
            return (Double(next) - mean) / standardDeviation
        })
    }
    
    func histogram(buckets: [Range<Int>]) -> HistogramCount {
        guard count > 0 else { return [:] }
        return buckets.reduce(into: HistogramCount(), { (result, bucket) in
            result[String(describing: bucket)] = filter({ (value) -> Bool in
                return bucket.contains(value)
            }).count
        })
    }
    
    func normalDistribution() -> HistogramCount {
        guard count > 0 else { return [:] }
        let zScores = self.zScores()
        let maxZ = ceil(zScores.max()!)
        let minZ = floor(zScores.min()!)
        let maxDistanceFromMean = Swift.max(abs(maxZ), abs(minZ))
        let buckets = stride(from: -maxDistanceFromMean, through: maxDistanceFromMean, by: 1).map({ (bucket) -> Range<Double> in
            return Range(uncheckedBounds: (lower: bucket, upper: bucket + 1))
        })
        return zScores.histogram(buckets: buckets)
    }
}

/// Map of bucket names to frequencies
public typealias HistogramCount = [String: Int]

/// Map of bucket names to tuples of frequencies and the set of tags that are included
public typealias TagValueMap = [String: Double]
public typealias TaggedCount = (count: Int, tags: Set<String>)
public typealias TaggedHistogramCount = [Double: TaggedCount]

public extension Dictionary where Key == String, Value == Double {
    func zScores() -> TagValueMap {
        let values = self.map({$0.value})
        let mean = values.mean()
        let standardDeviation = values.standardDeviation()
        return reduce(into: [String: Double](), { (result, next) in
            let (key, value) = next
            result[key] = (value - mean) / standardDeviation
        })
    }
    
    func histogram(buckets: [Range<Double>]) -> TaggedHistogramCount {
        return buckets.reduce(into: TaggedHistogramCount(), { (result, bucket) in
            let items = filter({ (next) -> Bool in
                return bucket.contains(next.value)
            })
            result[bucket.upperBound] = (items.count, Set(items.keys))
        })
    }
    
    func normalDistribution() -> TaggedHistogramCount {
        let zScores = self.zScores()
        let maxZ = ceil(zScores.values.max()!)
        let minZ = floor(zScores.values.min()!)
        let maxDistanceFromMean = Swift.max(abs(maxZ), abs(minZ))
        let buckets = stride(from: -maxDistanceFromMean, through: maxDistanceFromMean, by: 1).map({ (bucket) -> Range<Double> in
            return Range(uncheckedBounds: (lower: bucket, upper: bucket + 1))
        })
        return zScores.histogram(buckets: buckets)
    }
}
