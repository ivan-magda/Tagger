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

typealias CountPickerDoneBlock = (selectedIndex: Int, selectedValue: Int) -> Void
typealias CountPickerCancelBlock = () -> Void

// MARK: - Constants

private let kNibName = "CountPickerViewController"

// MARK: - CountPickerViewController: UIViewController

@IBDesignable
class CountPickerViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // MARK: Properties
    
    var initialSelection = 0
    var numberOfRows = 20
    
    private var selectedRowIdx = 0
    private var selectedValue: Int {
        get {
            return selectedRowIdx + 1
        }
    }
    
    private var doneBlock: CountPickerDoneBlock?
    private var cancelBlock: CountPickerCancelBlock?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setup()
    }
    
    // MARK: - Init
    
    convenience init() {
        self.init(nibName: kNibName, bundle: nil)
    }
    
    // MARK: - Actions
    
    func cancelButtonDidPressed(button: UIButton) {
        dismissFromParentViewController()
        cancelBlock?()
    }
    
    func selectButtonDidPressed(button: UIButton) {
        dismissFromParentViewController()
        doneBlock?(selectedIndex: selectedRowIdx, selectedValue: selectedValue)
    }
    
    // MARK: - Private
    
    private func configureUI() {
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 8.0
    }
    
    private func setup() {
        cancelButton.addTarget(self, action: #selector(cancelButtonDidPressed(_:)), forControlEvents: .TouchUpInside)
        selectButton.addTarget(self, action: #selector(selectButtonDidPressed(_:)), forControlEvents: .TouchUpInside)
        
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(initialSelection, inComponent: 0, animated: false)
    }
    
}

// MARK: - CountPickerViewController (Embed) -

extension CountPickerViewController {
    
    class func showPickerWithTitle(title: String, rows: Int, initialSelection: Int, doneBlock: CountPickerDoneBlock, cancelBlock: CountPickerCancelBlock?) -> Bool {
        guard let rootViewController = UIUtils.getRootViewController() else { return false }
        
        let picker = CountPickerViewController()
        picker.numberOfRows = rows
        picker.initialSelection = initialSelection
        picker.doneBlock = doneBlock
        picker.cancelBlock = cancelBlock
        
        picker.presentInParentViewController(rootViewController)
        picker.titleLabel.text = title
        
        return true
    }
    
    func dismissFromParentViewController() {
        willMoveToParentViewController(nil)
        UIView.animateWithDuration(0.3, animations: {
            self.containerView.frame.origin.y += self.view.bounds.height
            self.view.alpha = 0.0
        }) { finished in
            guard finished == true else { return }
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }
    }
    
    func presentInParentViewController(parentViewController: UIViewController) {
        view.frame = parentViewController.view.bounds
        
        parentViewController.addChildViewController(self)
        parentViewController.view.addSubview(view)
        
        view.alpha = 0.0
        containerView.frame.origin.y += containerView.bounds.height
        UIView.animateWithDuration(0.3, animations: {
            self.view.alpha = 1.0
            self.containerView.frame.origin.y = 0
            }, completion: nil)
    }
    
}

// MARK: - CountPickerViewController: UIPickerViewDataSource -

extension CountPickerViewController: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfRows
    }
    
}

// MARK: - CountPickerViewController: UIPickerViewDelegate -

extension CountPickerViewController: UIPickerViewDelegate {
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRowIdx = row
    }
    
}
