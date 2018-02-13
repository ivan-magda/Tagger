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

class FlickrCameraRollCollectionViewController: UICollectionViewController, Alertable {
    
    // MARK: Properties
    
    var flickr: MIFlickr!
    
    /// Did finish picking image completion handler.
    var didFinishPickingImageBlock: FlickrCameraRollDidPickImageCompletionHandler?
    
    fileprivate var photos = [FlickrPhoto]()
    fileprivate var images = [String: UIImage]()
    fileprivate var imagesIsInLoading = Set<IndexPath>()
    
    fileprivate var numberOfColumns = 3
    fileprivate let maxNumberOfColumns = 4
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(flickr != nil)
        
        configureUI()
        fetchData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        flickr.api.cancelAllRequests()
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        numberOfColumns += (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 1 : -1)
        if numberOfColumns > maxNumberOfColumns {
            numberOfColumns = maxNumberOfColumns
        }
        collectionView!.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: Presenting
    
    class func presentInViewController(_ viewController: UIViewController, flickr: MIFlickr, didFinishPickingImage block: @escaping FlickrCameraRollDidPickImageCompletionHandler) {
        let flowLayout = UICollectionViewFlowLayout()
        let cameraRollViewController = FlickrCameraRollCollectionViewController(collectionViewLayout: flowLayout)
        cameraRollViewController.flickr = flickr
        cameraRollViewController.didFinishPickingImageBlock = block
        let navigationController = UINavigationController(rootViewController: cameraRollViewController)
        viewController.present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FlickrCameraRollCollectionViewCell.reuseIdentifier, for: indexPath) as! FlickrCameraRollCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    fileprivate func configureCell(_ cell: FlickrCameraRollCollectionViewCell, atIndexPath indexPath: IndexPath) {
        func failedToLoadImageWithError(_ error: Error) {
            setImage(nil, toCellAtIndexPath: indexPath)
            print("Failed to load an image. Error: \(error.localizedDescription)")
        }
        
        let photo = photos[indexPath.row]
        if let image = images[photo.id] {
            cell.photoImageView.image = image
            return
        }
        
        guard imagesIsInLoading.contains(indexPath) == false else { return }
        imagesIsInLoading.insert(indexPath)
        
        guard let URL = URL(string: photo.urlSmall) else { return }
        cell.activityIndicator.startAnimating()
        
        flickr.api.downloadImageWithURL(URL, successBlock: { [weak self] image in
            self?.setImage(image, toCellAtIndexPath: indexPath)
            }, failBlock: failedToLoadImageWithError)
    }
    
    fileprivate func setImage(_ image: UIImage?, toCellAtIndexPath indexPath: IndexPath) {
        imagesIsInLoading.remove(indexPath)
        
        guard collectionView!.indexPathsForVisibleItems.contains(indexPath) == true else { return }
        guard let cell = collectionView!.cellForItem(at: indexPath) as? FlickrCameraRollCollectionViewCell else { return }
        
        cell.activityIndicator.stopAnimating()
        cell.photoImageView.image = image
        images[photos[indexPath.row].id] = image
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dismiss()
        didFinishPickingImageBlock?(images[photos[indexPath.row].id]!)
    }
    
    // MARK: Actions
    
    @objc func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Private
    
    // TODO: Currently presents 500 user photos. Need add ability to present next photos page.
    fileprivate func fetchData() {
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
    
}

// MARK: - FlickrCameraRollCollectionViewController (UI Functions)  -

extension FlickrCameraRollCollectionViewController {
    
    fileprivate func configureUI() {
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
    
    fileprivate func setupCollectionView() {
        collectionView!.register(FlickrCameraRollCollectionViewCell.self, forCellWithReuseIdentifier: FlickrCameraRollCollectionViewCell.reuseIdentifier)
        collectionView!.backgroundColor = .white
        if let layout = collectionView!.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets.zero
            layout.minimumInteritemSpacing = 1.0
            layout.minimumLineSpacing = 1.0
        }
    }
    
}

// MARK: - FlickrCameraRollCollectionViewController: UICollectionViewDelegateFlowLayout -

extension FlickrCameraRollCollectionViewController: UICollectionViewDelegateFlowLayout {
    
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
    
}
