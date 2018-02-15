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
        var param = getBaseMethodParameters(Constants.FlickrParameterValues.TagsHotList)
        param[Constants.FlickrParameterKeys.Period] = period.rawValue as AnyObject
        param[Constants.FlickrParameterKeys.Count] = count as AnyObject
        
        let keys = [Constants.FlickrResponseKeys.HotTags, Constants.FlickrResponseKeys.Tag]
        let request = URLRequest(url: url(from: param))
        fetchCollectionForRequest(request, rootKeys: keys, success: success, fail: fail)
    }
    
    func relatedTagsForTag(_ tag: String, successBlock success: @escaping FlickrTagsSuccessCompletionHandler, failBlock fail: @escaping FlickrFailureCompletionHandler) {
        var param = getBaseMethodParameters(Constants.FlickrParameterValues.TagsGetRelated)
        param[Constants.FlickrParameterKeys.Tag] = tag as AnyObject
        
        let keys = [Constants.FlickrResponseKeys.Tags, Constants.FlickrResponseKeys.Tag]
        let request = URLRequest(url: url(from: param))
        fetchCollectionForRequest(request, rootKeys: keys, success: success, fail: fail)
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
            parameters[Constants.FlickrParameterKeys.Page] = randomPage
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
        fetchResourceForRequest(request, success: success, fail: fail)
    }
    
    /// Returns number of pages for a photos search.
    fileprivate func countPagesForPhotoSearchWithParameters(_ param: MethodParameters, successBlock success: @escaping FlickrNumberSuccessCompletionHandler, failBlock fail: @escaping FlickrFailureCompletionHandler) {
        let request = URLRequest(url: url(from: param))
        fetchJsonForRequest(request) { result in
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
                guard let photosDictionary = json[Constants.FlickrResponseKeys.Photos] as? JSONDictionary,
                    let numberOfPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
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
        var parameters = getBaseMethodParameters(Constants.FlickrParameterValues.PeopleGetInfo)
        parameters[Constants.FlickrParameterKeys.UserID] = userID as AnyObject
        
        let request = URLRequest(url: url(from: parameters))
        fetchResourceForRequest(request, success: success, fail: failure)
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
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.TestLogin,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat
        ]
        
        guard let URL = FlickrApiClient.getTempOAuth().buildSHAEncryptedURLForHTTPMethod(.get, baseURL: baseURL, requestParameters: params) else {
            sendError("Could not build HMAC-SHA1 encrypted URL. Try to login in your Flickr account.")
            return
        }
        
        fetchJsonForRequest(URLRequest(url: URL)) { result in
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
        parameters[Constants.FlickrParameterKeys.PerPage] = "\(Constants.FlickrParameterValues.PerPageMax)"
        parameters[Constants.FlickrResponseKeys.UserID] = user.userID
        
        guard let URL = FlickrApiClient.getTempOAuth().buildSHAEncryptedURLForHTTPMethod(.get, baseURL: baseURL, requestParameters: parameters) else {
            return
        }
        
        let request = URLRequest(url: URL)
        fetchCollectionForRequest(request, rootKeys: ["photos", "photo"], success: success, fail: failure)
    }
    
    // MARK: Private
    
    fileprivate class func getTempOAuth() -> FlickrOAuth {
        return FlickrOAuth(consumerKey: FlickrApplicationKey, consumerSecret: FlickrApplicationSecret, callbackURL: "")
    }
    
    // MARK: - Private Helpers -
    
    func getBaseMethodParameters(_ method: String? = nil) -> MethodParameters {
        var parameters = [
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        if let method = method { parameters[Constants.FlickrParameterKeys.Method] = method }
        return parameters as MethodParameters
    }
    
    fileprivate func getBaseParametersForPhotosSearch() -> MethodParameters {
        var methodParameters = getBaseMethodParameters(Constants.FlickrParameterValues.SearchMethod)
        methodParameters[Constants.FlickrParameterKeys.Extras] = "\(Constants.FlickrParameterValues.ThumbnailURL),\(Constants.FlickrParameterValues.SmallURL),\(Constants.FlickrParameterValues.MediumURL)" as AnyObject
        methodParameters[Constants.FlickrParameterKeys.ContentType] = Constants.FlickrParameterValues.ContentType.photos.rawValue
        methodParameters[Constants.FlickrParameterKeys.SafeSearch] = Constants.FlickrParameterValues.UseSafeSearch as AnyObject
        methodParameters[Constants.FlickrParameterKeys.Page] = 1 as AnyObject
        methodParameters[Constants.FlickrParameterKeys.PerPage] = Constants.FlickrParameterValues.PerPageDefault as AnyObject
        return methodParameters
    }
    
    fileprivate func parametersForPhotosSearchWithTags(_ tags: [String]) -> MethodParameters {
        var methodParameters = getBaseParametersForPhotosSearch()
        methodParameters[Constants.FlickrParameterKeys.Tags] = tags.joined(separator: ",") as AnyObject
        return methodParameters
    }
    
    fileprivate func checkFlickrResponse(_ json: JSONDictionary) -> Bool {
        guard let flickrStatus = json[Constants.FlickrResponseKeys.Status] as? String, flickrStatus == Constants.FlickrResponseValues.OKStatus else {
            return false
        }
        return true
    }
    
}
