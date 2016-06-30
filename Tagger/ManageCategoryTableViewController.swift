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

let kManageCategoryTableViewControllerDidDoneOnCategoryNotification = "ManageCategoryTableViewControllerDidDoneOnCategory"

// MARK: ManageCategoryTableViewController: UITableViewController, Alertable

class ManageCategoryTableViewController: UITableViewController, Alertable {
    
    // MARK: Outlets
    
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    
    // MARK: Properties
    
    var persistenceCentral: PersistenceCentral!
    var category: Category?
    
    private var name = String()
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(persistenceCentral != nil)
        setup()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        textField.resignFirstResponder()
    }
    
    // MARK: Actions
    
    @IBAction func cancelDidPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doneDidPressed(sender: AnyObject) {
        textField.resignFirstResponder()
        
        name = name.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
        if category != nil {
            editCategory()
        } else {
            createCategory()
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(kManageCategoryTableViewControllerDidDoneOnCategoryNotification, object: nil)
    }
    
    // MARK: Private
    
    private func setup() {
        configureUI()
        textField.delegate = self
    }
    
    private func shouldDoneOnCategory() -> Bool {
        guard let category = category else {
            return true
        }
        return name != category.name
    }
    
    private func createCategory() {
        persistenceCentral.saveCategoryWithName(name)
        
        let alert = self.alert("Success", message: "Category created") { _ in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func editCategory() {
        let manager = persistenceCentral.coreDataStackManager
        
        category!.name = name
        if let image = category!.image {
            manager.managedObjectContext.deleteObject(image)
        }
        manager.saveContext()
        
        let alert = self.alert("Success", message: "Category edited", handler: { _ in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        presentViewController(alert, animated: true, completion: nil)
    }
    
}

// MARK: - ManageCategoryTableViewController (UI Functions) -

extension ManageCategoryTableViewController {
    
    private func configureUI() {
        if let category = category {
            title = "Edit Category"
            textField.text = category.name
            name = category.name
        } else {
            title = "Add Category"
        }
        updateDoneButtonEnabledState()
    }
    
    private func updateDoneButtonEnabledState() {
        doneBarButtonItem.enabled = name.characters.count > 0 && shouldDoneOnCategory()
    }
    
}

// MARK: - ManageCategoryTableViewController: UITextFieldDelegate -

extension ManageCategoryTableViewController: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        name = (textField.text ?? "" as NSString).stringByReplacingCharactersInRange(range, withString: string)
        updateDoneButtonEnabledState()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        name = textField.text ?? ""
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if shouldDoneOnCategory() {
            doneDidPressed(textField)
            return true
        }
        return false
    }
    
}
