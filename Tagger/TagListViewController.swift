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

// MARK: Constants

private let kTableViewCellReuseIdentifier = "TagTableViewCell"

// MARK: - TagListViewController: UIViewController, Alertable -

class TagListViewController: UIViewController, Alertable {
    
    // MARK: Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    // MARK: Properties
    
    static let nibName = "TagListViewController"
    
    var tags = [Tag]() {
        didSet {
            guard tableView != nil else { return }
            tagsTextView.tags = tags
            reloadData()
        }
    }
    
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
        guard tableView.numberOfSections == 1 else {
            tableView.reloadData()
            return
        }
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    // MARK: Actions
    
    func moreBarButtonItemDidPressed() {
        presentViewController(actionSheet, animated: true, completion: nil)
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
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[textView]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["textView": tagsTextView]))
        view.addConstraint(NSLayoutConstraint(item: tagsTextView, attribute: .Bottom, relatedBy: .Equal, toItem: toolbar, attribute: .Top, multiplier: 1.0, constant: 0.0))
        
        // Create more bar button and present action sheet with actions below on click.
        let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "more-tab-bar"), style: .Plain, target: self, action: #selector(moreBarButtonItemDidPressed))
        navigationItem.rightBarButtonItem = moreBarButtonItem
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Table View", style: .Default, handler: { action in
            guard self.tagsTextView.hidden == false else { return }
            self.tagsTextView.setTextViewHidden(true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Hashtags View", style: .Default, handler: { action in
            guard self.tagsTextView.hidden == true else { return }
            self.tagsTextView.setTextViewHidden(false)
        }))
    }
    
}

// MARK: - TagListViewController: UITableViewDataSource -

extension TagListViewController: UITableViewDataSource {
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kTableViewCellReuseIdentifier)!
        configureCell(cell, withTag: tags[indexPath.row])
        return cell
    }
    
    // MARK: Helpers
    
    private func configureCell(cell: UITableViewCell, withTag tag: Tag) {
        cell.textLabel?.text = tag.name
    }
    
}

// MARK: - TagListViewController: UITableViewDelegate -

extension TagListViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

