//
//  SignUpViewController.swift
//  VChat
//
//  Created by vishal on 8/16/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa

class SignUpViewController: NSViewController {
    @IBOutlet weak var txtName: NSTextField!
    
    @IBOutlet weak var txtEmail: NSTextField!
    
    @IBOutlet weak var txtPassword: NSSecureTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func btnSignUpAction(_ sender: NSButton) {
        self.dismiss(sender)
    }
}
