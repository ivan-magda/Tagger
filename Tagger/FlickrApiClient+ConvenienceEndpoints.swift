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

// MARK: Typealiases

typealias FlickPhotoTaskCompletionHandler = (album: JSONDictionary?, photos: [JSONDictionary]?, error: NSError?) -> Void
typealias FlickrImageDownloadingCompletionHandler = (imageData: NSData?, error: NSError?) -> Void

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
                    completionHandler(imageData: nil, error: error)
                }
                
                switch result {
                case .Error(let error):
                    sendError(error.localizedDescription)
                case .RawData(let data):
                    completionHandler(imageData: data, error: nil)
                default:
                    sendError(result.defaultErrorMessage()!)
                }
            }
        }
    }
    
    // MARK: - Tags -
    // MARK: Public
    
    func getWeekTagsHotList(success: [Tag] -> Void, fail: NSError -> Void) {
        getTagsHotListForPeriod(Constants.FlickrParameterValues.WeekPeriod, success: success, fail: fail)
    }
    
    func getTodayTagsHotList(success: [Tag] -> Void, fail: NSError -> Void) {
        getTagsHotListForPeriod(Constants.FlickrParameterValues.DayPeriod, success: success, fail: fail)
    }
    
    // MARK: Private
    
    private func getTagsHotListForPeriod(period: String, numberOfTags count: Int = 20, success: [Tag] -> Void, fail: NSError -> Void) {
        var methodParameters = getBaseMethodParameters()
        methodParameters[Constants.FlickrParameterKeys.Method] = Constants.FlickrParameterValues.TagsHotList
        methodParameters[Constants.FlickrParameterKeys.Period] = period
        methodParameters[Constants.FlickrParameterKeys.Count] = count
        
        let keys = [Constants.FlickrResponseKeys.HotTags, Constants.FlickrResponseKeys.Tag]
        
        let request = NSURLRequest(URL: urlFromParameters(methodParameters))
        fetchCollection(request, rootKeys: keys, success: success, fail: fail)
    }
    
    // MARK: - Photos -
    // MARK: Public
    
    /// Returns number of pages for a photo search.
    func getNumberOfPagesForFlickrPhotoSearch(completionHandler: (Int, NSError?) -> Void) {
        var methodParameters = getBaseMethodParameters()
        methodParameters[Constants.FlickrParameterKeys.Method] = Constants.FlickrParameterValues.SearchMethod
        let request = NSURLRequest(URL: urlFromParameters(methodParameters))
        
        fetchJson(request) { [unowned self] apiClientResult in
            performOnMain {
                func sendError(error: String) {
                    self.debugLog("Error: \(error)")
                    let error = NSError(
                        domain: FlickrApiClient.Constants.Error.NumberOfPagesForPhotoSearchErrorDomain,
                        code: FlickrApiClient.Constants.Error.NumberOfPagesForPhotoSearchErrorCode,
                        userInfo: [NSLocalizedDescriptionKey : error]
                    )
                    completionHandler(0, error)
                }
                
                switch apiClientResult {
                case .Error(let error):
                    sendError(error.localizedDescription)
                case .Json(let json):
                    guard self.checkFlickrStatusFromJson(json) == true else {
                        sendError("Flick API returned an error.")
                        return
                    }
                    
                    guard let photosDictionary = json[Constants.FlickrResponseKeys.Photos] as? JSONDictionary,
                        let numberOfPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                            sendError("Could't parse recieved JSON object.")
                            return
                    }
                    
                    completionHandler(numberOfPages, nil)
                default:
                    sendError(apiClientResult.defaultErrorMessage()!)
                }
            }
        }
    }
    
    // MARK: Private
    
    private func fetchPhotosWithMethodParameters(param: MethodParameters, completionHandler: FlickPhotoTaskCompletionHandler) {
        func sendError(error: String) {
            debugLog("Error: \(error)")
            let error = NSError(
                domain: FlickrApiClient.Constants.Error.FetchPhotosErrorDomain,
                code: FlickrApiClient.Constants.Error.FetchPhotosErrorCode,
                userInfo: [NSLocalizedDescriptionKey : error]
            )
            completionHandler(album: nil, photos: nil, error: error)
        }
        
        let request = NSURLRequest(URL: urlFromParameters(param))
        fetchJson(request) { apiClientResult in
            performOnMain {
                switch apiClientResult {
                case .Error(let error):
                    sendError(error.localizedDescription)
                case .Json(let json):
                    // GUARD: Did Flickr return an error?
                    guard let flickrStatus = json[Constants.FlickrResponseKeys.Status] as? String where flickrStatus == Constants.FlickrResponseValues.OKStatus else {
                        sendError("Flick API returned an error.")
                        return
                    }
                    
                    // GUARD: Are the "photos" and "photo" keys in our result.
                    guard let photosDictionary = json[Constants.FlickrResponseKeys.Photos] as? JSONDictionary,
                        let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [JSONDictionary] else {
                            sendError("Cannot find 'photos' or 'photo' keys!")
                            return
                    }
                    
                    guard photoArray.count > 0 else {
                        sendError("No photo found. Try again.")
                        return
                    }
                    
                    var albumDictionary = JSONDictionary()
                    albumDictionary[Constants.FlickrResponseKeys.Page] = photosDictionary[Constants.FlickrParameterKeys.Page]
                    albumDictionary[Constants.FlickrResponseKeys.Pages] = photosDictionary[Constants.FlickrResponseKeys.Pages]
                    albumDictionary[Constants.FlickrResponseKeys.PerPage] = photosDictionary[Constants.FlickrResponseKeys.PerPage]
                    albumDictionary[Constants.FlickrResponseKeys.Total] = photosDictionary[Constants.FlickrResponseKeys.Total]
                    
                    completionHandler(album: albumDictionary, photos: photoArray, error: nil)
                default:
                    sendError(apiClientResult.defaultErrorMessage()!)
                }
            }
        }
    }
    
    // MARK: - Private Helpers -
    
    private func checkFlickrStatusFromJson(json: JSONDictionary) -> Bool {
        guard let flickrStatus = json[Constants.FlickrResponseKeys.Status] as? String where flickrStatus == Constants.FlickrResponseValues.OKStatus else {
            return false
        }
        return true
    }

}