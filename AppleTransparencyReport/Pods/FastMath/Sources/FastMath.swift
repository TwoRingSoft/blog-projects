//
//  FastMath.swift
//  FastMath
//
//  Created by Andrew McKnight on 11/20/17.
//

import Foundation

public struct FastMath {

    /// Optionally provide a block for FastMath to log some details of its calculations.
    public static var logBlock: ((String) -> Void)?

}

internal func log(_ message: String) {
    #if DEBUG
        FastMath.logBlock?(message)
    #endif
}
