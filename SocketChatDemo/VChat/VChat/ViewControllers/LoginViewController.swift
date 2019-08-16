//
//  LoginViewController.swift
//  VChat
//
//  Created by vishal on 8/16/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa
import SocketIO

class LoginViewController: NSViewController {

    @IBOutlet weak var txtEmail: NSTextField!
    
    @IBOutlet weak var txtPassword: NSSecureTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    @IBAction func btnSignInAction(_ sender: NSButton) {
        
        
        if txtEmail.stringValue == "" {
            print("please enter email id")
        }else if txtPassword.stringValue == "" {
            print("Please enter password")
        }else{
            let params = ["email":txtEmail.stringValue,
                          "password":txtPassword.stringValue]
            if appdelegate.objAPI.socket.status == .connected {
                self.login(params)
            }else{
                appdelegate.objAPI.connectSocket { (success, error) in
                    if success ?? false {
                        self.login(params)
                    }
                }
            }
        }
    }
    
    func login(_ params:[String:Any]) -> Void {
        appdelegate.objAPI.authenticateUser(params) { (response, error) in
            if let error = error {
                print(error)
            }else{
                if let responseData = response {
                    do {
                        let managedObjectContext = appdelegate.persistentContainer.viewContext
                        let decoder = JSONDecoder()
                        if let context = CodingUserInfoKey.managedObjectContext {
                            decoder.userInfo[context] = managedObjectContext
                        }
                        let objUser = try decoder.decode(LoginUser.self, from: responseData.toData())
                        appdelegate.saveContext()
                        print("data saved")
                        UserDefaults.standard.userID = objUser.id
                        UserDefaults.standard.userName = objUser.name
                        UserDefaults.standard.userPhoto = objUser.photo
                        self.performSegue(withIdentifier: "segueDashboard", sender: nil)
                        self.view.window?.close()
//                        DispatchQueue.main.async {
//                            appdelegate.objAPI.getData()
//                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}
