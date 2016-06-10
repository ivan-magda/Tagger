//
//  GCDUtils.swift
//  VirtualTourist
//
//  Created by Ivan Magda on 16/05/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

typealias Block = () -> Void

func performOnMain(block: Block) {
    dispatch_async(dispatch_get_main_queue()) {
        block()
    }
}

func performAfterOnMain(time: Double, block: Block) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
        block()
    }
}

func performOnBackgroud(block: Block) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        block()
    }
}
