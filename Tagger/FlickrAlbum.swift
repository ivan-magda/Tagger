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

// MARK: FlickrAlbum

struct FlickrAlbum {
    
    // MARK: Properties
    
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    var photos: [FlickrPhoto]
    
    // MARK: Init
    
    init?(json: JSONDictionary) {
        guard let photosJson = json[FlickrApiClient.Constants.FlickrResponseKeys.Photos] as? JSONDictionary,
            let page = JSON.int(photosJson, key: FlickrApiClient.Constants.FlickrResponseKeys.Page),
            let pages = JSON.int(photosJson, key: FlickrApiClient.Constants.FlickrResponseKeys.Pages),
            let perpage = JSON.int(photosJson, key: FlickrApiClient.Constants.FlickrResponseKeys.PerPage),
            let totalString = JSON.string(photosJson, key: FlickrApiClient.Constants.FlickrResponseKeys.Total),
            let total = Int(totalString),
            let photoJsonArray = photosJson[FlickrApiClient.Constants.FlickrResponseKeys.Photo] as? [JSONDictionary] else {
                return nil
        }
        
        self.page = page
        self.pages = pages
        self.perpage = perpage
        self.total = total
        self.photos = FlickrPhoto.sanitezedPhotos(photoJsonArray)
    }
    
}

// MARK: - FlickrAlbum: JSONParselable -

extension FlickrAlbum: JSONParselable {
    
    static func decode(input: JSONDictionary) -> FlickrAlbum? {
        return FlickrAlbum.init(json: input)
    }
    
}
