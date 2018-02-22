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
    case tagCategoryDetail = "TagCategoryDetail"
}

// MARK: - DiscoverTagsViewController: UIViewController, Alertable -

final class DiscoverTagsViewController: UIViewController, Alertable {
    
    // MARK: IBOutlets
    
    @IBOutlet var collectionView: UICollectionView!
    
    // MARK: Instance Variables
    
    var flickr: IMFlickr!
    var persistenceCentral: PersistenceCentral!
    
    private var categories: [Category] {
        get {
            return persistenceCentral.categories
        }
    }

    private var trendingCategories: [Category] {
        get {
            return persistenceCentral.trendingCategories
        }
    }

    private var imagesLoadingSet = Set<IndexPath>()
    
    private var numberOfColumns = 2
    private var maxNumberOfColumns = 3
    
    // MARK: - UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(flickr != nil && persistenceCentral != nil)
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationController()
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
    
    // MARK: - Private
    
    private func setup() {
        setupUI()

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(reloadData),
                         name: NSNotification.Name(rawValue: persistenceCentralDidChangeContentNotification),
                         object: nil)
    }
    
}

// MARK: - DiscoverTagsViewController (Actions) -

extension DiscoverTagsViewController {

    @objc private func reloadData() {
        collectionView.reloadData()
    }

    @objc private func hideBarGesture(_ recognizer: UIPanGestureRecognizer) {
        updateNavigationBarBackgroundColor(hidden: navigationController!.isNavigationBarHidden)
    }

}

// MARK: - DiscoverTagsViewController (UI)  -

extension DiscoverTagsViewController {
    
    private func setupUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        guard let layout = collectionView!.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        layout.sectionInset = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        layout.minimumInteritemSpacing = 8.0
        layout.minimumLineSpacing = 8.0
        collectionView.contentInset.top += layout.sectionInset.top
    }
    
    private func updateTitleColor(for cell: TagCollectionViewCell) {
        cell.title.textColor = cell.imageView.image != nil ? .white : .black
    }
    
    // MARK: UINavigationController
    
    private func setupNavigationController() {
        navigationController?.hidesBarsOnSwipe = true
        navigationController?.barHideOnSwipeGestureRecognizer.addTarget(self, action: #selector(hideBarGesture))
    }
    
    private func setNavigationBarHidden(_ hidden: Bool, animated: Bool = false) {
        navigationController?.setNavigationBarHidden(hidden, animated: animated)
        navigationController?.hidesBarsOnSwipe = hidden
        updateNavigationBarBackgroundColor(hidden: hidden)
    }
    
    private func updateNavigationBarBackgroundColor(hidden: Bool) {
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
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TagCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as! TagCollectionViewCell
        configureCell(cell, at: indexPath)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SectionHeaderCollectionReusableView.reuseIdentifier,
                for: indexPath
            ) as! SectionHeaderCollectionReusableView
            configureSectionHeaderView(headerView, at: indexPath)

            return headerView
        default:
            fatalError("Unexpected element kind")
        }
    }
    
    // MARK: Private Helpers
    
    private func configureSectionHeaderView(_ view: SectionHeaderCollectionReusableView,
                                            at indexPath: IndexPath) {
        switch SectionType(rawValue: indexPath.section)! {
        case .trends:
            view.title.text = SectionType.TrendingTags.sectionTitle.uppercased()
        case .categories:
            view.title.text = SectionType.TagCategories.sectionTitle.uppercased()
        }
    }
    
    private func configureCell(_ cell: TagCollectionViewCell, at indexPath: IndexPath) {
        let category = getCategory(for: indexPath)
        cell.title.text = category.name.lowercased()
        updateTitleColor(for: cell)
        
        if let image = category.image?.image  {
            cell.imageView.image = image
            updateTitleColor(for: cell)
        } else {
            guard imagesLoadingSet.contains(indexPath) == false else { return }
            imagesLoadingSet.insert(indexPath)
            loadImageForCell(at: indexPath)
        }
    }
    
    private func getCategory(for indexPath: IndexPath) -> Category {
        return indexPath.section == SectionType.trends.rawValue
            ? trendingCategories[indexPath.row]
            : categories[indexPath.row]
    }
    
    // TODO: If network is unreachable, then don't try to download the image again.
    private func loadImageForCell(at indexPath: IndexPath) {
        func handleError(_ error: Error) {
            print("Failed to load an image. Error: \(error.localizedDescription)")
            setImage(nil, toCellAtIndexPath: indexPath)
            loadImageForCell(at: indexPath)
            UIUtils.showNetworkActivityIndicator()
        }
        
        let category = getCategory(for: indexPath)
        UIUtils.showNetworkActivityIndicator()
        
        if indexPath.section == SectionType.trends.rawValue {
            let period: Period = indexPath.row == SectionType.TrendingTags.today.rawValue ? .day : .week
            flickr.api.getTagsHotList(
                for: period,
                success: {
                    self.flickr.api.getRandomPhoto(
                        for: $0.map { $0.content },
                        success: { self.setImage($0, toCellAtIndexPath: indexPath) },
                        failure: handleError)
                },
                failure: handleError)
        } else {
            flickr.api.getRandomPhoto(
                for: [category.name],
                success: { self.setImage($0, toCellAtIndexPath: indexPath) },
                failure: handleError
            )
        }
    }
    
    private func setImage(_ image: UIImage?, toCellAtIndexPath indexPath: IndexPath) {
        imagesLoadingSet.remove(indexPath)
        UIUtils.hideNetworkActivityIndicator()
        
        // Persist the image.
        if let image = image {
            persistenceCentral.setImage(image, to: getCategory(for: indexPath))
        }
        
        guard collectionView.indexPathsForVisibleItems.contains(indexPath) == true else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) as? TagCollectionViewCell else { return }
        
        cell.imageView.image = image
        updateTitleColor(for: cell)
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
        
        let category = getCategory(for: indexPath)
        let flickrApi = flickr.api
        
        switch SectionType(rawValue: indexPath.section)! {
        case .trends:
            let period = indexPath.row == 0 ? Period.day : Period.week
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
