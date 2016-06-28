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

typealias FlickrCameraRollDidPickImageCompletionHandler = (image: UIImage) -> Void

// MARK: - FlickrCameraRollCollectionViewController: UICollectionViewController, Alertable

class FlickrCameraRollCollectionViewController: UICollectionViewController, Alertable {
    
    // MARK: Properties
    
    var flickr: MIFlickr!
    
    /// Did finish picking image completion handler.
    var didFinishPickingImageBlock: FlickrCameraRollDidPickImageCompletionHandler?
    
    private var photos = [FlickrPhoto]()
    private var images = [String: UIImage]()
    private var imagesIsInLoading = Set<NSIndexPath>()
    
    private var numberOfColumns = 3
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(flickr != nil)
        
        configureUI()
        fetchData()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        numberOfColumns += (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 1 : -1)
        collectionView!.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: Presenting
    
    class func presentInViewController(viewController: UIViewController, flickr: MIFlickr, didFinishPickingImage block: FlickrCameraRollDidPickImageCompletionHandler) {
        let flowLayout = UICollectionViewFlowLayout()
        let cameraRollViewController = FlickrCameraRollCollectionViewController(collectionViewLayout: flowLayout)
        cameraRollViewController.flickr = flickr
        cameraRollViewController.didFinishPickingImageBlock = block
        let navigationController = UINavigationController(rootViewController: cameraRollViewController)
        viewController.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(FlickrCameraRollCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! FlickrCameraRollCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    private func configureCell(cell: FlickrCameraRollCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        func failedToLoadImageWithError(error: NSError) {
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
        
        guard let URL = NSURL(string: photo.urlSmall) else { return }
        cell.activityIndicator.startAnimating()
        
        flickr.api.downloadImageWithURL(URL, successBlock: { [unowned self] image in
            self.setImage(image, toCellAtIndexPath: indexPath)
            }, failBlock: failedToLoadImageWithError)
    }
    
    private func setImage(image: UIImage?, toCellAtIndexPath indexPath: NSIndexPath) {
        imagesIsInLoading.remove(indexPath)
        
        guard collectionView!.indexPathsForVisibleItems().contains(indexPath) == true else { return }
        guard let cell = collectionView!.cellForItemAtIndexPath(indexPath) as? FlickrCameraRollCollectionViewCell else { return }
        
        cell.activityIndicator.stopAnimating()
        cell.photoImageView.image = image
        images[photos[indexPath.row].id] = image
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        dismiss()
        didFinishPickingImageBlock?(image: images[photos[indexPath.row].id]!)
    }
    
    // MARK: Actions
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Private
    
    // TODO: Currently presents 500 user photos. Need add ability to present next photos page.
    private func fetchData() {
        UIUtils.showNetworkActivityIndicator()
        
        flickr.api.getUserPhotos(flickr.currentUser!, success: { [unowned self] photos in
            UIUtils.hideNetworkActivityIndicator()
            self.photos = photos
            self.collectionView?.reloadData()
        }) { [unowned self] error in
            UIUtils.hideNetworkActivityIndicator()
            let alert = self.alert("Error", message: error.localizedDescription, handler: nil)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}

// MARK: - FlickrCameraRollCollectionViewController (UI Functions)  -

extension FlickrCameraRollCollectionViewController {
    
    private func configureUI() {
        title = "Camera Roll"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(dismiss))
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        collectionView!.registerClass(FlickrCameraRollCollectionViewCell.self, forCellWithReuseIdentifier: FlickrCameraRollCollectionViewCell.reuseIdentifier)
        collectionView!.backgroundColor = .whiteColor()
        if let layout = collectionView!.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsetsZero
            layout.minimumInteritemSpacing = 1.0
            layout.minimumLineSpacing = 1.0
        }
    }
    
}

// MARK: - FlickrCameraRollCollectionViewController: UICollectionViewDelegateFlowLayout -

extension FlickrCameraRollCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSizeZero
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
