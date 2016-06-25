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

// MARK: FlickrCameraRollCollectionViewController: UICollectionViewController

class FlickrCameraRollCollectionViewController: UICollectionViewController {
    
    // MARK: Properties
    
    private var numberOfColumns = 3
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        numberOfColumns += (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 1 : -1)
        collectionView!.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(FlickrCameraRollCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! FlickrCameraRollCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    private func configureCell(cell: FlickrCameraRollCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print(#function + "\(indexPath.row)")
    }
    
    // MARK: Actions
    
    func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

// MARK: - FlickrCameraRollCollectionViewController (UI Functions)  -

extension FlickrCameraRollCollectionViewController {
    
    private func configureUI() {
        title = "Camera Roll"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(cancel))
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
