//
//  MainWindowController.swift
//  VChat
//
//  Created by vishal on 8/19/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    override func windowDidLoad() {
        appdelegate.objAPI = SocketManagerAPI.shared
        MTPLAPIManager.shared.setupReachability()
        if UserDefaults.standard.userID != nil {
            appdelegate.objAPI.connectSocket { (success, error) in
                if let suceess = success, suceess == true {
                    self.contentViewController = NSStoryboard.dashboardSplitController()
                }else{
                    self.contentViewController = NSStoryboard.loginViewController()
                }
            }
        } else {
            self.contentViewController = NSStoryboard.loginViewController()
        }
    }
}

extension NSStoryboard {

    private class func mainStoryboard() -> NSStoryboard { return NSStoryboard(name: "Main", bundle: Bundle.main) }

    class func loginViewController() -> LoginViewController {
        return self.mainStoryboard().instantiateController(withIdentifier: "LoginViewController") as! LoginViewController
    }

    class func dashboardSplitController() -> DashboardSplitViewController {
        return self.mainStoryboard().instantiateController(withIdentifier: "DashboardSplitViewController") as! DashboardSplitViewController
    }
}
