//
//  JSON.swift
//  On the Map
//
//  Created by Ivan Magda on 20.03.16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

// Parsing JSON using Oscar Swanros's approach http://swanros.com/how-i-deal-with-json-in-swift/
// Functional part of this approach described by the Chris Eidhof's
// in the blog post http://chris.eidhof.nl/post/json-parsing-in-swift/

//----------------------------------------------------------
// MARK: Typealias
//----------------------------------------------------------

public typealias JSONDictionary = [String: AnyObject]

//----------------------------------------------------------
// MARK: - Private Functions
//----------------------------------------------------------

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

//----------------------------------------------------------
// MARK: - JSON -
//----------------------------------------------------------

public class JSON {
    
    //------------------------------------------------------
    // MARK: Decode
    //------------------------------------------------------
    
    // These functions retrieve data from JSON structures in a type-safe manner,
    // and they're the building blocks.
    
    class func number(input: [NSObject:AnyObject], key: String) -> NSNumber? {
        return input[key] >>>= { $0 as? NSNumber }
    }
    
    class func int(input: [NSObject:AnyObject], key: String) -> Int? {
        return number(input, key: key).map { $0.integerValue }
    }
    
    class func float(input: [NSObject:AnyObject], key: String) -> Float? {
        return number(input, key: key).map { $0.floatValue }
    }
    
    class func double(input: [NSObject:AnyObject], key: String) -> Double? {
        return number(input, key: key).map { $0.doubleValue }
    }
    
    class func string(input: [String:AnyObject], key: String) -> String? {
        return input[key] >>>= { $0 as? String }
    }
    
    class func bool(input: [String:AnyObject], key: String) -> Bool? {
        return number(input, key: key).map { $0.boolValue }
    }
    
}
