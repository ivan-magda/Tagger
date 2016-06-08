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

// MARK: FlickrApiClient (Constants)

extension FlickrApiClient {
    
    typealias SearchCoordinateRange = (start: Double, end: Double)
    
    // MARK: - Constants
    
    struct Constants {
        
        // MARK: Flickr
        
        struct Flickr {
            static let APIScheme = "https"
            static let APIHost = "api.flickr.com"
            static let APIPath = "/services/rest"
            
            static let SearchBBoxHalfWidth = 1.0
            static let SearchBBoxHalfHeight = 1.0
            static let SearchLatRange = SearchCoordinateRange(start: -90.0, end: 90.0)
            static let SearchLonRange = SearchCoordinateRange(start: -180.0, end: 180.0)
        }
        
        // MARK: Flickr Parameter Keys
        
        struct FlickrParameterKeys {
            static let Method = "method"
            static let APIKey = "api_key"
            static let GalleryID = "gallery_id"
            static let Extras = "extras"
            static let Format = "format"
            static let NoJSONCallback = "nojsoncallback"
            static let SafeSearch = "safe_search"
            static let Text = "text"
            static let Page = "page"
            static let PerPage = "per_page"
            static let Period = "period"
            static let Count = "count"
            static let ContentType = "content_type"
            static let Tags = "tags"
        }
        
        // MARK: Flickr Parameter Values
        
        struct FlickrParameterValues {
            static let APIKey = FlickrApplicationKey
            static let ResponseFormat = "json"
            static let DisableJSONCallback = "1"
            static let SearchMethod = "flickr.photos.search"
            static let TagsHotList = "flickr.tags.getHotList"
            static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
            static let ThumbnailURL = "url_t"
            static let SmallURL = "url_s"
            static let MediumURL = "url_m"
            static let UseSafeSearch = "1"
            static let DayPeriod = "day"
            static let WeekPeriod = "week"
            
            enum ContentType: Int {
                case Photos = 1
                case Screenshots
                case Other
            }
            
        }
        
        // MARK: Flickr Response Keys
        
        struct FlickrResponseKeys {
            static let Status = "stat"
            static let Photos = "photos"
            static let Photo = "photo"
            static let Id = "id"
            static let Title = "title"
            static let ThumbnailURL = "url_t"
            static let SmallURL = "url_s"
            static let MediumURL = "url_m"
            static let Page = "page"
            static let Pages = "pages"
            static let PerPage = "perpage"
            static let Total = "total"
            static let HotTags = "hottags"
            static let Tag = "tag"
            static let Owner = "owner"
            static let Secret = "secret"
            static let Server = "server"
            static let Farm = "farm"
        }
        
        // MARK: Flickr Response Values
        
        struct FlickrResponseValues {
            static let OKStatus = "ok"
        }
        
        // MARK: Error
        
        struct Error {
            static let ErrorDomain = "\(BaseErrorDomain).FlickrApiClient"
            static let ErrorCode = 300
            
            static let NumberOfPagesForPhotoSearchErrorDomain = "\(ErrorDomain).number-of-pages"
            static let NumberOfPagesForPhotoSearchErrorCode = 301
            
            static let FetchPhotosErrorDomain = "\(ErrorDomain).fetch-photos"
            static let FetchPhotosErrorCode = 302
            
            static let GetTagsHotListErrorDomain = "\(ErrorDomain).tags-getHotList"
            static let GetTagsHotListErrorCode = 303
            
            static let LoadImageErrorDomain = "\(ErrorDomain).load-image"
            static let LoadImageErrorCode = 304
        }
        
    }
    
}
