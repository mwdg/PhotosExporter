//
//  PlansController.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 11.06.19.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Cocoa

class PlansViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    convenience init() {
        self.init(nibName: "PlansView", bundle: nil);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
