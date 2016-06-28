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

// MARK: - Constants

private let kTableViewCellReuseIdentifier = "TagTableViewCell"

// MARK: - TagListViewController: UIViewController, Alertable -

class TagListViewController: UIViewController, Alertable {
    
    // MARK: Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var copyAllBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var copyToClipboardBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var messageBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    static let nibName = "TagListViewController"
    
    var tags = [Tag]() {
        didSet {
            guard tableView != nil else { return }
            reloadData()
        }
    }
    
    private var selectedIndexes = Set<Int>()
    
    private var tagsTextView: HashtagsTextView = {
        let textView = HashtagsTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.editable = false
        textView.font = UIFont.systemFontOfSize(19.0)
        textView.hidden = true
        textView.alpha = 0.0
        return textView
    }()
    
    let actionSheet = UIAlertController(title: "Choose an action", message: nil, preferredStyle: .ActionSheet)
    
    // MARK: Init
    
    convenience init() {
        self.init(nibName: TagListViewController.nibName, bundle: nil)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        setTabBarHidden(false)
    }
    
    // MARK: - Private
    
    private func reloadData() {
        updateTagsTextViewDataSource()
        
        guard tableView.numberOfSections == 1 else {
            tableView.reloadData()
            return
        }
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    private func updateTagsTextViewDataSource() {
        tagsTextView.updateWithNewData(tags.enumerate().flatMap {
            selectedIndexes.contains($0) ? $1 : nil })
    }
    
    // MARK: Actions
    
    func moreBarButtonItemDidPressed() {
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func selectAllDidPressed(sender: AnyObject) {
        let selectedCount = selectedIndexes.count
        selectedIndexes.removeAll()
        
        if selectedCount != tags.count {
            for i in 0..<tags.count { selectedIndexes.insert(i) }
        }
        
        reloadData()
        updateMessageToolbarItemTitle()
        updateCopyToClipboardButtonEnabledState()
    }
    
    @IBAction func copyToClipboardDidPressed(sender: AnyObject) {
        PasteboardUtils.copyString(tagsTextView.text)
    }
    
}

// MARK: - TagListViewController (UI Functions) -

extension TagListViewController {
    
    private func configureUI() {
        setTabBarHidden(true)
        
        // Configure table view.
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kTableViewCellReuseIdentifier)
        
        // Configure text view:
        // Add as a subview to a root view and add constraints.
        view.insertSubview(tagsTextView, belowSubview: toolbar)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[topGuide]-0-[textView]", options: NSLayoutFormatOptions(), metrics: nil, views: ["topGuide": topLayoutGuide, "textView": tagsTextView]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-8-[textView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["textView": tagsTextView]))
        view.addConstraint(NSLayoutConstraint(item: tagsTextView, attribute: .Bottom, relatedBy: .Equal, toItem: toolbar, attribute: .Top, multiplier: 1.0, constant: 0.0))
        
        // Create more bar button and present action sheet with actions below on click.
        let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "more-tab-bar"), style: .Plain, target: self, action: #selector(moreBarButtonItemDidPressed))
        navigationItem.rightBarButtonItem = moreBarButtonItem
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Table View", style: .Default, handler: { action in
            guard self.tagsTextView.hidden == false else { return }
            self.tableView.hidden = false
            self.tagsTextView.setTextViewHidden(true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Hashtags View", style: .Default, handler: { action in
            guard self.tagsTextView.hidden == true else { return }
            self.tableView.hidden = true
            self.tagsTextView.setTextViewHidden(false)
        }))
        
        // Configure toolbar.
        messageBarButtonItem.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(14.0)], forState: .Normal)
        
        setUIState(.Default)
    }
    
    func setUIState(state: TagListViewControllerUIState) {
        func setItemsEnabled(enabled: Bool) {
            navigationItem.rightBarButtonItems?.forEach { $0.enabled = enabled }
            toolbar.items?.forEach { $0.enabled = enabled }
            
            if enabled {
                messageBarButtonItem.enabled = false
                updateCopyToClipboardButtonEnabledState()
            }
        }
        
        UIUtils.hideNetworkActivityIndicator()
        
        switch state {
        case .Default:
            setItemsEnabled(tags.count > 0)
            updateMessageToolbarItemTitle()
        case .Downloading:
            UIUtils.showNetworkActivityIndicator()
            setItemsEnabled(false)
            messageBarButtonItem.title = "Updating..."
        case .SuccessDoneWithDownloading:
            setItemsEnabled(tags.count > 0)
            updateMessageToolbarItemTitle()
        case .FailureDoneWithDownloading(let error):
            setItemsEnabled(false)
            messageBarButtonItem.title = error.localizedFailureReason ?? "Failed to fetch tags"
        }
    }
    
    private func updateMessageToolbarItemTitle() {
        let selectedCount = selectedIndexes.count
        
        guard tags.count > 0 else {
            messageBarButtonItem.title = "Nothing was returned"
            return
        }
        
        if selectedCount == tags.count {
            messageBarButtonItem.title = "All Selected (\(selectedCount))"
        } else {
            messageBarButtonItem.title = "\(selectedCount) Selected"
        }
    }
    
    private func updateCopyToClipboardButtonEnabledState() {
        copyToClipboardBarButtonItem.enabled = selectedIndexes.count > 0
    }
    
}

// MARK: - TagListViewController: UITableViewDataSource -

extension TagListViewController: UITableViewDataSource {
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier(kTableViewCellReuseIdentifier)!
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        configureCell(cell, atIndexPath: indexPath)
    }
    
    // MARK: Helpers
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let tag = tags[indexPath.row]
        cell.textLabel?.text = tag.name
        cell.accessoryType = selectedIndexes.contains(indexPath.row) ? .Checkmark : .None
    }
    
}

// MARK: - TagListViewController: UITableViewDelegate -

extension TagListViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if selectedIndexes.contains(indexPath.row) {
            selectedIndexes.remove(indexPath.row)
        } else {
            selectedIndexes.insert(indexPath.row)
        }
        
        updateCopyToClipboardButtonEnabledState()
        updateMessageToolbarItemTitle()
        updateTagsTextViewDataSource()
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
}

