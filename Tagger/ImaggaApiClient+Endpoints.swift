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

typealias ImaggaContentIdSuccessCompletionHandler = (contentId: String) -> Void
typealias ImaggaTaggingSuccessCompletionHandler = (tags: [ImaggaTag]) -> Void
typealias ImaggaFailCompletionHandler = (error: NSError) -> Void

// MARK: - ImaggaApiClient (Calling Api Endpoints)

extension ImaggaApiClient {
    
    // MARK: - API Endpoints -
    // MARK: Public
    
    func taggingImage(image: UIImage, successBlock success: ImaggaTaggingSuccessCompletionHandler, failBlock fail: ImaggaFailCompletionHandler) {
        uploadImage(image, successBlock: { [unowned self] contentId in
            self.taggingByContentId(contentId, successBlock: success, failBlock: fail)
            }, failBlock: fail)
    }
    
    // MARK: Private
    
    private func uploadImage(image: UIImage, successBlock success: ImaggaContentIdSuccessCompletionHandler, failBlock fail: ImaggaFailCompletionHandler) {
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            sendError("Could not get JPEG representation of selected image.", toBlock: fail)
            return
        }
        
        let boundary = generateBoundaryString()
        
        let request = NSMutableURLRequest(URL: urlFromParameters(nil, withPathExtension: ImaggaApiEndpoint.Content.rawValue))
        request.HTTPMethod = HttpMethod.POST.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = createMultipartBodyWithParameters(
            nil,
            files: [(data: imageData, name: "imagefile", fileName: "image.jpg")],
            boundary: boundary
        )
        
        fetchJsonForRequest(request) { [unowned self] result in
            if let error = self.checkApiClientResultForAnError(result) {
                fail(error: error)
                return
            }
            
            switch result {
            case .Json(let json):
                guard let status = json["status"] as? String where status == "success" else {
                    self.sendError(json["message"] as! String, toBlock: fail)
                    return
                }
                
                guard let uploaded = json["uploaded"] as? [JSONDictionary],
                    let fileId = uploaded.first?["id"] as? String else {
                        self.sendError("Invalid information received from service.", toBlock: fail)
                        return
                }
                
                self.debugLog("Content uploaded with ID: \(fileId)")
                success(contentId: fileId)
            default:
                self.sendError("An error occured. Please, try again.", toBlock: fail)
            }
        }
    }
    
    private func taggingByContentId(id: String, successBlock success: ImaggaTaggingSuccessCompletionHandler, failBlock fail: ImaggaFailCompletionHandler) {
        let url = urlFromParameters(["content": id], withPathExtension: ImaggaApiEndpoint.Tagging.rawValue)
        let request = NSURLRequest(URL: url)
        fetchJsonForRequest(request) { result in
            switch result {
            case .Json(let json):
                guard let results = json["results"] as? [JSONDictionary],
                    let tagsJson = results.first?["tags"] as? [JSONDictionary] else {
                        self.sendError("", toBlock: fail)
                        return
                }
                
                let tags = ImaggaTag.sanitezedTags(tagsJson)
                success(tags: tags)
            default:
                self.sendError("An error occured. Please, try again.", toBlock: fail)
            }
            
        }
    }
    
    // MARK: - Private Helpers
    
    private func sendError(error: String, toBlock failBlock: ImaggaFailCompletionHandler) {
        func sendError(error: String) {
            let error = NSError(domain: "\(BaseErrorDomain).ImaggaApiClient", code: 44, userInfo: [NSLocalizedDescriptionKey : error])
            failBlock(error: error)
        }
    }
    
}

