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
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        DispatchQueue.main.async {
            self.view.frame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: screen!.frame.size.width, height: screen!.frame.size.height))
            self.view.window?.setContentSize(CGSize.init(width: screen!.visibleFrame.size.width, height: screen!.visibleFrame.size.height-22))
            self.view.window?.setFrameOrigin(CGPoint.init(x: 0, y: screen!.visibleFrame.maxY))
        }
    }
    
    override func mouseDown(with event: NSEvent){
        (self.children[0] as! DashboardViewController).scrollTableDropDown.isHidden = true
    }
}
