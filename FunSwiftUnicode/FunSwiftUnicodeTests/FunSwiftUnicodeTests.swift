//
//  FunSwiftUnicodeTests.swift
//  FunSwiftUnicodeTests
//
//  Created by Andrew McKnight on 1/28/19.
//  Copyright © 2019 Two Ring Software. All rights reserved.
//

import XCTest

class FunSwiftUnicodeTests: XCTestCase {
    func testUnicode() {
        ////////////////
        // Lookalikes //
        ////////////////
        
        //
        // ligatures
        //
        
        // ligatured ff U+FB00 ﬀ
        let vpnTrafficPort = 1
        let vpnTraﬀicPort = 2
        
        // ligatured fi U+FB01 ﬁ
        let vpnTrafﬁcPort = 3
        
        // ligatured ffi U+FB03 ﬃ
        let vpnTraﬃcPort = 4
        
        // quick, what values does `ports` contain?
        let ports = [vpnTraﬀicPort, vpnTraﬃcPort, vpnTrafficPort, vpnTrafﬁcPort]
        
        //
        // characters
        //
        
        // given lhs is, in fact, < rhs...
        let zero = 0
        let one = 1
        
        // small less-than sign U+FE64 ﹤
        let zero﹤one = true
        if (zero﹤one) {
            print("Look ma!")
        }
        
        // fullwidth less-than sign U+FF1C ＜
        let zero＜one = false
        if (zero＜one) {
            print("No hands?")
        }
        
        // quick, what values does `results` contain?
        let results = [zero＜one, zero<one, zero﹤one]
        
        //
        // Roman numerals U+2160...U+217F
        // Ⅰ, Ⅱ, Ⅲ, Ⅳ, Ⅴ, Ⅵ, Ⅶ, Ⅷ, Ⅸ, Ⅹ, Ⅺ, Ⅻ, Ⅼ, Ⅽ, Ⅾ, Ⅿ,
        // ⅰ, ⅱ, ⅲ, ⅳ, ⅴ, ⅵ, ⅶ, ⅷ, ⅸ, ⅹ, ⅺ, ⅻ, ⅼ, ⅽ, ⅾ, ⅿ
        //
        
        let coreData = 1
        let ⅽoreData = 2
        let coreⅮata = 3
        let ⅽoreⅮata = 4
        
        // what are the values in `allTheData`?
        let allTheData = [coreⅮata, ⅽoreⅮata, ⅽoreData, coreData]
        
        // as if I's, 1's and l's aren't bad enough...
        // the value is the amount of unicode characters in the name...
        // can you guess which characters they are for each?
        let Il1ll1I1I11l = 0
        let Il1ll1Ⅰ1I11ⅼ = 2
        let Ⅰl1ll1I1I11l = 1
        let Ⅰl1ll1Ⅰ1Ⅰ11l = 3
        
        //
        // Greek U+0370...U+03FF (many omitted that resemble no english letter)
        // Α, Β, Ε, Ζ, Η, Ι, Κ, Μ, Ν, Ο, Ρ, Τ, Υ, Χ, ν, ο
        //
        
        // same game, new name
        let SPANIKOPITA = 0
        let SPΑNIKOPITA = 1
        let SPANIKOPITΑ = 1
        let SPΑNIΚΟPITA = 3
        let SPANIKΟΡITA = 2
        let SPANIKOΡITA = 1
        let SPΑNIKOPITΑ = 2
        let SPANΙKOΡITΑ = 3
        let SPANIKΟPITA = 1
        
        //
        // full-width characters U+FF10...U+FFE5
        //
        
        // mimicking an if statement
        func iｆｃond(_: () -> ()) {}
        func cond() -> Bool { return true }
        iｆｃond() {}
        if cond() {}
        
        // mimicking an empty catch block
        func catch｛｝() {
            print("I'm in ur codez.")
        }
        // ...
        do {
            // `try` some stuff? better not `throw`...
        }; let error = catch｛｝
        // ...
        error()
        
        //
        // greek question mark U+037E ;
        //
        
        func innocent() { print("What,") }
        func function() { print("me worry?") }
        func innocent（）;function() { print("💣") }
        innocent () ;function()
        innocent（）;function()
        
        //////////////
        // Noseeums //
        //////////////
        
        // zero width non-joiner U+200C ‌
        // NOTE: bug in Xcode's source editor. Previously, I pasted the character onto the end of the comment, like the one right above this. Try arrowing past the end of the comment–it goes to the beginning of the line before continuing to the next one below! I fixed this by pasting all the invisible characters between arrows like so (nothing in between these!) -><-
        
        // Note: zero width joiner U+200D ->‍<- breaks FiraCode ligature of the arrow on the left
        
        // normal spelling
        let spacedOut = 0
        
        // zero width joiner U+200D ->‍<-
        let spaced‍Out = 1
        
        // zero width non-joiner U+200C ->‌<-
        let spaced‌Out = 2
        
        // zero width space u+200B ->​<-
        let spaced​Out = 3
        
        // you know the drill by now...
        let values = [spacedOut, spaced‍Out, spaced‌Out, spaced​Out]
        
        ///////////
        // Emoji //
        ///////////
        
        // let's make our country variables emoji!
        let 🇦🇩 = "Andorra"
        let 🇧🇪 = "Belgium"
        let 🇹🇩 = "Chad"
        let 🇬🇳 = "Guinea"
        let 🇮🇪 = "Ireland"
        let 🇨🇮 = "Ivory Coast"
        let 🇰🇼 = "Kuwait"
        let 🇲🇱 = "Mali"
        let 🇷🇴 = "Romania"
        let 🇸🇰 = "Slovakia"
        let 🇸🇮 = "Slovenia"
        let 🇸🇩 = "Sudan"
        let 🇦🇪 = "UAE"
        let 🇪🇭 = "Western Sahara"
        
        // which flag is where now?
        let countries = [🇧🇪, 🇹🇩, 🇷🇴, 🇦🇩, 🇲🇱, 🇬🇳, 🇪🇭, 🇸🇩, 🇦🇪, 🇰🇼, 🇸🇰, 🇸🇮, 🇮🇪, 🇨🇮]
        
        ///////////
        // Zalgo //
        ///////////
        
        func c̀o̤͙̠̞̊̽̈ͭm͕̮͓͖̮͎̲m̛̪͖̘̝̮̹aͮ̂ͬͫnͭ͏dM̯͙̯̮̲ͩͯ̉̂͒eO̩̜͐͗h̶D̥͔͙a̡̦͎̻̅̎̓r̅̽͘kL͓̺̣̘̙ͭ̐ͫ̆ͮ͠o͛ͯ̚҉̞̫̱rd() { print("Go for̦̟͌̆th and͍̼̍̈́ obfu̠̺̽̋̿ͅs̙͈ͣͮc̀a̙̟̮̖̩̍̃́̀̓te͢͞!̴̶̥͉̹̙̬̥͈̘͍̖̣̰͂͐̅́͊́ͧ̽̿̀̓ͣ͝") }
        c̀o̤͙̠̞̊̽̈ͭm͕̮͓͖̮͎̲m̛̪͖̘̝̮̹aͮ̂ͬͫnͭ͏dM̯͙̯̮̲ͩͯ̉̂͒eO̩̜͐͗h̶D̥͔͙a̡̦͎̻̅̎̓r̅̽͘kL͓̺̣̘̙ͭ̐ͫ̆ͮ͠o͛ͯ̚҉̞̫̱rd()
    }
}
