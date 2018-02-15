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
import UIKit.UIImage

// MARK: Types

enum Period: String {
    case Day = "day"
    case Week = "week"
}

// MARK: - Typealiases

typealias FlickrFailureCompletionHandler = (_ error: Error) -> Void
typealias FlickrTagsSuccessCompletionHandler = (_ tags: [FlickrTag]) -> Void
typealias FlickrPhotosSearchSuccessCompletionHandler = (_ album: FlickrAlbum) -> Void
typealias FlickrNumberSuccessCompletionHandler = (_ number: Int) -> Void
typealias FlickrPhotoSuccessCompletionHandler = (_ photo: FlickrPhoto) -> Void
typealias FlickrPhotosSuccessCompletionHandler = (_ photos: [FlickrPhoto]) -> Void
typealias FlickrPersonInfoSuccessCompletionHandler = (_ person: FlickrPersonInfo) -> Void

// MARK: - FlickrApiClient (Calling Api Endpoints)

extension FlickrApiClient {
    
    // MARK: - Tags -
    // MARK: Public
    
    func tagsHotListForPeriod(_ period: Period, numberOfTags count: Int = 20, successBlock success: @escaping FlickrTagsSuccessCompletionHandler, failBlock fail: @escaping FlickrFailureCompletionHandler) {
        var params = getBaseMethodParameters(Constants.Params.Values.tagsHotList)
        params[Constants.Params.Keys.period] = period.rawValue
        params[Constants.Params.Keys.count] = count
        
        let keys = [Constants.Response.Keys.hotTags, Constants.Response.Keys.tag]
        let request = URLRequest(url: url(from: params))
        getCollection(for: request, rootKeys: keys, success: success, fail: fail)
    }
    
    func relatedTagsForTag(_ tag: String, successBlock success: @escaping FlickrTagsSuccessCompletionHandler, failBlock fail: @escaping FlickrFailureCompletionHandler) {
        var param = getBaseMethodParameters(Constants.Params.Values.tagsGetRelated)
        param[Constants.Params.Keys.tag] = tag
        
        let keys = [Constants.Response.Keys.tags, Constants.Response.Keys.tag]
        let request = URLRequest(url: url(from: param))
        getCollection(for: request, rootKeys: keys, success: success, fail: fail)
    }
    
    // MARK: - Photos -
    // MARK: Public
    
    func searchPhotosWithTags(_ tags: [String], successBlock success: @escaping FlickrPhotosSearchSuccessCompletionHandler, failBlock fail: @escaping FlickrFailureCompletionHandler) {
        searchPhotosWithParameters(parametersForPhotosSearchWithTags(tags), successBlock: success, failBlock: fail)
    }
    
    func randomImageFromTags(_ tags: [String], successBlock success: @escaping ImageDownloadingCompletionHandler, failBlock fail: @escaping FlickrFailureCompletionHandler) {
        randomPhotoForPhotosSearchWithParameters(parametersForPhotosSearchWithTags(tags), successBlock: { [unowned self] photo in
            guard let url = URL(string: photo.urlSmall) else {
                fail(Constants.Error.DefaultError)
                return
            }
            self.getImage(for: url, success: success, fail: fail)
            }, failBlock: fail)
    }
    
    func randomPhotoForPhotosSearchWithParameters(_ parameters: MethodParameters, successBlock success: @escaping FlickrPhotoSuccessCompletionHandler, failBlock fail: @escaping FlickrFailureCompletionHandler) {
        countPagesForPhotoSearchWithParameters(parameters, successBlock: { pages in
            let pageLimit = min(pages, 20)
            let randomPage = RandomNumberUtils.numberFromZeroTo(pageLimit) + 1
            
            var parameters = parameters
            parameters[Constants.Params.Keys.page] = randomPage
            self.searchPhotosWithParameters(parameters, successBlock: { album in
                guard album.photos.count > 0 else {
                    fail(Constants.Error.EmptyResponseError)
                    return
                }
                
                let randomIndex = RandomNumberUtils.numberFromZeroTo(album.photos.count)
                success(album.photos[randomIndex])
                }, failBlock: fail)
            }, failBlock: fail)
    }
    
    // MARK: Private
    
    fileprivate func searchPhotosWithParameters(_ param: MethodParameters, successBlock success: @escaping FlickrPhotosSearchSuccessCompletionHandler, failBlock fail: @escaping FlickrFailureCompletionHandler) {
        let request = URLRequest(url: url(from: param))
        getResource(for: request, success: success, fail: fail)
    }
    
    /// Returns number of pages for a photos search.
    fileprivate func countPagesForPhotoSearchWithParameters(_ param: MethodParameters, successBlock success: @escaping FlickrNumberSuccessCompletionHandler, failBlock fail: @escaping FlickrFailureCompletionHandler) {
        let request = URLRequest(url: url(from: param))
        fetchJson(for: request) { result in
            func sendError(_ error: String) {
                self.log("Error: \(error)")
                let error = NSError(
                    domain: Constants.Error.NumberOfPagesForPhotoSearchErrorDomain,
                    code: Constants.Error.NumberOfPagesForPhotoSearchErrorCode,
                    userInfo: [NSLocalizedDescriptionKey : error]
                )
                fail(error)
            }
            
            switch result {
            case .error(let error):
                sendError(error.localizedDescription)
            case .json(let json):
                guard let photosDictionary = json[Constants.Response.Keys.photos] as? JSONDictionary,
                    let numberOfPages = photosDictionary[Constants.Response.Keys.pages] as? Int else {
                        sendError("Could't parse recieved JSON object")
                        return
                }
                success(numberOfPages)
            default:
                sendError(result.defaultErrorMessage()!)
            }
        }
    }
    
