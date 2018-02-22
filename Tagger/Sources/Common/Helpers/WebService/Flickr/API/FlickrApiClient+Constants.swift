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
        
        struct Flickr {
            static let baseURL = "https://api.flickr.com/services/rest"
            static let searchBBoxHalfWidth = 1.0
            static let searchBBoxHalfHeight = 1.0
            static let searchLatRange = SearchCoordinateRange(start: -90.0, end: 90.0)
            static let searchLonRange = SearchCoordinateRange(start: -180.0, end: 180.0)
        }

        // MARK: - Params -

        struct Params {

            struct Keys {
                static let method = "method"
                static let apiKey = "api_key"
                static let galleryId = "gallery_id"
                static let extras = "extras"
                static let format = "format"
                static let noJSONCallback = "nojsoncallback"
                static let safeSearch = "safe_search"
                static let text = "text"
                static let page = "page"
                static let perPage = "per_page"
                static let period = "period"
                static let count = "count"
                static let contentType = "content_type"
                static let tag = "tag"
                static let tags = "tags"
                static let userId = "user_id"
            }

            struct Values {

                static let apiKey = Tagger.Constants.Flickr.applicationKey
                static let responseFormat = "json"
                static let disableJSONCallback = "1"
                static let searchMethod = "flickr.photos.search"
                static let tagsHotList = "flickr.tags.getHotList"
                static let tagsGetRelated = "flickr.tags.getRelated"
                static let galleryPhotosMethod = "flickr.galleries.getPhotos"
                static let testLogin = "flickr.test.login"
                static let peopleGetInfo = "flickr.people.getInfo"
                static let thumbnailURL = "url_t"
                static let smallURL = "url_s"
                static let mediumURL = "url_m"
                static let useSafeSearch = "1"
                static let dayPeriod = "day"
                static let weekPeriod = "week"
                static let perPageDefault = 100
                static let perPageMax = 500

                enum ContentType: Int {
                    case photos = 1
                    case screenshots
                    case other
                }

            }

        }

        struct Response {

            struct Keys {
                static let status = "stat"
                static let photos = "photos"
                static let photo = "photo"
                static let id = "id"
                static let NSID = "nsid"
                static let title = "title"
                static let thumbnailURL = "url_t"
                static let smallURL = "url_s"
                static let mediumURL = "url_m"
                static let page = "page"
                static let pages = "pages"
                static let perPage = "perpage"
                static let total = "total"
                static let hotTags = "hottags"
                static let tag = "tag"
                static let tags = "tags"
                static let owner = "owner"
                static let secret = "secret"
                static let server = "server"
                static let farm = "farm"
                static let score = "score"
                static let content = "_content"
                static let userID = "user_id"
                static let iconServer = "iconserver"
                static let iconFarm = "iconfarm"
                static let username = "username"
                static let realName = "realname"
                static let person = "person"
            }

            struct Values {
                static let okStatus = "ok"
            }

        }
        
        // MARK: - Errors -
        
        struct Error {
            
            // MARK: Domains & Code
            
            static let ErrorDomain = "\(Tagger.Constants.Error.baseDomain).FlickrApiClient"
            static let ErrorCode = 300
            
            static let NumberOfPagesForPhotoSearchErrorDomain = "\(ErrorDomain).number-of-pages"
            static let NumberOfPagesForPhotoSearchErrorCode = 301
            
            static let FetchPhotosErrorDomain = "\(ErrorDomain).fetch-photos"
            static let FetchPhotosErrorCode = 302
            
            static let GetTagsHotListErrorDomain = "\(ErrorDomain).tags-getHotList"
            static let GetTagsHotListErrorCode = 303
            
            static let LoadImageErrorDomain = "\(ErrorDomain).load-image"
            static let LoadImageErrorCode = 304
            
            static let EmptyResultErrorDomain = "\(ErrorDomain).empty-result"
            static let EmptyResultErrorCode = 305
            
            static let DefaultErrorCode = 307
            
            static let DefaultError = NSError(
                domain: FlickrApiClient.Constants.Error.ErrorDomain,
                code: FlickrApiClient.Constants.Error.DefaultErrorCode,
                userInfo: [NSLocalizedDescriptionKey : "An error occured. Try again later."]
            )
            
            static let EmptyResponseError = NSError(
                domain: FlickrApiClient.Constants.Error.EmptyResultErrorDomain,
                code: FlickrApiClient.Constants.Error.EmptyResultErrorCode,
                userInfo: [NSLocalizedDescriptionKey : "No data was returned."]
            )
        }
    }
    
}
