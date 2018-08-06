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

typealias IMImagePickerDidFinishPickingImageCompletionHandler = (_ image: UIImage) -> Swift.Void

// MARK: - IMImagePickerController: UIImagePickerController

final class IMImagePickerController: UIImagePickerController, Alertable {
    
    // MARK: - Instance Variables
    
    /// Controller in that image picker controller presenting.
    var rootViewController: UIViewController!
    
    /// Did finish picking image completion handler.
    var didFinishPickingImageHandler: IMImagePickerDidFinishPickingImageCompletionHandler!
    
    // MARK: - Public API
    
    class func present(in rootViewController: UIViewController,
                       then handler: @escaping IMImagePickerDidFinishPickingImageCompletionHandler) {
        let picker = IMImagePickerController()
        picker.rootViewController = rootViewController
        picker.didFinishPickingImageHandler = handler
        picker.delegate = picker
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            picker.getPhotoFromLibrary()
        })
        photoLibraryAction.setValue(UIImage(named: "iOS-photos")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        actionSheet.addAction(photoLibraryAction)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            picker.takePhoto()
        })
        takePhotoAction.setValue(UIImage(named: "compact-camera")?.withRenderingMode(.alwaysOriginal), forKey: "image")
        actionSheet.addAction(takePhotoAction)
        
        rootViewController.present(actionSheet, animated: true, completion: nil)
    }
    
}

// MARK: - IMImagePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate -

extension IMImagePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        onMain { [unowned self] in
            guard let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
                let alertViewController = self.alert("An error occured",
                                                     message: "Failed to select an image. Please, try again.",
                                                     handler: nil)
                self.rootViewController.present(alertViewController, animated: true, completion: nil)
                return
            }
            
            picker.dismiss(animated: true, completion: { [unowned self] in
                self.didFinishPickingImageHandler(pickedImage)
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Private Helpers
    
    /// Gets a photo from the library.
    private func getPhotoFromLibrary() {
        allowsEditing = false
        sourceType = .photoLibrary
        modalPresentationStyle = .fullScreen
        rootViewController.present(self, animated: true, completion: nil)
    }
    
    /// Takes a picture, checks if we have a camera first.
    private func takePhoto() {
        guard UIImagePickerController.availableCaptureModes(for: .rear) != nil else {
            noCameraAlert()
            return
        }
        
        allowsEditing = false
        sourceType = .camera
        cameraCaptureMode = .photo
        modalPresentationStyle = .fullScreen
        rootViewController.present(self, animated: true, completion: nil)
    }

    private func noCameraAlert() {
        let alert = UIAlertController(title: "No Camera",
                                      message: "Sorry, this device has no camera",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        rootViewController.present(alert, animated: true, completion: nil)
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
