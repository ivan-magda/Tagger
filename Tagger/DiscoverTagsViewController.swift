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
    
    enum TrendingTags: Int, CaseCountable {
        case Today, Week
        
        static let sectionTitle = "Trending Tags"
        static let tags = ["now", "this week"]
    }
    
    enum UserCategories {
        static let sectionTitle = "Categories"
    }
    
}

private enum SegueIdentifier: String {
    case TagCategoryDetail
}

// MARK: - DiscoverTagsViewController: UIViewController -

class DiscoverTagsViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Properties
    
    private let flickrApiClient = FlickrApiClient.sharedInstance
    private var numberOfColumns = 2
    private let defaultTagCategories = [
        "art", "light", "park", "winter", "sun", "clouds", "family", "new", "macro", "summer"
    ]
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        numberOfColumns += (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 1 : -1)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
}

// MARK: - DiscoverTagsViewController (UI Methods)  -

extension DiscoverTagsViewController {
    
    private func configureUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Add extra top content inset to a collection view.
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
            let delegateFlowLayout = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
            let sectionInset = delegateFlowLayout.collectionView?(collectionView, layout: flowLayout, insetForSectionAtIndex: SectionType.Trends.rawValue)
            collectionView.contentInset.top += sectionInset?.top ?? 0.0
        }
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
            return SectionType.TrendingTags.caseCount
        case .Categories:
            return defaultTagCategories.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TagCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! TagCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: SectionHeaderCollectionReusableView.reuseIdentifier, forIndexPath: indexPath) as! SectionHeaderCollectionReusableView
            configureSectionHeaderView(headerView, forIndexPath: indexPath)
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
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
        cell.title.text = SectionType.TrendingTags.tags[row]
    }
    
    private func configureCategoryTagCell(cell: TagCollectionViewCell, forRow row: Int) {
        cell.title.text = defaultTagCategories[row]
    }
    
    private func configureSectionHeaderView(view: SectionHeaderCollectionReusableView, forIndexPath indexPath: NSIndexPath) {
        guard let section = SectionType(rawValue: indexPath.section) else { return }
        switch section {
        case .Trends:
            view.title.text = SectionType.TrendingTags.sectionTitle
        case .Categories:
            view.title.text = SectionType.UserCategories.sectionTitle
        }
    }
    
}

// MARK: - DiscoverTagsViewController: UICollectionViewDelegateFlowLayout -

extension DiscoverTagsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
            let delegateFlowLayout = collectionView.delegate as? UICollectionViewDelegateFlowLayout else {
                return CGSizeZero
        }
        
        let sectionInset = delegateFlowLayout.collectionView!(collectionView, layout: layout, insetForSectionAtIndex: indexPath.section)
        let minimumInteritemSpacing = layout.minimumInteritemSpacing
        
        let remainingWidth = collectionView.bounds.width - sectionInset.left - CGFloat((numberOfColumns - 1)) * minimumInteritemSpacing - sectionInset.right
        let width = floor(remainingWidth / CGFloat(numberOfColumns))
        
        return CGSize(width: width, height: width)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard collectionView.numberOfItemsInSection(section) > 0 else { return CGSizeZero }
        return CGSize(width: collectionView.bounds.width, height: SectionHeaderCollectionReusableView.height)
    }
    
}

// MARK: - DiscoverTagsViewController: UICollectionViewDelegate -

extension DiscoverTagsViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
        switch indexPath.section {
        case SectionType.Trends.rawValue:
            let period = indexPath.row == 0 ? Period.Day : Period.Week
            let hotTagsViewController = FlickrHotTagsViewController(period: period, flickrApiClient: flickrApiClient)
            hotTagsViewController.title = SectionType.TrendingTags.tags[indexPath.row].capitalizedString
            navigationController?.pushViewController(hotTagsViewController, animated: true)
        case SectionType.Categories.rawValue:
            let tagListViewController = TagListViewController()
            tagListViewController.title = defaultTagCategories[indexPath.row].capitalizedString
            navigationController?.pushViewController(tagListViewController, animated: true)
        default:
            break
        }
    }
    
}
