//
//  CaseCountable.swift
//  Tagger
//
//  Created by Ivan Magda on 05/06/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

/**
 * Use a reusable protocol which automatically performs the case count.
 * Question on StackOverFlow: http://stackoverflow.com/questions/27094878/how-do-i-get-the-count-of-a-swift-enum
 * Answered by Tom Pelaia: http://stackoverflow.com/users/1389909/tom-pelaia
 */

/// Enum which provides a count of its cases.
protocol CaseCountable {
    static func countCases() -> Int
    static var caseCount: Int { get }
}

/**
 * Provide a default implementation to count the cases for Int enums assuming starting at 0 and contiguous.
 */
extension CaseCountable where Self : RawRepresentable, Self.RawValue == Int {
    
    static func countCases() -> Int {
        var count = 0
        while let _ = Self(rawValue: count) { count += 1 }
        return count
    }
    
    static var caseCount: Int {
        return Self.countCases()
    }
    
}
