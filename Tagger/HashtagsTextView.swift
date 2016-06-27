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
    
    // MARK: Properties
    
    var tags = [Tag]() {
        didSet {
            let tagsText = tags.map { $0.name }.joinWithSeparator(" #")
            text = "#\(tagsText)"
        }
    }
    
    // MARK: Public Methods
    
    func setTextViewHidden(hidden: Bool) {
        let duration = 0.45
        if hidden {
            UIView.animateWithDuration(duration, animations: {
                self.alpha = 0.0
                }, completion: { finish in
                    if finish { self.hidden = true }
            })
        } else {
            self.hidden = false
            UIView.animateWithDuration(duration) {
                self.alpha = 1.0
            }
        }
    }
    
}
