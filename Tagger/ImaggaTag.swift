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
import CoreData

// MARK: ImaggaTag

struct ImaggaTag {
    
    // MARK: - Properties
    
    fileprivate (set) var tag: String
    fileprivate (set) var confidence: Double
    
    // MARK: - Init
    
    init(confidence: Double, tag: String) {
        self.tag = tag
        self.confidence = confidence
    }
    
    init?(json: JSONDictionary) {
        guard let confidence = JSON.double(json, key: ImaggaApiClient.Constants.ResponseKeys.Confidence),
            let tag = JSON.string(json, key: ImaggaApiClient.Constants.ResponseKeys.Tag) else {
                return nil
        }
        self.init(confidence: confidence, tag: tag)
    }
    
    // MARK: - Static
    
    static func sanitezedTags(_ json: [JSONDictionary]) -> [ImaggaTag] {
        return json.flatMap { self.init(json: $0) }
    }
    
    // MARK: Core Data
    
    func convertToTagInContext(_ context: NSManagedObjectContext) -> Tag {
        return Tag(name: tag, context: context)
    }
    
    @discardableResult static func mapImaggaTags(_ tags: [ImaggaTag], withParentCategory category: Category? = nil, toTagsInContext context: NSManagedObjectContext) -> [Tag] {
        return tags.map {
            let tag = $0.convertToTagInContext(context)
            
            if let category = category {
                tag.category = category
            }
            
            return tag
        }
    }
    
}

// MARK: - ImaggaTag: JSONParselable -

extension ImaggaTag: JSONParselable {
    
    static func decode(_ input: JSONDictionary) -> ImaggaTag? {
        return ImaggaTag.init(json: input)
    }
    
}
