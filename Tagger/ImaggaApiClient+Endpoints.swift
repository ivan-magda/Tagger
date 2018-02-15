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

private enum ImaggaApiEndpoint: String {
    case Tagging = "/tagging"
    case Content = "/content"
    case Categorizations = "/categorizations"
}

// MARK: - Typealiases

typealias ImaggaContentIdSuccessCompletionHandler = (_ contentId: String) -> Void
typealias ImaggaTaggingSuccessCompletionHandler = (_ tags: [ImaggaTag]) -> Void
typealias ImaggaFailCompletionHandler = (_ error: Error) -> Void

// MARK: - ImaggaApiClient (Calling Api Endpoints)

extension ImaggaApiClient {
    
    // MARK: - API Endpoints -
    // MARK: Public
    
    func taggingImage(_ image: UIImage, successBlock success: @escaping ImaggaTaggingSuccessCompletionHandler, failBlock fail: @escaping ImaggaFailCompletionHandler) {
        uploadImage(image, successBlock: { [unowned self] contentId in
            self.taggingByContentId(contentId, successBlock: success, failBlock: fail)
            }, failBlock: fail)
    }
    
    // MARK: Private
    
    fileprivate func uploadImage(_ image: UIImage, successBlock success: @escaping ImaggaContentIdSuccessCompletionHandler, failBlock fail: @escaping ImaggaFailCompletionHandler) {
        let compression: CGFloat = (image.size.height > 500 || image.size.width > 500 ? 0.5 : 0.9)
        guard let imageData = UIImageJPEGRepresentation(image, compression) else {
            sendError("Could not get JPEG representation of selected image.", toBlock: fail)
            return
        }
        
        let boundary = generateBoundaryString()

        let request = NSMutableURLRequest(url: url(from: nil, withPathExtension: ImaggaApiEndpoint.Content.rawValue))
        request.httpMethod = HttpMethod.post.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createMultipartBodyWithParameters(
            nil,
            files: [(data: imageData, name: Constants.ParameterKeys.ImageFile, fileName: "image.jpg")],
            boundary: boundary
        )
        
        fetchJsonForRequest(request as URLRequest) { [unowned self] result in
            if let error = self.checkApiClientResultForAnError(result) {
                fail(error)
                return
            }
            
            switch result {
            case .json(let json):
                guard let status = json[Constants.ResponseKeys.Status] as? String, status == Constants.ResponseValues.SuccessStatus else {
                    self.sendError(json[Constants.ResponseKeys.Message] as! String, toBlock: fail)
                    return
                }
                
                guard let uploaded = json[Constants.ResponseKeys.Uploaded] as? [JSONDictionary],
                    let fileId = uploaded.first?[Constants.ResponseKeys.ID] as? String else {
                        self.sendError("Invalid information received from service.", toBlock: fail)
                        return
                }
                
                self.log("Content uploaded with ID: \(fileId)")
                success(fileId)
            default:
                self.sendError("An error occured. Please, try again.", toBlock: fail)
            }
        }
    }
    
    fileprivate func taggingByContentId(_ id: String, successBlock success: @escaping ImaggaTaggingSuccessCompletionHandler, failBlock fail: @escaping ImaggaFailCompletionHandler) {
        let URL = url(from: [Constants.ParameterKeys.Content: id], withPathExtension: ImaggaApiEndpoint.Tagging.rawValue)
        let request = URLRequest(url: URL)
        fetchJsonForRequest(request) { result in
            switch result {
            case .json(let json):
                guard let results = json[Constants.ResponseKeys.Results] as? [JSONDictionary],
                    let tagsJson = results.first?[Constants.ResponseKeys.Tags] as? [JSONDictionary] else {
                        self.sendError("", toBlock: fail)
                        return
                }
                
                let tags = ImaggaTag.sanitezedTags(tagsJson)
                success(tags)
            default:
                self.sendError("An error occured. Please, try again.", toBlock: fail)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    fileprivate func sendError(_ error: String, toBlock failBlock: @escaping ImaggaFailCompletionHandler) {
        func sendError(_ error: String) {
            let error = NSError(
                domain: "\(BaseErrorDomain).ImaggaApiClient",
                code: 44,
                userInfo: [NSLocalizedDescriptionKey : error]
            )
            failBlock(error)
        }
    }
    
}
