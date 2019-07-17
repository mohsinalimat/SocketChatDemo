//
//  SignUpViewController.swift
//  ChatDemo
//
//  Created by Ravi Patel on 16/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //check Validation
    func checkValidation(){
        if self.txtName.text?.isEmpty ?? true{
            print("please enter Name")
        }else if self.txtEmail.text?.isEmpty ?? true{
            print("please enter email id")
        }else if self.txtPassword.text?.isEmpty ?? true{
            print("please enter password")
        }else{
            let params = [
                "name": self.txtName.text!,
                "photo":"",
                "email":self.txtEmail.text!,
                          "password":self.txtPassword.text!]
            appdelegate.objAPI.userSignUp(params) { (response, error) in
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
                            try managedObjectContext.save()
                            print("data saved")
                            UserDefaults.standard.userID = objUser.id
                            appdelegate.objAPI.getData()
                            self.performSegue(withIdentifier: "segueChatList", sender: self)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
    }
    

    //MARK:- Button Actions
    @IBAction func btnSignUpAction(_ sender: Any) {
        self.checkValidation()
    }
    

}
