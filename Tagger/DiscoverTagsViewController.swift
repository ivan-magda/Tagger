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

// MARK: Types

private enum SectionType: Int, CaseCountable {
    
    case Trends
    case Categories
    
    enum TrendsTagHeader: Int, CaseCountable {
        case Today, Week
        
        static var tagValues: [String] = {
            return ["now", "this week"]
        }()
    }
    
}

// MARK: - DiscoverTagsViewController: UIViewController -

class DiscoverTagsViewController: UIViewController {
    
    // MARK: Outlets

    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Properties
    
    private let defaultTagCategories = [
        "art", "light", "park", "winter", "sun", "clouds", "family", "new", "macro", "summer"
    ]
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }

}

// MARK: - DiscoverTagsViewController: UICollectionViewDataSource -

extension DiscoverTagsViewController: UICollectionViewDataSource {
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return SectionType.countCases()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = SectionType(rawValue: section) else { return 0 }
        switch section {
        case .Trends:
            return SectionType.TrendsTagHeader.caseCount
        case .Categories:
            return defaultTagCategories.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TagCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! TagCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    // MARK: Helpers
    
    private func configureCell(cell: TagCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let section = SectionType(rawValue: indexPath.section) else { return }
        switch section {
        case .Trends:
            configureTrendTagCell(cell, forRow: indexPath.row)
        case .Categories:
            configureCategoryTagCell(cell, forRow: indexPath.row)
        }
    }
    
    private func configureTrendTagCell(cell: TagCollectionViewCell, forRow row: Int) {
        cell.title.text = SectionType.TrendsTagHeader.tagValues[row]
    }
    
    private func configureCategoryTagCell(cell: TagCollectionViewCell, forRow row: Int) {
        cell.title.text = defaultTagCategories[row]
    }
    
}

// MARK: - DiscoverTagsViewController: UICollectionViewDelegate -

extension DiscoverTagsViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("Did select item at index: \(indexPath.row)")
    }
    
}
