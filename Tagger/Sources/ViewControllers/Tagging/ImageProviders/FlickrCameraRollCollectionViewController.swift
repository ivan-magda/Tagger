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

// MARK: Typealiases

typealias FlickrCameraRollDidPickImageCompletionHandler = (_ image: UIImage) -> Void

// MARK: - FlickrCameraRollCollectionViewController: UICollectionViewController, Alertable

final class FlickrCameraRollCollectionViewController: UICollectionViewController, Alertable {
    
    // MARK: Instance Variables
    
    var flickr: IMFlickr!
    
    /// Did finish picking image completion handler.
    var didFinishPickingImageBlock: FlickrCameraRollDidPickImageCompletionHandler?
    
    private var photos = [FlickrPhoto]()
    private var images = [String: UIImage]()
    private var loadingSet = Set<IndexPath>()
    
    private var numberOfColumns = 3
    private let maxNumberOfColumns = 4
    
    // MARK: UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(flickr != nil)
        
        setup()
        fetchData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        flickr.api.cancelAll()
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        numberOfColumns += (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 1 : -1)

        if numberOfColumns > maxNumberOfColumns {
            numberOfColumns = maxNumberOfColumns
        }

        collectionView!.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: Public API
    
    static func show(in viewController: UIViewController,
                    flickr: IMFlickr,
                    then callback: @escaping FlickrCameraRollDidPickImageCompletionHandler) {
        let cameraRollVC = FlickrCameraRollCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
        cameraRollVC.flickr = flickr
        cameraRollVC.didFinishPickingImageBlock = callback

        let navigationVC = UINavigationController(rootViewController: cameraRollVC)
        viewController.present(navigationVC, animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    @objc private func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - FlickrCameraRollCollectionViewController (Setup)  -

extension FlickrCameraRollCollectionViewController {
    
    private func setup() {
        title = "Camera Roll"

        let selector = #selector(
            ((FlickrCameraRollCollectionViewController.dismiss) as
                (FlickrCameraRollCollectionViewController) -> () -> Void)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: selector
        )

        setupCollectionView()
    }
    
    private func setupCollectionView() {
        collectionView!.register(FlickrCameraRollCollectionViewCell.self,
                                 forCellWithReuseIdentifier: FlickrCameraRollCollectionViewCell.reuseIdentifier)
        collectionView!.backgroundColor = .white

        if let layout = collectionView!.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets.zero
            layout.minimumInteritemSpacing = 1.0
            layout.minimumLineSpacing = 1.0

            if #available(iOS 11.0, *) {
                layout.sectionInsetReference = .fromSafeArea
            }
        }
    }
    
}

// MARK: - FlickrCameraRollCollectionViewController (Networking) -

extension FlickrCameraRollCollectionViewController {

    // TODO: Currently presents 500 user photos. Need add ability to present next photos page.
    private func fetchData() {
        UIUtils.showNetworkActivityIndicator()

        flickr.api.getUserPhotos(flickr.currentUser!, success: { [weak self] photos in
            UIUtils.hideNetworkActivityIndicator()
            self?.photos = photos
            self?.collectionView?.reloadData()
        }) { [weak self] error in
            UIUtils.hideNetworkActivityIndicator()
            let alert = self?.alert("Error", message: error.localizedDescription, handler: nil)
            self?.present(alert!, animated: true, completion: nil)
        }
    }

    private func load(_ photo: FlickrPhoto,
                      at indexPath: IndexPath,
                      into cell: FlickrCameraRollCollectionViewCell) {
        guard loadingSet.contains(indexPath) == false else { return }
        loadingSet.insert(indexPath)

        guard let URL = URL(string: photo.urlSmall) else { return }
        cell.activityIndicator.startAnimating()

        flickr.api.getImage(
            for: URL,
            success: { [weak self] image in
                self?.set(image: image, at: indexPath)
            },
            failure: { [weak self] error in
                self?.set(image: nil, at: indexPath)
                print("Failed to load an image. Error: \(error.localizedDescription)")
            }
        )
    }

}

// MARK: - FlickrCameraRollCollectionViewController (UICollectionViewDelegate) -

extension FlickrCameraRollCollectionViewController {

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dismiss()
        didFinishPickingImageBlock?(images[photos[indexPath.row].id]!)
    }

}

// MARK: - FlickrCameraRollCollectionViewController (UICollectionViewDataSource) -

extension FlickrCameraRollCollectionViewController {

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: FlickrCameraRollCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 willDisplay cell: UICollectionViewCell,
                                 forItemAt indexPath: IndexPath) {
        configure(cell: cell as! FlickrCameraRollCollectionViewCell, at: indexPath)
    }

    // MARK: Private Helpers

    private func configure(cell: FlickrCameraRollCollectionViewCell,
                           at indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        if let image = images[photo.id] {
            cell.photoImageView.image = image
            return
        }

        load(photo, at: indexPath, into: cell)
    }

    private func set(image: UIImage?, at indexPath: IndexPath) {
        loadingSet.remove(indexPath)

        guard collectionView!.indexPathsForVisibleItems.contains(indexPath) == true else { return }
        guard let cell = collectionView!.cellForItem(at: indexPath) as? FlickrCameraRollCollectionViewCell else { return }

        cell.activityIndicator.stopAnimating()
        cell.photoImageView.image = image

        images[photos[indexPath.row].id] = image
    }

}

// MARK: - FlickrCameraRollCollectionViewController: UICollectionViewDelegateFlowLayout -

extension FlickrCameraRollCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize.zero
        }

        var collectionViewWidth = collectionView.bounds.width

        if #available(iOS 11.0, *) {
            let insets = collectionView.safeAreaInsets
            collectionViewWidth -= (insets.left + insets.right)
        }

        let sectionInsets = layout.sectionInset
        let minimumInteritemSpacing = layout.minimumInteritemSpacing
        
        let remainingWidth = collectionViewWidth
            - sectionInsets.left
            - CGFloat((numberOfColumns - 1)) * minimumInteritemSpacing
            - sectionInsets.right
        let width = floor(remainingWidth / CGFloat(numberOfColumns))
        
        return CGSize(width: width, height: width)
    }
    
}
