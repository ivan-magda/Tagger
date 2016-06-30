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
import CoreData

// MARK: FlickrHotTagsViewController: TagListViewController -

class FlickrHotTagsViewController: TagListViewController {
    
    // MARK: Properties
    
    var flickrApiClient: FlickrApiClient!
    
    private var period = Period.Day
    private var numberOfTags = 20
    
    private let refreshControl = UIRefreshControl()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(flickrApiClient != nil && parentCategory != nil)
        setup()
    }
    
    // MARK: - Init
    
    convenience init(flickrApiClient: FlickrApiClient, period: Period, category: Category) {
        self.init(nibName: TagListViewController.nibName, bundle: nil)
        self.flickrApiClient = flickrApiClient
        self.period = period
        self.parentCategory = category
    }
    
    // MARK: - Private
    
    private func setup() {
        configureUI()
        if tags.count == 0 {
            fetchData()
        }
    }
    
    func fetchData() {
        setUIState(.Downloading)
        flickrApiClient.tagsHotListForPeriod(
            period,
            numberOfTags: numberOfTags,
            successBlock: { [weak self] tags in
                guard let strongSelf = self else { return }
                strongSelf.refreshControl.endRefreshing()
                
                strongSelf.persistenceCentral.deleteAllTagsInCategory(strongSelf.parentCategory!)
                let manager = strongSelf.persistenceCentral.coreDataStackManager
                
                let mappedTags = FlickrTag.mapFlickrTags(tags,
                    withParentCategory: strongSelf.parentCategory!,
                    toTagsInContext: manager.managedObjectContext
                )
                manager.saveContext()
                strongSelf.tags = mappedTags
                
                strongSelf.setUIState(.SuccessDoneWithDownloading)
        }) { [weak self] error in
            self?.refreshControl.endRefreshing()
            self?.setUIState(.FailureDoneWithDownloading(error: error))
            let alert = self?.alert("Error", message: error.localizedDescription, handler: nil)
            self?.presentViewController(alert!, animated: true, completion: nil)
        }
    }
}

// MARK: - FlickrHotTagsViewController (UI Functions) -

extension FlickrHotTagsViewController {
    
    private func configureUI() {
        refreshControl.addTarget(self, action: #selector(fetchData), forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
        
        actionSheet.addAction(UIAlertAction(title: "Number of Tags", style: .Default, handler: { _ in
            CountPickerViewController.showPickerWithTitle(
                "Number of Tags",
                rows: 200,
                initialSelection: self.numberOfTags-1,
                doneBlock: { (_, selectedValue) in
                    self.numberOfTags = selectedValue
                    self.fetchData() },
                cancelBlock: nil
            )
        }))
    }
}
