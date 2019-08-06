//
//  SignUpViewController.swift
//  ChatDemo
//
//  Created by Ravi Patel on 16/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnProfile: UIButton!
    @IBOutlet weak var imageViewProfile: UIImageView!
    
    
    var imagePath : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //check Validation
    func checkValidation(){
        if self.txtName.text?.isEmpty ?? true{
            print("please enter Name")
        }else if self.txtEmail.text?.isEmpty ?? true{
            print("please enter email id")
        }else if self.txtPassword.text?.isEmpty ?? true{
            print("please enter password")
        }else if self.imagePath == ""{
            print("please Upload Profile Photo")
        }else{
            let params: [String : Any] = [
                "name": self.txtName.text!,
                "email":self.txtEmail.text!,
                "password":self.txtPassword.text!]
            appdelegate.objAPI.connectSocket { (success, error) in
                if success ?? false {
                    self.callUploadMediaAPI(path: self.imagePath , params: params)
                }
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
                        UserDefaults.standard.userID = Int(objUser.id)
                        UserDefaults.standard.userName = objUser.name
                        UserDefaults.standard.userPhoto = objUser.photo
                        appdelegate.objAPI.getData()
                        self.performSegue(withIdentifier: "segueChatList", sender: self)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    //MARK:- Button Actions
    @IBAction func btnSignUpAction(_ sender: Any) {
        self.checkValidation()
    }
    
    @IBAction func btnProfileAction(_ sender: Any) {
        self.openActionSheet()
    }
    
    func openActionSheet(){
        let alert = UIAlertController(title: "ChatDemo", message: "Please Select an Option", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default , handler:{ (UIAlertAction)in
            openImageViewPicker(isOpenGallery: .camera,viewController: self)
        }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default , handler:{ (UIAlertAction)in
            openImageViewPicker(isOpenGallery: .photoLibrary,viewController: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler:{ (UIAlertAction)in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
}
extension SignUpViewController{
    
    //MARK:- ImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: { () -> Void in
            self.imagePath = ""
            if let chosenImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
                self.imageViewProfile.image = chosenImage
                self.imagePath = saveImageIntoDocumentDirectory(chosenImage) ?? ""
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func callUploadMediaAPI(path : String , params : [String:Any]){
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
}
