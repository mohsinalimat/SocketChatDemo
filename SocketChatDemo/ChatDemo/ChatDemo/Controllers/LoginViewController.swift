//
//  LoginViewController.swift
//  ChatDemo
//
//  Created by vishal on 14/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet var emailID: UITextField!
    @IBOutlet var password: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnLoginAction(_ sender: UIButton) {
        if emailID.text == "" {
            print("please enter email id")
        }else if password.text == "" {
            print("Please enter password")
        }else{
            let params = ["email":emailID.text!,
                          "password":password.text!]
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
                        self.performSegue(withIdentifier: "segueChatList", sender: self)
                        DispatchQueue.main.async {
                            appdelegate.objAPI.getData()
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}
