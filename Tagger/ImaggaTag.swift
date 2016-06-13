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

// MARK: ImaggaTag: Tag -

final class ImaggaTag: Tag {
    
    // MARK: - Properties
    
    let confidence: Double
    
    // MARK: - Init
    
    init(confidence: Double, tag: String) {
        self.confidence = confidence
        super.init(name: tag)
    }
    
    convenience init?(json: JSONDictionary) {
        guard let confidence = JSON.double(json, key: "confidence"),
            let tag = JSON.string(json, key: "tag") else {
                return nil
        }
        self.init(confidence: confidence, tag: tag)
    }
    
    // MARK: - Static
    
    static func sanitezedTags(json: [JSONDictionary]) -> [ImaggaTag] {
        return json.flatMap { self.init(json: $0) }
    }
    
}

// MARK: - ImaggaTag: JSONParselable -

extension ImaggaTag: JSONParselable {
    
    static func decode(input: JSONDictionary) -> ImaggaTag? {
        return ImaggaTag.init(json: input)
    }
    
}
