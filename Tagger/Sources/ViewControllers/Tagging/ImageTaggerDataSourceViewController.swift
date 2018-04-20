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
    case tagAnImage = "TagAnImage"
}

// MARK: - ImageTaggerDataSourceViewController: UIViewController, Alertable -

final class ImageTaggerDataSourceViewController: UIViewController, Alertable {

    // MARK: - Instance Variables
    
    var flickr: IMFlickr!
    var persistenceCentral: PersistenceCentral!
    
    private var pickedImage: UIImage?

    private var rootView: ImageTaggerDataSourceView {
        get {
            return self.view as! ImageTaggerDataSourceView
        }
    }
    
    // MARK: - UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(flickr != nil && persistenceCentral != nil)

        rootView.scrollView.alwaysBounceVertical = true

        for view in rootView.stackView.subviews {
            guard let button = view as? UIButton else { continue }
            button.imageView?.contentMode = .scaleAspectFit
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateConstraints()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.updateConstraints()
        }, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.tagAnImage.rawValue {
            let navigationController = segue.destination as! UINavigationController
            let imageTaggerViewController = navigationController.topViewController as! ImageTaggerViewController
            imageTaggerViewController.taggingImage = pickedImage
            imageTaggerViewController.persistenceCentral = persistenceCentral
        }
    }
    
}

// MARK: - ImageTaggerDataSourceViewController (Actions) -

extension ImageTaggerDataSourceViewController {

    @IBAction func selectImageFromFlickr(_ sender: AnyObject) {
        if let _ = flickr.currentUser {
            presentFlickrUserCameraRoll()
        } else {
            let alert = UIAlertController(title: "You are not logged in",
                                          message: "If you want select photo from your Flickr account, then sign in your account.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Sign In", style: .default) { action in
                self.flickrAuth()
            })

            present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func selectImageFromDevice(_ sender: AnyObject) {
        IMImagePickerController.present(in: self, then: processOnPickedImage)
    }

}

// MARK: - ImageTaggerDataSourceViewController (Private Helpers) -

extension ImageTaggerDataSourceViewController {

    private func flickrAuth() {
        UIUtils.showNetworkActivityIndicator()

        flickr.OAuth.auth(with: .write) { [unowned self] result in
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

    private func processOnPickedImage(_ image: UIImage) {
        pickedImage = image
        performSegue(withIdentifier: SegueIdentifier.tagAnImage.rawValue, sender: self)
    }

    private func presentFlickrUserCameraRoll() {
        FlickrCameraRollCollectionViewController.show(in: self,
                                                      flickr: flickr,
                                                      then: processOnPickedImage)
    }

}

// MARK: - ImageTaggerDataSourceViewController (UI) -

extension ImageTaggerDataSourceViewController {

    private func updateConstraints() {
        if UIDevice.current.orientation.isLandscape {
            rootView.messageViewTopConstraint.constant = ImageTaggerDataSourceView.defaultMessageViewTopConstant
            rootView.stackViewTopConstraint.constant = ImageTaggerDataSourceView.smallStackViewVerticalSpacingConstant
        } else {
            rootView.stackViewTopConstraint.constant = ImageTaggerDataSourceView.defaultStackViewVerticalSpacingConstant

            let contentHeight = round(rootView.messageView.bounds.height)
                + round(rootView.stackView.bounds.height)
                + rootView.stackViewTopConstraint.constant
            rootView.messageViewTopConstraint.constant = round(rootView.scrollView.bounds.height / 2.0)
                - round(contentHeight / 2.0)
        }
    }

}
