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

// MARK: FlickrPhoto

struct FlickrPhoto {
    
    // MARK: Properties
    
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let urlThumbnail: String
    let urlSmall: String
    
    // MARK: Init
    
    init?(json: JSONDictionary) {
        guard let id = JSON.string(json, key: FlickrApiClient.Constants.FlickrResponseKeys.Id),
            let owner = JSON.string(json, key: FlickrApiClient.Constants.FlickrResponseKeys.Owner),
            let secret = JSON.string(json, key: FlickrApiClient.Constants.FlickrResponseKeys.Secret),
            let server = JSON.string(json, key: FlickrApiClient.Constants.FlickrResponseKeys.Server),
            let farm = JSON.int(json, key: FlickrApiClient.Constants.FlickrResponseKeys.Farm),
            let title = JSON.string(json, key: FlickrApiClient.Constants.FlickrResponseKeys.Title),
            let urlThumbnail = JSON.string(json, key: FlickrApiClient.Constants.FlickrResponseKeys.ThumbnailURL),
            let urlSmall = JSON.string(json, key: FlickrApiClient.Constants.FlickrResponseKeys.SmallURL) else {
                return nil
        }
        
        self.id = id
        self.owner = owner
        self.secret = secret
        self.server = server
        self.farm = farm
        self.title = title
        self.urlThumbnail = urlThumbnail
        self.urlSmall = urlSmall
    }
    
    // MARK: Static
    
    static func sanitezedPhotos(json: [JSONDictionary]) -> [FlickrPhoto] {
        return json.flatMap { self.init(json: $0) }
    }
    
}

// MARK: - FlickrPhoto: JSONParselable -

extension FlickrPhoto: JSONParselable {
    static func decode(input: JSONDictionary) -> FlickrPhoto? {
        return self.init(json: input)
    }
}
