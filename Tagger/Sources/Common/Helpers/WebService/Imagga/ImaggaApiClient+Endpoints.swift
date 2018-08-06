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

private enum Endpoint: String {
    case Tagging = "/tagging"
    case Content = "/content"
    case Categorizations = "/categorizations"
}

// MARK: - Typealiases

typealias ImaggaContentIdSuccessCompletionHandler = (_ contentId: String) -> Void
typealias ImaggaTaggingSuccessCompletionHandler = (_ tags: [ImaggaTag]) -> Void
typealias ImaggaFailureCompletionHandler = (_ error: Error) -> Void

// MARK: - ImaggaApiClient (Calling Api Endpoints)

extension ImaggaApiClient {

    // MARK: Public API
    
    func taggingImage(_ image: UIImage,
                      success: @escaping ImaggaTaggingSuccessCompletionHandler,
                      failure: @escaping ImaggaFailureCompletionHandler) {
        uploadImage(image, success: { [unowned self] contentId in
            self.tagging(by: contentId, success: success, failure: failure)
            }, failure: failure)
    }
    
    // MARK: Private

    private static let maxImageSize: CGFloat = 500
    
    private func uploadImage(_ image: UIImage,
                             success: @escaping ImaggaContentIdSuccessCompletionHandler,
                             failure: @escaping ImaggaFailureCompletionHandler) {
        let compression: CGFloat = (image.size.height > ImaggaApiClient.maxImageSize ||
            image.size.width > ImaggaApiClient.maxImageSize) ? 0.5 : 0.9

        guard let data = image.jpegData(compressionQuality: compression) else {
            onFailure(with: "Could not get JPEG representation of selected image.",
                      callback: failure)
            return
        }
        
        let boundary = generateBoundaryString()

        let request = NSMutableURLRequest(url: url(from: nil, withPathExtension: Endpoint.Content.rawValue))
        request.httpMethod = HttpMethod.post.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createMultipartBody(
            params: nil,
            files: [(data: data, name: Constants.Params.Keys.imageFile, fileName: "image.jpg")],
            boundary: boundary
        )
        
        fetchJson(for: request as URLRequest) { [unowned self] result in
            if let error = self.isContainsError(result: result) {
                failure(error)
                return
            }
            
            switch result {
            case .json(let json):
                guard let status = json[Constants.Response.Keys.status] as? String,
                    status == Constants.Response.Values.successStatus else {
                    self.onFailure(with: json[Constants.Response.Keys.message] as! String,
                                   callback: failure)
                    return
                }
                
                guard let uploaded = json[Constants.Response.Keys.uploaded] as? [JSONDictionary],
                    let fileId = uploaded.first?[Constants.Response.Keys.id] as? String else {
                        self.onFailure(with: "Invalid information received from service.",
                                       callback: failure)
                        return
                }

                self.log("Content uploaded with ID: \(fileId)")
                success(fileId)
            default:
                self.onFailure(with: "An error occured. Please, try again.",
                               callback: failure)
            }
        }
    }
    
    private func tagging(by id: String,
                         success: @escaping ImaggaTaggingSuccessCompletionHandler,
                         failure: @escaping ImaggaFailureCompletionHandler) {
        let URL = url(from: [Constants.Params.Keys.content: id],
                      withPathExtension: Endpoint.Tagging.rawValue)
        let request = URLRequest(url: URL)

        fetchJson(for: request) { [unowned self] result in
            switch result {
            case .json(let json):
                guard let results = json[Constants.Response.Keys.results] as? [JSONDictionary],
                    let tagsJson = results.first?[Constants.Response.Keys.tags] as? [JSONDictionary] else {
                        self.onFailure(with: "An error occured. Failed to tag your image",
                                       callback: failure)
                        return
                }
                
                let tags = ImaggaTag.sanitezedTags(tagsJson)
                success(tags)
            default:
                self.onFailure(with: "An error occured. Please, try again.",
                               callback: failure)
            }
        }
    }

}

// MARK: - ImaggaApiClient (Private Helpers) -

extension ImaggaApiClient {

    private func onFailure(with error: String,
                           callback: @escaping ImaggaFailureCompletionHandler) {
        func sendError(_ error: String) {
            let error = NSError(
                domain: "\(Tagger.Constants.Error.baseDomain).ImaggaApiClient",
                code: 44,
                userInfo: [NSLocalizedDescriptionKey : error]
            )
            callback(error)
        }
    }

}
