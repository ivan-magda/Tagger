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
    case day = "day"
    case week = "week"
}

// MARK: - Typealiases

typealias FlickrFailureCompletionHandler = (_ error: Error) -> Void
typealias FlickrTagsSuccessCompletionHandler = (_ tags: [FlickrTag]) -> Void
typealias FlickrPhotosSearchSuccessCompletionHandler = (_ album: FlickrAlbum) -> Void
typealias FlickrNumericSuccessCompletionHandler = (_ number: Int) -> Void
typealias FlickrPhotoSuccessCompletionHandler = (_ photo: FlickrPhoto) -> Void
typealias FlickrPhotosSuccessCompletionHandler = (_ photos: [FlickrPhoto]) -> Void
typealias FlickrPersonInfoSuccessCompletionHandler = (_ person: FlickrPersonInfo) -> Void

// MARK: - FlickrApiClient (Tags) -

extension FlickrApiClient {

    func getTagsHotList(for period: Period,
                        numberOfTags count: Int = 20,
                        success: @escaping FlickrTagsSuccessCompletionHandler,
                        failure: @escaping FlickrFailureCompletionHandler) {
        var params = getBaseMethodParams(Constants.Params.Values.tagsHotList)
        params[Constants.Params.Keys.period] = period.rawValue
        params[Constants.Params.Keys.count] = count

        let keys = [Constants.Response.Keys.hotTags, Constants.Response.Keys.tag]
        let request = URLRequest(url: url(from: params))

        getCollection(for: request, rootKeys: keys, success: success, failure: failure)
    }

    func getRelatedTags(for tag: String,
                        success: @escaping FlickrTagsSuccessCompletionHandler,
                        failure: @escaping FlickrFailureCompletionHandler) {
        var param = getBaseMethodParams(Constants.Params.Values.tagsGetRelated)
        param[Constants.Params.Keys.tag] = tag

        let keys = [Constants.Response.Keys.tags, Constants.Response.Keys.tag]
        let request = URLRequest(url: url(from: param))

        getCollection(for: request, rootKeys: keys, success: success, failure: failure)
    }

}

// MARK: - FlickrApiClient (Photos) -

extension FlickrApiClient {

    // MARK: Public

    func searchPhotos(for tags: [String],
                      success: @escaping FlickrPhotosSearchSuccessCompletionHandler,
                      failure: @escaping FlickrFailureCompletionHandler) {
        searchPhotos(with: getParamsForPhotosSearch(for: tags),
                     success: success,
                     failure: failure)
    }

    func getRandomPhoto(for tags: [String],
                        success: @escaping ImageDownloadingCompletionHandler,
                        failure: @escaping FlickrFailureCompletionHandler) {
        getRandomPhoto(for: getParamsForPhotosSearch(for: tags), success: { [unowned self] photo in
            guard let url = URL(string: photo.urlSmall) else {
                failure(Constants.Error.DefaultError)
                return
            }
            self.getImage(for: url, success: success, failure: failure)
            }, failure: failure)
    }

    func getRandomPhoto(for parameters: HttpMethodParams,
                        success: @escaping FlickrPhotoSuccessCompletionHandler,
                        failure: @escaping FlickrFailureCompletionHandler) {
        countPages(with: parameters, success: { pages in
            let pageLimit = min(pages, 20)
            let randomPage = RandomNumberUtils.numberFromZeroTo(pageLimit) + 1

            var parameters = parameters
            parameters[Constants.Params.Keys.page] = randomPage
            self.searchPhotos(with: parameters, success: { album in
                guard album.photos.count > 0 else {
                    failure(Constants.Error.EmptyResponseError)
                    return
                }

                let randomIndex = RandomNumberUtils.numberFromZeroTo(album.photos.count)
                success(album.photos[randomIndex])
            }, failure: failure)
        }, failure: failure)
    }

    func getUserPhotos(_ user: FlickrUser,
                       success: @escaping FlickrPhotosSuccessCompletionHandler,
                       failure: @escaping FlickrFailureCompletionHandler) {
        var parameters = FlickrOAuthMethodParams()
        getBaseParamsForPhotosSearch().forEach { parameters[$0] = "\($1)" }
        parameters[Constants.Params.Keys.perPage] = "\(Constants.Params.Values.perPageMax)"
        parameters[Constants.Response.Keys.userID] = user.userID

        guard let URL = FlickrApiClient.getTempOAuth().buildSHAEncryptedURL(for: .get, baseURL: baseURL, requestParameters: parameters) else {
            return
        }

        getCollection(for: URLRequest(url: URL),
                      rootKeys: ["photos", "photo"],
                      success: success,
                      failure: failure)
    }

    // MARK: Private

    private func searchPhotos(with params: HttpMethodParams,
                              success: @escaping FlickrPhotosSearchSuccessCompletionHandler,
                              failure: @escaping FlickrFailureCompletionHandler) {
        getResource(for: URLRequest(url: url(from: params)),
                    success: success,
                    failure: failure)
    }

