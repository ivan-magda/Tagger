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
    case trends
    case categories
    
    enum TrendingTags: Int, CaseCountable {
        case today
        case week
        static let sectionTitle = "Trending Tags"
    }
    
    enum TagCategories {
        static let sectionTitle = "Categories"
    }
}

private enum SegueIdentifier: String {
    case TagCategoryDetail
}

// MARK: - DiscoverTagsViewController: UIViewController, Alertable -

class DiscoverTagsViewController: UIViewController, Alertable {
    
    // MARK: Outlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Properties
    
    var flickr: MIFlickr!
    var persistenceCentral: PersistenceCentral!
    
    fileprivate var categories: [Category] {
        get {
            return persistenceCentral.categories
        }
    }
    fileprivate var trendingCategories: [Category] {
        get {
            return persistenceCentral.trendingCategories
        }
    }
    fileprivate var imagesIsInLoading = Set<IndexPath>()
    
    fileprivate var numberOfColumns = 2
    fileprivate var maxNumberOfColumns = 3
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(flickr != nil && persistenceCentral != nil)
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setNavigationBarHidden(false)
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        numberOfColumns += (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 1 : -1)
        if numberOfColumns > maxNumberOfColumns {
            numberOfColumns = maxNumberOfColumns
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public
    
    @objc func reloadData() {
        collectionView.reloadData()
    }
    
    @objc func hideBarGesture(_ recognizer: UIPanGestureRecognizer) {
        updateNavigationBarBackgroundColor(hidden: navigationController!.isNavigationBarHidden)
    }
    
    // MARK: - Private
    
    fileprivate func setup() {
        configureUI()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: kPersistenceCentralDidChangeContentNotification), object: nil)
    }
    
}

// MARK: - DiscoverTagsViewController (UI Methods)  -

extension DiscoverTagsViewController {
    
    fileprivate func configureUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        guard let layout = collectionView!.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        layout.sectionInset = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        layout.minimumInteritemSpacing = 8.0
        layout.minimumLineSpacing = 8.0
        collectionView.contentInset.top += layout.sectionInset.top
    }
    
    fileprivate func updateTitleColorForCell(_ cell: TagCollectionViewCell) {
        cell.title.textColor = cell.imageView.image != nil ? .white : .black
    }
    
    // MARK: Navigation Controller
    
    fileprivate func configureNavigationController() {
        navigationController?.hidesBarsOnSwipe = true
        navigationController?.barHideOnSwipeGestureRecognizer.addTarget(self, action: #selector(hideBarGesture))
    }
    
    fileprivate func setNavigationBarHidden(_ hidden: Bool, animated: Bool = false) {
        navigationController?.setNavigationBarHidden(hidden, animated: animated)
        navigationController?.hidesBarsOnSwipe = hidden
        updateNavigationBarBackgroundColor(hidden: hidden)
    }
    
    fileprivate func updateNavigationBarBackgroundColor(hidden: Bool) {
        let color = hidden ? UIColor.white : UIColor.clear
        UIUtils.setStatusBarBackgroundColor(color)
    }
    
}

// MARK: - DiscoverTagsViewController: UICollectionViewDataSource -

