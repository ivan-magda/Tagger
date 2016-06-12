//
//  NSData+MimeType.swift
//  Tagger
//
//  Created by Ivan Magda on 13/06/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

// Source: http://stackoverflow.com/questions/21789770/determine-mime-type-from-nsdata
// Author: http://stackoverflow.com/users/2042510/tib

extension NSData {
    
    func mimeType() -> String {
        var c: UInt8 = 0
        getBytes(&c, length: 1)
        
        switch (c) {
        case 0xFF:
            return "image/jpeg"
        case 0x89:
            return "image/png"
        case 0x47:
            return "image/gif"
        case 0x49, 0x4D:
            return "image/tiff"
        case 0x25:
            return "application/pdf"
        case 0xD0:
            return "application/vnd"
        case 0x46:
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
    
}
