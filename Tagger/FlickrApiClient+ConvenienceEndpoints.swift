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

typealias FlickrRequestFailCompletionHandler = (error: NSError) -> Void
typealias FlickrImageDownloadingSuccessCompletionHandler = (image: UIImage) -> Void
typealias FlickrTagsSuccessCompletionHandler = (tags: [Tag]) -> Void
typealias FlickrPhotosSearchSuccessCompletionHandler = (album: FlickrAlbum) -> Void

// MARK: - FlickrApiClient (Calling Api Endpoints)

extension FlickrApiClient {
    
    // MARK: - Public Methods -
    
    func loadImageData(url: NSURL, successBlock success: FlickrImageDownloadingSuccessCompletionHandler, failBlock fail: FlickrRequestFailCompletionHandler) {
        fetchRawData(NSURLRequest(URL: url)) { result in
            performOnMain {
                func sendError(error: String) {
                    self.debugLog("Error: \(error)")
                    let error = NSError(
                        domain: FlickrApiClient.Constants.Error.LoadImageErrorDomain,
                        code: FlickrApiClient.Constants.Error.LoadImageErrorCode,
                        userInfo: [NSLocalizedDescriptionKey : error]
                    )
                    fail(error: error)
                }
                
                switch result {
                case .Error(let error):
                    sendError(error.localizedDescription)
                case .RawData(let data):
                    guard let image = UIImage(data: data) else {
                        sendError("Could not initialize the image from the specified data.")
                        return
                    }
                    success(image: image)
                default:
                    sendError(result.defaultErrorMessage()!)
                }
            }
        }
    }
    
    // MARK: - Tags -
    // MARK: Public
    
    func getListHotTagsForPeriod(period: Period, numberOfTags count: Int = 20, successBlock success: FlickrTagsSuccessCompletionHandler, failBlock fail: FlickrRequestFailCompletionHandler) {
        var methodParameters = parametersWithMethodName(Constants.FlickrParameterValues.TagsHotList)
        methodParameters[Constants.FlickrParameterKeys.Period] = period.rawValue
        methodParameters[Constants.FlickrParameterKeys.Count] = count
        
        let keys = [Constants.FlickrResponseKeys.HotTags, Constants.FlickrResponseKeys.Tag]
        let request = NSURLRequest(URL: urlFromParameters(methodParameters))
        fetchCollection(request, rootKeys: keys, success: success, fail: fail)
    }
    
    // MARK: - Photos -
    // MARK: Public
    
    func searchPhotosWithTags(tags: [String], perpage: Int = 20, successBlock success: FlickrPhotosSearchSuccessCompletionHandler, failBlock fail: FlickrRequestFailCompletionHandler) {
        var methodParameters = parametersWithMethodName(Constants.FlickrParameterValues.SearchMethod)
        methodParameters[Constants.FlickrParameterKeys.Extras] = "\(Constants.FlickrParameterValues.ThumbnailURL),\(Constants.FlickrParameterValues.SmallURL),\(Constants.FlickrParameterValues.MediumURL)"
        methodParameters[Constants.FlickrParameterKeys.PerPage] = perpage
        methodParameters[Constants.FlickrParameterKeys.ContentType] = Constants.FlickrParameterValues.ContentType.Photos.rawValue
        methodParameters[Constants.FlickrParameterKeys.Tags] = tags.joinWithSeparator(",")
        searchPhotosWithParameters(methodParameters, successBlock: success, failBlock: fail)
    }
    
    func randomPhotoFromTags(tags: [String], successBlock success: FlickrImageDownloadingSuccessCompletionHandler, failBlock fail: FlickrRequestFailCompletionHandler) {
        searchPhotosWithTags(tags, perpage: 10, successBlock: { album in
            guard album.total > 0 else {
                fail(error: Constants.Error.EmptyResponseError)
                return
            }
            
            let idx = RandomNumberUtils.numberFromZeroTo(album.total > album.perpage ? album.perpage : album.total)
            
            guard let url = NSURL(string: album.photos[idx].urlSmall) else {
                fail(error: Constants.Error.DefaultError)
                return
            }
            self.loadImageData(url, successBlock: success, failBlock: fail)
            }, failBlock: fail)
    }
    
    // MARK: Private
    
    // TODO: param.count > 0, album.photos.count > 0
    private func searchPhotosWithParameters(param: MethodParameters, successBlock success: FlickrPhotosSearchSuccessCompletionHandler, failBlock fail: FlickrRequestFailCompletionHandler) {
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
