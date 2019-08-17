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
    @IBOutlet weak var imageView: NSImageView!
    
    var filePath : String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnImagePickerAction(_ sender: NSButton) {
        let dialog = NSOpenPanel()
        dialog.title                   = "Choose a jpeg and png file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["jpeg","png","jpg"];

        if (dialog.runModal() == .OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                self.filePath = path
                self.imageView.image = NSImage.init(contentsOfFile: path)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func btnSignUpAction(_ sender: NSButton) {
        checkValidation()
    }
    
    @IBAction func btnBackAction(_ sender: NSButton) {
        self.dismiss(sender)
    }
    
    
    func checkValidation(){
        if txtName.stringValue == ""{
            print("please enter Name")
        }else if txtEmail.stringValue == "" {
            print("please enter email id")
        }else if txtPassword.stringValue == "" {
            print("please enter password")
        }else if self.filePath == nil{
            print("please Upload Profile Photo")
        }else{
            let params: [String : Any] = [ "name": txtName.stringValue,
                                           "email": txtEmail.stringValue,
                                           "password": txtPassword.stringValue]
            appdelegate.objAPI.connectSocket { (success, error) in
                if success ?? false {
                    self.callUploadMediaAPI(path: self.filePath ?? "", params: params)
                }
            }
        }
    }
    
    func callUploadMediaAPI(path : String, params : [String:Any]){
        var param = params
        MTPLAPIManager.shared.upload(ChatURLManager.file_upload, parameter: nil, videoPath: [path], filekey: "file") { (objData, error) in
            if let error = error{
                print(error)
            }else{
                guard let data = objData else { return }
                do{
                    if let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]{
                        
                        if let mediaUrl = jsonData["filename"] as? String{
                            DispatchQueue.main.async {
                                param["photo"]  = mediaUrl
                                self.SignUp(param)
                            }
                        }
                    }
                }catch{}
            }
        }
    }
    
    func SignUp(_ params:[String:Any]) -> Void {
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
                        appdelegate.saveContext()
                        print("data saved")
                        UserDefaults.standard.userID = objUser.id
                        UserDefaults.standard.userName = objUser.name
                        UserDefaults.standard.userPhoto = objUser.photo
                        self.performSegue(withIdentifier: "segueDashboard", sender: self)
                        self.view.window?.close()
                        appdelegate.objAPI.getData()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}
