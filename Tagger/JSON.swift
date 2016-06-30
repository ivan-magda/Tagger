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

// Parsing JSON using Oscar Swanros's approach http://swanros.com/how-i-deal-with-json-in-swift/
// Functional part of this approach described by the Chris Eidhof's
// in the blog post http://chris.eidhof.nl/post/json-parsing-in-swift/

// MARK: Typealias

public typealias JSONDictionary = [String: AnyObject]

// MARK: - Private Functions

/// Takes a double optional and removes one level of optional-ness.
private func flatten<A>(x: A??) -> A? {
    if let y = x { return y }
    return nil
}

// The custom operator >>>= takes an optional of type A to the left,
// and a function that takes an A as a parameter and returns an optional B to the right.
// Basically, it says "apply."
infix operator >>>= {}
private func >>>= <A, B> (optional: A?, f: A -> B?) -> B? {
    return flatten(optional.map(f))
}

// MARK: - JSON

class JSON {
    
    // MARK: - Init
    
    private init() {
    }
    
    // MARK: - Decode
    
    // These functions retrieve data from JSON structures in a type-safe manner,
    // and they're the building blocks.
    
    class func number(input: [NSObject: AnyObject], key: String) -> NSNumber? {
        return input[key] >>>= { $0 as? NSNumber }
    }
    
    class func int(input: [NSObject: AnyObject], key: String) -> Int? {
        return number(input, key: key).map { $0.integerValue }
    }
    
    class func float(input: [NSObject: AnyObject], key: String) -> Float? {
        return number(input, key: key).map { $0.floatValue }
    }
    
    class func double(input: [NSObject: AnyObject], key: String) -> Double? {
        return number(input, key: key).map { $0.doubleValue }
    }
    
    class func string(input: [String: AnyObject], key: String) -> String? {
        return input[key] >>>= { $0 as? String }
    }
    
    class func bool(input: [String: AnyObject], key: String) -> Bool? {
        return number(input, key: key).map { $0.boolValue }
    }
    
}