    /// Returns number of pages for a photos search.
    private func countPages(with param: HttpMethodParams,
                            success: @escaping FlickrNumericSuccessCompletionHandler,
                            failure: @escaping FlickrFailureCompletionHandler) {
        let request = URLRequest(url: url(from: param))
        fetchJson(for: request) { result in
            func returnError(_ error: String) {
                self.log("Error: \(error)")
                let error = NSError(
                    domain: Constants.Error.NumberOfPagesForPhotoSearchErrorDomain,
                    code: Constants.Error.NumberOfPagesForPhotoSearchErrorCode,
                    userInfo: [NSLocalizedDescriptionKey : error]
                )
                failure(error)
            }

            switch result {
            case .error(let error):
                returnError(error.localizedDescription)
            case .json(let json):
                guard let photosDictionary = json[Constants.Response.Keys.photos] as? JSONDictionary,
                    let numberOfPages = photosDictionary[Constants.Response.Keys.pages] as? Int else {
                        returnError("Could't parse recieved JSON object")
                        return
                }
                success(numberOfPages)
            default:
                returnError(result.defaultErrorMessage()!)
            }
        }
    }

}

// MARK: - FlickrApiClient (User) -

extension FlickrApiClient {

    func getPersonInfoWithNSID(_ userID: String,
                               success: @escaping FlickrPersonInfoSuccessCompletionHandler,
                               failure: @escaping FlickrFailureCompletionHandler) {
        var parameters = getBaseMethodParams(Constants.Params.Values.peopleGetInfo)
        parameters[Constants.Params.Keys.userId] = userID

        getResource(for: URLRequest(url: url(from: parameters)),
                    success: success,
                    failure: failure)
    }

    func getProfilePhoto(for info: FlickrPersonInfo,
                         success: @escaping ImageDownloadingCompletionHandler,
                         failure: @escaping FlickrFailureCompletionHandler) {
        let URL = Foundation.URL(string: "https://farm\(info.iconFarm).staticflickr.com/\(info.iconServer)/buddyicons/\(info.nsid)_l.jpg")!
        getImage(for: URL, success: success, failure: failure)
    }

    func getProfilePhotoWithNSID(_ nsid: String,
                                 success: @escaping ImageDownloadingCompletionHandler,
                                 failure: @escaping FlickrFailureCompletionHandler) {
        getPersonInfoWithNSID(
            nsid,
            success: { self.getProfilePhoto(for: $0, success: success, failure: failure) },
            failure: failure
        )
    }

}

// MARK: - FlickrApiClient (Authenticated Requests) -

extension FlickrApiClient {

    func testLogin(_ callback: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        func sendError(_ error: String) {
            self.log("Error: \(error)")
            let error = NSError(
                domain: Constants.Error.ErrorDomain,
                code: Constants.Error.DefaultErrorCode,
                userInfo: [NSLocalizedDescriptionKey : error]
            )
            callback(false, error)
        }

        let params = [
            Constants.Params.Keys.method: Constants.Params.Values.testLogin,
            Constants.Params.Keys.noJSONCallback: Constants.Params.Values.disableJSONCallback,
            Constants.Params.Keys.format: Constants.Params.Values.responseFormat
        ]

        guard let URL = FlickrApiClient.getTempOAuth().buildSHAEncryptedURL(for: .get, baseURL: baseURL, requestParameters: params) else {
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
                callback(true, nil)
            default:
                sendError(result.defaultErrorMessage()!)
            }
        }
    }

    // MARK: Private

    private static func getTempOAuth() -> FlickrOAuth {
        return FlickrOAuth(consumerKey: FlickrApplicationKey,
                           consumerSecret: FlickrApplicationSecret,
                           callbackURL: "")
    }

}

// MARK: - FlickrApiClient (Utility) -

extension FlickrApiClient {

    private func getBaseMethodParams(_ method: String? = nil) -> HttpMethodParams {
        var parameters = [
            Constants.Params.Keys.apiKey: Constants.Params.Values.apiKey,
            Constants.Params.Keys.format: Constants.Params.Values.responseFormat,
            Constants.Params.Keys.noJSONCallback: Constants.Params.Values.disableJSONCallback
        ]

        if let method = method {
            parameters[Constants.Params.Keys.method] = method
        }

        return parameters as HttpMethodParams
    }

    private func getBaseParamsForPhotosSearch() -> HttpMethodParams {
        var params = getBaseMethodParams(Constants.Params.Values.searchMethod)
        params[Constants.Params.Keys.extras] = "\(Constants.Params.Values.thumbnailURL),\(Constants.Params.Values.smallURL),\(Constants.Params.Values.mediumURL)"
        params[Constants.Params.Keys.contentType] = Constants.Params.Values.ContentType.photos.rawValue
        params[Constants.Params.Keys.safeSearch] = Constants.Params.Values.useSafeSearch
        params[Constants.Params.Keys.page] = 1
        params[Constants.Params.Keys.perPage] = Constants.Params.Values.perPageDefault

        return params
    }

    private func getParamsForPhotosSearch(for tags: [String]) -> HttpMethodParams {
        var params = getBaseParamsForPhotosSearch()
        params[Constants.Params.Keys.tags] = tags.joined(separator: ",")

        return params
    }

    private func checkFlickrResponse(_ json: JSONDictionary) -> Bool {
        guard let flickrStatus = json[Constants.Response.Keys.status] as? String,
            flickrStatus == Constants.Response.Values.okStatus else {
                return false
        }

        return true
    }

}