    // MARK: - User -
    
    func getPersonInfoWithNSID(_ userID: String, success: @escaping FlickrPersonInfoSuccessCompletionHandler, failure: @escaping FlickrFailureCompletionHandler) {
        var parameters = getBaseMethodParameters(Constants.Params.Values.peopleGetInfo)
        parameters[Constants.Params.Keys.userId] = userID
        
        let request = URLRequest(url: url(from: parameters))
        getResource(for: request, success: success, fail: failure)
    }
    
    func getProfilePictureFromUserInfo(_ info: FlickrPersonInfo, success: @escaping ImageDownloadingCompletionHandler, failure: @escaping FlickrFailureCompletionHandler) {
        let URL = Foundation.URL(string: "https://farm\(info.iconFarm).staticflickr.com/\(info.iconServer)/buddyicons/\(info.nsid)_l.jpg")!
        getImage(for: URL, success: success, fail: failure)
    }
    
    func getProfilePictureWithNSID(_ nsid: String, success: @escaping ImageDownloadingCompletionHandler, failure: @escaping FlickrFailureCompletionHandler) {
        getPersonInfoWithNSID(nsid,
                    success: { self.getProfilePictureFromUserInfo($0, success: success, failure: failure) },
                    failure: failure)
    }
    
    // MARK: - Authenticated Requests -
    
    func testLogin(_ completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        func sendError(_ error: String) {
            self.log("Error: \(error)")
            let error = NSError(
                domain: Constants.Error.ErrorDomain,
                code: Constants.Error.DefaultErrorCode,
                userInfo: [NSLocalizedDescriptionKey : error]
            )
            completionHandler(false, error)
        }
        
        let params = [
            Constants.Params.Keys.method: Constants.Params.Values.testLogin,
            Constants.Params.Keys.noJSONCallback: Constants.Params.Values.disableJSONCallback,
            Constants.Params.Keys.format: Constants.Params.Values.responseFormat
        ]
        
        guard let URL = FlickrApiClient.getTempOAuth().buildSHAEncryptedURLForHTTPMethod(.get, baseURL: baseURL, requestParameters: params) else {
            sendError("Could not build HMAC-SHA1 encrypted URL. Try to login in your Flickr account.")
            return
        }
        
        fetchJson(for: URLRequest(url: URL)) { result in
            switch result {
            case .error(let error):
                sendError(error.localizedDescription)
            case .json(let json):
                guard self.checkFlickrResponse(json) == true else {
                    sendError("Flickr API return an error.")
                    return
                }
                print("TEST_LOGIN_SUCCESS: \(json)")
                completionHandler(true, nil)
            default:
                sendError(result.defaultErrorMessage()!)
            }
        }
    }
    
    func getUserPhotos(_ user: FlickrUser, success: @escaping FlickrPhotosSuccessCompletionHandler, failure: @escaping FlickrFailureCompletionHandler) {
        var parameters = Parameters()
        getBaseParametersForPhotosSearch().forEach { parameters[$0] = "\($1)" }
        parameters[Constants.Params.Keys.perPage] = "\(Constants.Params.Values.perPageMax)"
        parameters[Constants.Response.Keys.userID] = user.userID
        
        guard let URL = FlickrApiClient.getTempOAuth().buildSHAEncryptedURLForHTTPMethod(.get, baseURL: baseURL, requestParameters: parameters) else {
            return
        }
        
        let request = URLRequest(url: URL)
        getCollection(for: request, rootKeys: ["photos", "photo"], success: success, fail: failure)
    }
    
    // MARK: Private
    
    fileprivate class func getTempOAuth() -> FlickrOAuth {
        return FlickrOAuth(consumerKey: FlickrApplicationKey, consumerSecret: FlickrApplicationSecret, callbackURL: "")
    }
    
    // MARK: - Private Helpers -
    
    func getBaseMethodParameters(_ method: String? = nil) -> MethodParameters {
        var parameters = [
            Constants.Params.Keys.apiKey: Constants.Params.Values.apiKey,
            Constants.Params.Keys.format: Constants.Params.Values.responseFormat,
            Constants.Params.Keys.noJSONCallback: Constants.Params.Values.disableJSONCallback
        ]
        if let method = method { parameters[Constants.Params.Keys.method] = method }
        return parameters as MethodParameters
    }
    
    fileprivate func getBaseParametersForPhotosSearch() -> MethodParameters {
        var params = getBaseMethodParameters(Constants.Params.Values.searchMethod)
        params[Constants.Params.Keys.extras] = "\(Constants.Params.Values.thumbnailURL),\(Constants.Params.Values.smallURL),\(Constants.Params.Values.mediumURL)"
        params[Constants.Params.Keys.contentType] = Constants.Params.Values.ContentType.photos.rawValue
        params[Constants.Params.Keys.safeSearch] = Constants.Params.Values.useSafeSearch
        params[Constants.Params.Keys.page] = 1
        params[Constants.Params.Keys.perPage] = Constants.Params.Values.perPageDefault

        return params
    }
    
    fileprivate func parametersForPhotosSearchWithTags(_ tags: [String]) -> MethodParameters {
        var params = getBaseParametersForPhotosSearch()
        params[Constants.Params.Keys.tags] = tags.joined(separator: ",")

        return params
    }
    
    fileprivate func checkFlickrResponse(_ json: JSONDictionary) -> Bool {
        guard let flickrStatus = json[Constants.Response.Keys.status] as? String,
            flickrStatus == Constants.Response.Values.okStatus else {
            return false
        }

        return true
    }
    
}
