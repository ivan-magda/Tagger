/**
 * Copyright (c) 2016 Ivan Magda
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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
