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

typealias CountPickerDoneBlock = (_ selectedIndex: Int, _ selectedValue: Int) -> Swift.Void
typealias CountPickerCancelBlock = () -> Swift.Void

// MARK: - CountPickerViewController: UIViewController

@IBDesignable
final class CountPickerViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var selectButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    
    // MARK: Instance Variables
    
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

    private static let nibName = "CountPickerViewController"
    
    // MARK: - UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: - Init
    
    convenience init() {
        self.init(nibName: CountPickerViewController.nibName, bundle: nil)
    }
    
}

// MARK: - CountPickerViewController (Actions) -

extension CountPickerViewController {

    @objc private func cancelButtonDidPressed(_ button: UIButton) {
        dismissFromParentViewController()
        cancelBlock?()
    }

    @objc private func selectButtonDidPressed(_ button: UIButton) {
        dismissFromParentViewController()
        doneBlock?(selectedRowIdx, selectedValue)
    }

}

// MARK: - CountPickerViewController (Private Helpers) -

extension CountPickerViewController {

    private func setup() {
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 8.0

        cancelButton.addTarget(self, action: #selector(cancelButtonDidPressed(_:)), for: .touchUpInside)
        selectButton.addTarget(self, action: #selector(selectButtonDidPressed(_:)), for: .touchUpInside)

        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(initialSelection, inComponent: 0, animated: false)
    }

}

// MARK: - CountPickerViewController (Embed) -

extension CountPickerViewController {
    
    @discardableResult class func showPicker(title: String,
                                             rows: Int,
                                             initialSelection: Int,
                                             doneHandler: @escaping CountPickerDoneBlock,
                                             cancelHandler: CountPickerCancelBlock?) -> Bool {
        guard let rootViewController = UIUtils.rootViewController() else { return false }
        
        let picker = CountPickerViewController()
        picker.numberOfRows = rows
        picker.initialSelection = initialSelection
        picker.doneBlock = doneHandler
        picker.cancelBlock = cancelHandler
        
        picker.presentInParentViewController(rootViewController)
        picker.titleLabel.text = title
        
        return true
    }
    
    func dismissFromParentViewController() {
        willMove(toParentViewController: nil)

        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.frame.origin.y += self.view.bounds.height
            self.view.alpha = 0.0
        }, completion: { finished in
            guard finished == true else { return }
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }) 
    }
    
    func presentInParentViewController(_ parentViewController: UIViewController) {
        view.frame = parentViewController.view.bounds
        
        parentViewController.addChildViewController(self)
        parentViewController.view.addSubview(view)
        
        view.alpha = 0.0
        containerView.frame.origin.y += containerView.bounds.height
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 1.0
            self.containerView.frame.origin.y = 0
        }, completion: nil)
    }
    
}

// MARK: - CountPickerViewController: UIPickerViewDataSource -

extension CountPickerViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return numberOfRows
    }
    
}

// MARK: - CountPickerViewController: UIPickerViewDelegate -

extension CountPickerViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRowIdx = row
    }
    
}
