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

// MARK: Typealias

typealias MIImagePickerDidFinishPickingImageCompletionHandler = (image: UIImage) -> Void

// MARK: - MIImagePickerController: UIImagePickerController

class MIImagePickerController: UIImagePickerController, Alertable {
    
    // MARK: - Properties
    
    /// Controller in that image picker controller presenting.
    var rootViewController: UIViewController!
    
    /// Did finish picking image completion handler.
    var didFinishPickingImageBlock: MIImagePickerDidFinishPickingImageCompletionHandler!
    
    // MARK: - Presenting
    
    class func presentInViewController(rootViewController: UIViewController, withDidFinishPickingImageBlock block: MIImagePickerDidFinishPickingImageCompletionHandler) {
        let picker = MIImagePickerController()
        picker.rootViewController = rootViewController
        picker.didFinishPickingImageBlock = block
        picker.delegate = picker
        
        let actionSheet = UIAlertController(title: "From where select an image?", message: "Choose an action.", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .Default, handler: { _ in
            picker.photoFromLibrary()
        })
        photoLibraryAction.setValue(UIImage(named: "iOS-photos")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        actionSheet.addAction(photoLibraryAction)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default, handler: { _ in
            picker.takePhoto()
        })
        takePhotoAction.setValue(UIImage(named: "compact-camera")?.imageWithRenderingMode(.AlwaysOriginal), forKey: "image")
        actionSheet.addAction(takePhotoAction)
        
        rootViewController.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
}

// MARK: - MIImagePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate -

extension MIImagePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        performOnMain { [unowned self] in
            guard let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                let alertViewController = self.alert("An error occured", message: "Failed to select an image. Please, try again.", handler: nil)
                self.rootViewController.presentViewController(alertViewController, animated: true, completion: nil)
                return
            }
            
            picker.dismissViewControllerAnimated(true, completion: { [unowned self] in
                self.didFinishPickingImageBlock(image: pickedImage)
            })
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Private Helper Methods
    
    private func noCameraAlert() {
        let alert = UIAlertController(title: "No Camera", message: "Sorry, this device has no camera", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        rootViewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    /// Get a photo from the library.
    func photoFromLibrary() {
        allowsEditing = false
        sourceType = .PhotoLibrary
        modalPresentationStyle = .FullScreen
        rootViewController.presentViewController(self, animated: true, completion: nil)
    }
    
    /// Take a picture, check if we have a camera first.
    func takePhoto() {
        guard UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil else {
            noCameraAlert()
            return
        }
        
        allowsEditing = false
        sourceType = .Camera
        cameraCaptureMode = .Photo
        modalPresentationStyle = .FullScreen
        rootViewController.presentViewController(self, animated: true, completion: nil)
    }
    
}
