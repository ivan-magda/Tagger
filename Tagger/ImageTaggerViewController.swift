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
import CoreData

// MARK: Types

private enum UIState {
    case Default
    case Networking
    case DoneWithNetworking
}

// MARK: - ImageTaggerViewController: UIViewController, Alertable

class ImageTaggerViewController: UIViewController, Alertable {
    
    // MARK: - Properties
    
    var taggingImage: UIImage!
    var persistenceCentral: PersistenceCentral!
    
    private let imaggaApiClient = ImaggaApiClient.sharedInstance
    
    private var generatedTags: [ImaggaTag]?
    private var createdCategory: Category?
    private lazy var temporaryContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistenceCentral.coreDataStackManager.persistentStoreCoordinator
        return context
    }()
    
    // MARK: Outlets
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var generateBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var resultsBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveResultsBarButtonItem: UIBarButtonItem!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(taggingImage != nil && persistenceCentral != nil)
        configureUI()
    }
    
    // MARK: - Actions
    
    @IBAction func cancelDidPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func generateTags(sender: AnyObject) {
        setUIState(.Networking)
        imaggaApiClient.taggingImage(taggingImage, successBlock: { [weak self] tags in
            self?.processOnGeneratedTags(tags)
        }) { [weak self] error in
            self?.generatedTags = nil
            self?.setUIState(.DoneWithNetworking)
            let alert = self?.alert("Error", message: error.localizedDescription, handler: nil)
            self?.presentViewController(alert!, animated: true, completion: nil)
        }
    }
    
    @IBAction func showResults(sender: AnyObject) {
        let tagListViewController = TagListViewController(persistenceCentral: persistenceCentral)
        
        if let createdCategory = createdCategory {
            tagListViewController.parentCategory = createdCategory
        } else {
            tagListViewController.title = "Results"
            tagListViewController.tags = ImaggaTag.mapImaggaTags(generatedTags!,
                                                                 toTagsInContext: temporaryContext)
        }
        navigationController?.pushViewController(tagListViewController, animated: true)
    }
    
    @IBAction func saveResults(sender: AnyObject) {
        func showInvalidNameAlert() {
            let alert = self.alert("Invalid category name", message: "Try again", handler: { [unowned self] in
                self.saveResults($0)
            })
            presentViewController(alert, animated: true, completion: nil)
        }
        
        var categoryNameTextField: UITextField?
        
        let alert = UIAlertController(title: "Create Category", message: "To save the tags, please enter the category name.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { [unowned self] _ in
            guard let name = categoryNameTextField?.text where name.characters.count > 0 else {
                showInvalidNameAlert()
                return
            }
            self.createCategoryWithName(name)
        }))
        alert.addTextFieldWithConfigurationHandler { textField in
            categoryNameTextField = textField
            categoryNameTextField?.placeholder = "Enter category name"
        }
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Private
    
    private func processOnGeneratedTags(tags: [ImaggaTag]) {
        generatedTags = tags
        setUIState(.DoneWithNetworking)
        
        let alert = UIAlertController(title: "Success", message: "Tags successfully generated. Do you want save or see them?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .Default) { [unowned self]  _ in
            self.saveResults(self)
        })
        alert.addAction(UIAlertAction(title: "See Results", style: .Default) { [unowned self]  _ in
            self.showResults(self)
        })
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func createCategoryWithName(name: String) {
        let name = name.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
        let manager = persistenceCentral.coreDataStackManager
        let context = manager.managedObjectContext
        
        let category = Category(name: name, context: context)
        ImaggaTag.mapImaggaTags(generatedTags!, withParentCategory: category, toTagsInContext: context)
        manager.saveContext()
        
        createdCategory = category
        
        saveResultsBarButtonItem.enabled = false
        showResults(self)
    }
}

// MARK: - ImageTaggerViewController (UI Functions) -

extension ImageTaggerViewController {
    
    private func configureUI() {
        setUIState(.Default)
        navigationController?.view.backgroundColor = .whiteColor()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
    }
    
    private func setUIState(state: UIState) {
        func updateResultsButtonState() {
            let enabled = generatedTags != nil && generatedTags?.count > 0
            resultsBarButtonItem.enabled = enabled
            saveResultsBarButtonItem.enabled = enabled
        }
        
        switch state {
        case .Default:
            imageView.image = taggingImage
            resultsBarButtonItem.enabled = false
            saveResultsBarButtonItem.enabled = false
        case .Networking:
            UIUtils.showNetworkActivityIndicator()
            activityIndicator.startAnimating()
            resultsBarButtonItem.enabled = false
            generateBarButtonItem.enabled = false
            saveResultsBarButtonItem.enabled = false
        case .DoneWithNetworking:
            UIUtils.hideNetworkActivityIndicator()
            activityIndicator.stopAnimating()
            generateBarButtonItem.enabled = true
            updateResultsButtonState()
        }
    }
}
