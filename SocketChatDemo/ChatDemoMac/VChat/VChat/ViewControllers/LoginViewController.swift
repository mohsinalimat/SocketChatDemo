//
//  LoginViewController.swift
//  VChat
//
//  Created by vishal on 8/16/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa

class LoginViewController: NSViewController {

    @IBOutlet weak var txtEmail: NSTextField!
    
    @IBOutlet weak var txtPassword: NSSecureTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    @IBAction func btnSignInAction(_ sender: NSButton) {
        self.performSegue(withIdentifier: "segueDashboard", sender: nil)
        self.view.window?.close()
    }
    
}
