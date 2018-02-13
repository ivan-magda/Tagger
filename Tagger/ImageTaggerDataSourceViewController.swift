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

private enum SegueIdentifier: String {
    case TagAnImage
}

// MARK: - ImageTaggerDataSourceViewController: UIViewController, Alertable -

class ImageTaggerDataSourceViewController: UIViewController, Alertable {
    
    // MARK: - Properties
    
    var flickr: MIFlickr!
    var persistenceCentral: PersistenceCentral!
    
    fileprivate var pickedImage: UIImage?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(flickr != nil && persistenceCentral != nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.TagAnImage.rawValue {
            let navigationController = segue.destination as! UINavigationController
            let imageTaggerViewController = navigationController.topViewController as! ImageTaggerViewController
            imageTaggerViewController.taggingImage = pickedImage
            imageTaggerViewController.persistenceCentral = persistenceCentral
        }
    }
    
    // MARK: - Actions
    
    @IBAction func selectImageFromFlickr(_ sender: AnyObject) {
        if let _ = flickr.currentUser {
            presentFlickrUserCameraRoll()
        } else {
            let alert = UIAlertController(title: "You are not logged in", message: "If you want select photo from your Flickr account, then sign in your account.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign In", style: .default) { action in
                self.flickrAuth()
            })
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func selectImageFromDevice(_ sender: AnyObject) {
        MIImagePickerController.presentInViewController(self, withDidFinishPickingImageBlock: processOnPickedImage)
    }
    
    // MARK: - Private
    
    fileprivate func flickrAuth() {
        UIUtils.showNetworkActivityIndicator()
        
        flickr.OAuth.authorizeWithPermission(.Write) { [unowned self] result in
            UIUtils.hideNetworkActivityIndicator()
            switch result {
            case .success(let token, let tokenSecret, let user):
                print("TOKEN: \(token)\nTOKEN_SECRET: \(tokenSecret)\nUSER: \(user)")
                self.flickr.currentUser = user
                self.presentFlickrUserCameraRoll()
            case .failure(let error):
                let alert = self.alert("Error", message: error.localizedDescription, handler: nil)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func processOnPickedImage(_ image: UIImage) {
        pickedImage = image
        performSegue(withIdentifier: SegueIdentifier.TagAnImage.rawValue, sender: self)
    }
    
    fileprivate func presentFlickrUserCameraRoll() {
        FlickrCameraRollCollectionViewController.presentInViewController(self, flickr: flickr, didFinishPickingImage: processOnPickedImage)
    }
    
}
