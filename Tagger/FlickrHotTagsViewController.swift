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

// MARK: FlickrHotTagsViewController: TagListViewController -

class FlickrHotTagsViewController: TagListViewController {
    
    // MARK: Properties
    
    var flickrApiClient: FlickrApiClient!
    
    private var period = Period.Day
    private var numberOfTags = 20
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchData()
    }
    
    // MARK: - Init
    
    convenience init(period: Period, flickrApiClient: FlickrApiClient) {
        self.init(nibName: TagListViewController.nibName, bundle: nil)
        self.period = period
        self.flickrApiClient = flickrApiClient
    }
    
    // MARK: - Private
    
    private func fetchData() {
        setUIState(.Downloading)
        flickrApiClient.tagsHotListForPeriod(period, numberOfTags: numberOfTags, successBlock: { [unowned self] tags in
            self.tags = tags
            self.setUIState(.SuccessDoneWithDownloading)
        }) { [unowned self] error in
            self.setUIState(.FailureDoneWithDownloading(error: error))
            let alert = self.alert("Error", message: error.localizedDescription, handler: nil)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}

// MARK: - FlickrHotTagsViewController (UI Functions) -

extension FlickrHotTagsViewController {
    private func configureUI() {
        actionSheet.addAction(UIAlertAction(title: "Number of Tags", style: .Default, handler: { [unowned self] action in
            CountPickerViewController.showPickerWithTitle("Number of Tags", rows: 200, initialSelection: self.numberOfTags-1, doneBlock: { (selectedIndex, selectedValue) in
                self.numberOfTags = selectedValue
                self.fetchData()
                }, cancelBlock: nil)
            }))
    }
}
