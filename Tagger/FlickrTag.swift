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

// MARK: FlickrTag: Tag -

final class FlickrTag: Tag {
    
    // MARK: - Properties
    
    private (set) var score: Int? = nil
    
    // MARK: - Init
    
    init(content: String) {
        super.init(name: content)
    }
    
    init(score: Int, content: String) {
        self.score = score
        super.init(name: content)
    }
    
    convenience init?(json: JSONDictionary) {
        guard let content = JSON.string(json, key: FlickrApiClient.Constants.FlickrResponseKeys.Content) else {
            return nil
        }
        self.init(content: content)
        
        if let scoreString = JSON.string(json, key: FlickrApiClient.Constants.FlickrResponseKeys.Score),
            let score = Int(scoreString) {
            self.score = score
        }
    }
    
}

// MARK: - FlickrTag: JSONParselable -

extension FlickrTag: JSONParselable {
    
    static func decode(input: JSONDictionary) -> FlickrTag? {
        return FlickrTag.init(json: input)
    }
    
}
