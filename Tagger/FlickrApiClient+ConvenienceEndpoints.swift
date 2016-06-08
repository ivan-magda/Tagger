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

typealias FlickrImageDownloadingCompletionHandler = (image: UIImage?, error: NSError?) -> Void

typealias FlickrTagSuccessCompletionHandler = [Tag] -> Void
typealias FlickrTagFailCompletionHandler = NSError -> Void

typealias FlickrPhotosSearchSuccessBlock = (album: FlickrAlbum) -> Void
typealias FlickrPhotosSearchFailBlock = (error: NSError) -> Void

// MARK: - FlickrApiClient (Calling Api Endpoints)

extension FlickrApiClient {
    
    // MARK: - Public Methods -
    
    func loadImageData(url: NSURL, completionHandler: FlickrImageDownloadingCompletionHandler) {
        fetchRawData(NSURLRequest(URL: url)) { result in
            performOnMain {
                func sendError(error: String) {
                    self.debugLog("Error: \(error)")
                    let error = NSError(
                        domain: FlickrApiClient.Constants.Error.LoadImageErrorDomain,
                        code: FlickrApiClient.Constants.Error.LoadImageErrorCode,
                        userInfo: [NSLocalizedDescriptionKey : error]
                    )
                    completionHandler(image: nil, error: error)
                }
                
                switch result {
                case .Error(let error):
                    sendError(error.localizedDescription)
                case .RawData(let data):
                    completionHandler(image: UIImage(data: data), error: nil)
                default:
                    sendError(result.defaultErrorMessage()!)
                }
            }
        }
    }
    
    // MARK: - Tags -
    // MARK: Public
    
    func getListHotTagsForPeriod(period: Period, numberOfTags count: Int = 20, withSuccessBlock success: FlickrTagSuccessCompletionHandler, failBlock fail: FlickrTagFailCompletionHandler) {
        var methodParameters = parametersWithMethodName(Constants.FlickrParameterValues.TagsHotList)
        methodParameters[Constants.FlickrParameterKeys.Period] = period.rawValue
        methodParameters[Constants.FlickrParameterKeys.Count] = count
        
        let keys = [Constants.FlickrResponseKeys.HotTags, Constants.FlickrResponseKeys.Tag]
        let request = NSURLRequest(URL: urlFromParameters(methodParameters))
        fetchCollection(request, rootKeys: keys, success: success, fail: fail)
    }
    
    // MARK: - Photos -
    // MARK: Public
    
    func searchPhotosWithTags(tags: [String], doneWithSuccess success: FlickrPhotosSearchSuccessBlock, failBlock fail: FlickrPhotosSearchFailBlock) {
        var methodParameters = parametersWithMethodName(Constants.FlickrParameterValues.SearchMethod)
        methodParameters[Constants.FlickrParameterKeys.Extras] = "\(Constants.FlickrParameterValues.ThumbnailURL),\(Constants.FlickrParameterValues.SmallURL),\(Constants.FlickrParameterValues.MediumURL)"
        methodParameters[Constants.FlickrParameterKeys.PerPage] = 20
        methodParameters[Constants.FlickrParameterKeys.ContentType] = Constants.FlickrParameterValues.ContentType.Photos.rawValue
        methodParameters[Constants.FlickrParameterKeys.Tags] = tags.joinWithSeparator(",")
        searchPhotosWithParameters(methodParameters, doneWithSuccess: success, failBlock: fail)
    }
    
    // MARK: Private
    
    private func searchPhotosWithParameters(param: MethodParameters, doneWithSuccess success: FlickrPhotosSearchSuccessBlock, failBlock fail: FlickrPhotosSearchFailBlock) {
        let request = NSURLRequest(URL: urlFromParameters(param))
        fetchResource(request, success: { (album: FlickrAlbum) in
            performOnMain {
                success(album: album)
            }
        }) { error in
            performOnMain {
                fail(error: error)
            }
        }
    }
    
    // MARK: - Private Helpers -
    
    private func parametersWithMethodName(method: String) -> MethodParameters {
        var parameters = getBaseMethodParameters()
        parameters[Constants.FlickrParameterKeys.Method] = method
        return parameters
    }
    
    private func checkFlickrResponse(json: JSONDictionary) -> Bool {
        guard let flickrStatus = json[Constants.FlickrResponseKeys.Status] as? String where flickrStatus == Constants.FlickrResponseValues.OKStatus else {
            return false
        }
        return true
    }
    
}
