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

// MARK: HashtagsTextView: UITextView

class HashtagsTextView: UITextView {
    
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: Init
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Public
    
    func updateWithNewData(_ tags: [String]) {
        let tagsText = tags.joined(separator: " #")
        
        if tagsText.characters.count > 0 {
            text = "#\(tagsText)"
        } else {
            text = "No tags selected. First, select at least one."
        }
    }
    
    func setTextViewHidden(_ hidden: Bool) {
        let duration = 0.25
        if hidden {
            UIView.animate(withDuration: duration, animations: {
                self.alpha = 0.0
                }, completion: { finish in
                    if finish { self.isHidden = true }
            })
        } else {
            self.isHidden = false
            UIView.animate(withDuration: duration, animations: {
                self.alpha = 1.0
            }) 
        }
    }
    
    // MARK: Actions
    
    @objc func didTapOnText() {
        selectedTextRange = textRange(from: beginningOfDocument, to: endOfDocument)
    }
    
    // MARK: Private
    
    fileprivate func setup() {
        updateWithNewData([])
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnText))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
}
