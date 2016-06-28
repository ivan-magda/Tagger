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

import UIKit

// MARK: FlickrRelatedTagsViewController: TagListViewController -

class FlickrRelatedTagsViewController: TagListViewController {
    
    // MARK: Properties
    
    private (set) var flickrApiClient: FlickrApiClient!
    private (set) var tag: String!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(flickrApiClient != nil && tag != nil)
        
        configureUI()
        fetchData()
    }
    
    // MARK: - Init
    
    convenience init(flickrApiClient: FlickrApiClient, tag: String) {
        self.init(nibName: TagListViewController.nibName, bundle: nil)
        self.flickrApiClient = flickrApiClient
        self.tag = tag
    }
    
    // MARK: - Private
    
    private func configureUI() {
        title = tag.capitalizedString
    }
    
    private func fetchData() {
        setUIState(.Downloading)
        flickrApiClient.relatedTagsForTag(tag, successBlock: { [unowned self] tags in
            self.tags = tags
            self.setUIState(.SuccessDoneWithDownloading)
        }) { [unowned self] error in
            self.setUIState(.FailureDoneWithDownloading(error: error))
            let alert = self.alert("Error", message: error.localizedDescription, handler: nil)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}
