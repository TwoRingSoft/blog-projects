//
//  RomanNumerals.swift
//  ProjectEuler
//
//  Created by Andrew McKnight on 1/11/16.
//  Copyright © 2016 AMProductions. All rights reserved.
//

import Foundation

extension Int {

    func romanNumeral() -> String {

        var n = self

        if n == 0 { return "" }

        var characters = [String]()

        // TODO: overbars and thousands the same as the logic below

        for _ in 0 ..< n/1000 {
            characters.append("M")
        }
        n %= 1000

        let indices = [ 9, 5, 4 ]
        let places = [ 100, 10, 1 ]
        let placeNumerals = [ "C", "X", "I" ]

        let specialCases = [
            [ "CM", "D", "CD" ],
            [ "XC", "L", "XL" ],
            [ "IX", "V", "IV" ]
        ]

        for place in places {
            for index in indices {
                let value = place * index
                if n >= value {
                    characters.append(specialCases[places.index(of: place)!][indices.index(of: index)!])
                    n -= value
                    break
                }
            }
            for _ in 0 ..< n/place {
                characters.append(placeNumerals[places.index(of: place)!])
            }
            n %= place
        }

        return characters.joined(separator: "")

    }

    init?(romanNumeral:String) {

        let characters = Array(romanNumeral.uppercased())

        self = 0

        var position = 0
        while position < characters.count {

            let currentCharacter = characters[position]
            var nextCharacter: Character?
            if position + 1 < characters.count {
                nextCharacter = characters[position + 1]
            }

            if currentCharacter == "M" {
                self += 1000
            } else if currentCharacter == "D" {
                self += 500
            } else if currentCharacter == "C" {
                if nextCharacter != nil && nextCharacter == "M" {
                    self += 900
                    position += 1
                } else if nextCharacter != nil && nextCharacter == "D" {
                    self += 400
                    position += 1
                } else {
                    self += 100
                }
            } else if currentCharacter == "L" {
                self += 50
            } else if currentCharacter == "X" {
                if nextCharacter != nil && nextCharacter == "C" {
                    self += 90
                    position += 1
                } else if nextCharacter != nil && nextCharacter == "L" {
                    self += 40
                    position += 1
                } else {
                    self += 10
                }
            } else if currentCharacter == "V" {
                self += 5
            } else if currentCharacter == "I" {
                if nextCharacter != nil && nextCharacter == "X" {
                    self += 9
                    position += 1
                } else if nextCharacter != nil && nextCharacter == "V" {
                    self += 4
                    position += 1
                } else {
                    self += 1
                }
            }

            position += 1

        }

    }
    
}
