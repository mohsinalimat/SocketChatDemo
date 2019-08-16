//
//  DashboardSplitViewController.swift
//  VChat
//
//  Created by vishal on 8/16/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa

class DashboardSplitViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.frame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: screen!.frame.size.width, height: screen!.frame.size.height))
        self.view.window?.minSize = screen!.frame.size
    }
    
}
