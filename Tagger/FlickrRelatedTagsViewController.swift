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

// MARK: FlickrRelatedTagsViewController: TagListViewController -

final class FlickrRelatedTagsViewController: TagListViewController {
    
    // MARK: Instance Variables
    
    private (set) var flickrApiClient: FlickrApiClient!
    private let refreshControl = UIRefreshControl()
    
    // MARK: - UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(flickrApiClient != nil && category != nil)
        setup()
    }
    
    // MARK: - Init
    
    convenience init(flickrApiClient: FlickrApiClient, category: Category) {
        self.init(nibName: TagListViewController.nibName, bundle: nil)
        self.flickrApiClient = flickrApiClient
        self.category = category
    }
    
}

// MARK: - FlickrRelatedTagsViewController (Networking) -

extension FlickrRelatedTagsViewController {

    @objc private func fetchData() {
        setUIState(.downloading)

        flickrApiClient.getRelatedTags(
            for: category!.name,
            success: { [weak self] tags in
                guard let strongSelf = self else { return }
                strongSelf.refreshControl.endRefreshing()

                strongSelf.persistenceCentral.deleteTags(in: strongSelf.category!)
                let manager = strongSelf.persistenceCentral.coreDataStackManager

                let mappedTags = FlickrTag.map(on: tags,
                                               with: strongSelf.category!,
                                               in: manager.managedObjectContext)
                manager.saveContext()
                strongSelf.tags = mappedTags

                strongSelf.setUIState(.successDoneWithDownloading)
        }) { [weak self] error in
            guard let strongSelf = self else { return }

            strongSelf.refreshControl.endRefreshing()
            strongSelf.setUIState(.failureDoneWithDownloading(error: error))
            let alert = strongSelf.alert("Error", message: error.localizedDescription,
                                         handler: nil)
            strongSelf.present(alert, animated: true, completion: nil)
        }
    }

}

// MARK: - FlickrRelatedTagsViewController (Private Helpers) -

extension FlickrRelatedTagsViewController {

    private func setup() {
        configureUI()
        if tags.count == 0 {
            fetchData()
        }
    }

    private func configureUI() {
        title = category!.name.capitalized
        refreshControl.addTarget(self, action: #selector(fetchData), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
}