extension DiscoverTagsViewController: UICollectionViewDataSource {
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return SectionType.countCases()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = SectionType(rawValue: section) else { return 0 }
        switch section {
        case .trends:
            return trendingCategories.count
        case .categories:
            return categories.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionViewCell.reuseIdentifier, for: indexPath) as! TagCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderCollectionReusableView.reuseIdentifier, for: indexPath) as! SectionHeaderCollectionReusableView
            configureSectionHeaderView(headerView, forIndexPath: indexPath)
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    // MARK: Helpers
    
    fileprivate func configureSectionHeaderView(_ view: SectionHeaderCollectionReusableView, forIndexPath indexPath: IndexPath) {
        switch SectionType(rawValue: indexPath.section)! {
        case .trends:
            view.title.text = SectionType.TrendingTags.sectionTitle.uppercased()
        case .categories:
            view.title.text = SectionType.TagCategories.sectionTitle.uppercased()
        }
    }
    
    fileprivate func configureCell(_ cell: TagCollectionViewCell, atIndexPath indexPath: IndexPath) {
        let category = categoryForIndexPath(indexPath)
        cell.title.text = category.name.lowercased()
        updateTitleColorForCell(cell)
        
        if let image = category.image?.image  {
            cell.imageView.image = image
            updateTitleColorForCell(cell)
        } else {
            guard imagesIsInLoading.contains(indexPath) == false else { return }
            imagesIsInLoading.insert(indexPath)
            loadImageForCellAtIndexPath(indexPath)
        }
    }
    
    fileprivate func categoryForIndexPath(_ indexPath: IndexPath) -> Category {
        return indexPath.section == SectionType.trends.rawValue
            ? trendingCategories[indexPath.row]
            : categories[indexPath.row]
    }
    
    // TODO: If network is unreachable, then don't try to download the image again.
    fileprivate func loadImageForCellAtIndexPath(_ indexPath: IndexPath) {
        func handleError(_ error: Error) {
            print("Failed to load an image. Error: \(error.localizedDescription)")
            setImage(nil, toCellAtIndexPath: indexPath)
            loadImageForCellAtIndexPath(indexPath)
            UIUtils.showNetworkActivityIndicator()
        }
        
        let category = categoryForIndexPath(indexPath)
        UIUtils.showNetworkActivityIndicator()
        
        if indexPath.section == SectionType.trends.rawValue {
            let period: Period = indexPath.row == SectionType.TrendingTags.today.rawValue ? .Day : .Week
            flickr.api.tagsHotListForPeriod(
                period,
                successBlock: {
                    self.flickr.api.randomImageFromTags(
                        $0.map { $0.content },
                        successBlock: { self.setImage($0, toCellAtIndexPath: indexPath) },
                        failBlock: handleError)
                },
                failBlock: handleError)
        } else {
            flickr.api.randomImageFromTags(
                [category.name],
                successBlock: { self.setImage($0, toCellAtIndexPath: indexPath) },
                failBlock: handleError
            )
        }
    }
    
    fileprivate func setImage(_ image: UIImage?, toCellAtIndexPath indexPath: IndexPath) {
        imagesIsInLoading.remove(indexPath)
        UIUtils.hideNetworkActivityIndicator()
        
        // Persist the image.
        if let image = image {
            persistenceCentral.setImage(image, toCategory: categoryForIndexPath(indexPath))
        }
        
        guard collectionView.indexPathsForVisibleItems.contains(indexPath) == true else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) as? TagCollectionViewCell else { return }
        
        cell.imageView.image = image
        updateTitleColorForCell(cell)
    }
    
}

// MARK: - DiscoverTagsViewController: UICollectionViewDelegateFlowLayout -

extension DiscoverTagsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize.zero
        }
        
        let sectionInsets = layout.sectionInset
        let minimumInteritemSpacing = layout.minimumInteritemSpacing
        
        let remainingWidth = collectionView.bounds.width
            - sectionInsets.left
            - CGFloat((numberOfColumns - 1)) * minimumInteritemSpacing
            - sectionInsets.right
        let width = floor(remainingWidth / CGFloat(numberOfColumns))
        
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard collectionView.numberOfItems(inSection: section) > 0 else { return CGSize.zero }
        return CGSize(width: collectionView.bounds.width, height: SectionHeaderCollectionReusableView.height)
    }
    
}

// MARK: - DiscoverTagsViewController: UICollectionViewDelegate -

extension DiscoverTagsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        let category = categoryForIndexPath(indexPath)
        let flickrApi = flickr.api
        
        switch SectionType(rawValue: indexPath.section)! {
        case .trends:
            let period = indexPath.row == 0 ? Period.Day : Period.Week
            let hotTagsViewController = FlickrHotTagsViewController(flickrApiClient: flickrApi, period: period, category: category)
            hotTagsViewController.persistenceCentral = persistenceCentral
            navigationController?.pushViewController(hotTagsViewController, animated: true)
        case .categories:
            let relatedTagsViewController = FlickrRelatedTagsViewController(flickrApiClient: flickr.api, category: category)
            relatedTagsViewController.persistenceCentral = persistenceCentral
            navigationController?.pushViewController(relatedTagsViewController, animated: true)
        }
    }
    
}
