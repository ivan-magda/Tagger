/**
 * Copyright (c) 2017 Ivan Magda
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

import UIKit.UIColor

extension UIColor {

    enum ColorType {
        case primary
        case primaryLight
        case primaryDark
        case gray
        case darkGray
        case strongGray
        case red
        case white
        case black
        case lightGray
        case pink
    }

    convenience init(_ colorType: ColorType) {
        switch colorType {
        case .primary:
            self.init(hexString: "57B2A3")
        case .primaryLight:
            self.init(hexString: "8AE4D4")
        case .primaryDark:
            self.init(hexString: "1F8274")
        case .gray:
            self.init(hexString: "8C8C8C")
        case .strongGray:
            self.init(hexString: "555555")
        case .darkGray:
            self.init(hexString: "6C6C6C")
        case .red:
            self.init(hexString: "DB1D5F")
        case .white:
            self.init(hexString: "FDFEFE")
        case .black:
            self.init(hexString: "000000")
        case .lightGray:
            self.init(hexString: "E3E5E5")
        case .pink:
            self.init(hexString: "C550DC")
        }
    }
}
