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

// MARK: - ImageTaggerDataSourceViewController: UIViewController -

class ImageTaggerDataSourceViewController: UIViewController {
    
    // MARK: - Properties
    
    private var pickedImage: UIImage?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier.TagAnImage.rawValue {
            let navigationController = segue.destinationViewController as! UINavigationController
            let imageTaggerViewController = navigationController.topViewController as! ImageTaggerViewController
            imageTaggerViewController.taggingImage = pickedImage
        }
    }
    
    // MARK: - Actions
    
    @IBAction func selectImageFromFlickr(sender: AnyObject) {
        MIFlickr.sharedInstance.api.testLogin { (success, error) in
            if success {
                print("Success")
            } else {
                print(error!.localizedDescription)
            }
        }
        
//        MIFlickr.sharedInstance.OAuth.authorizeWithPermission(.Write) { result in
//            switch result {
//            case .Success(let token, let tokenSecret, let user):
//                print("TOKEN: \(token)\nTOKEN_SECRET: \(tokenSecret)\nUSER: \(user)")
//            case .Failure(let error):
//                print(error.localizedDescription)
//            }
//        }
    }
    
    @IBAction func selectImageFromDevice(sender: AnyObject) {
        MIImagePickerController.presentInViewController(self) { [unowned self] image in
            self.pickedImage = image
            self.performSegueWithIdentifier(SegueIdentifier.TagAnImage.rawValue, sender: self)
        }
    }
    
}
