//
//  CreateGroupViewController.swift
//  ChatDemo
//
//  Created by vishal on 04/08/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit

class CreateGroupViewController: UIViewController , UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var txtGroupName: UITextField!
    @IBOutlet weak var ImgGroupPic: UIImageView!
    
    @IBOutlet weak var lblNumbersOfParticipants: UILabel!
    @IBOutlet weak var tableParticipants: UITableView!
    var selectedUserList : [LoginUser]?
    var imagePath : String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        lblNumbersOfParticipants.text = "     PARTICIPANTS: \(selectedUserList?.count ?? 0) OF 10"
    }
    
    @IBAction func btnDoneAction(_ sender: UIBarButtonItem) {
        if txtGroupName.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            print("Please enter group name")
        }else if imagePath == ""{
            print("Please select group Pic")
        }else{
            guard let tempIdArray = self.selectedUserList?.map({$0.id!}) else{
                return
            }
            callUploadMediaAPI(path: imagePath, completion: { (jsonData , error) in
                if let mediaUrl = jsonData!["filename"] as? String{
                    let userIds = tempIdArray.joined(separator: ",")
                    let ids = userIds + "," + UserDefaults.standard.userID!
                    self.createGroup(ids: ids, mediaUrl: mediaUrl)
                }
            })
        }
    }
    
    @IBAction func btnBackAction(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnChangeProfilePic(_ sender: UIButton) {
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
    
    //MARK:- ImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        
        picker.dismiss(animated: true, completion: { () -> Void in
            if let chosenImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
                self.imagePath = saveImageIntoDocumentDirectory(chosenImage) ?? ""
                self.ImgGroupPic.image = chosenImage
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func createGroup(ids : String, mediaUrl:String){
        let channelData = ["userids":ids,
                           "channelName":txtGroupName.text ?? "",
                           "channelType":"1",
                           "channelPic":mediaUrl,
                           "created_at":Date().millisecondsSince1970] as [String : Any]
        appdelegate.objAPI.createGroup(channelData) { (response, error) in
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
                        
                        let objUser = try decoder.decode(ChatList.self, from: responseData.toData())
                        self.performSegue(withIdentifier: "ChatConversation", sender: objUser)
                        appdelegate.saveContext()
                    }catch {
                        
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ChatViewController{
            destination.chatObj = sender as? ChatList
        }
    }
}

extension CreateGroupViewController : UITableViewDelegate,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedUserList?.count ??  0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell") as! ChatListCell
        let objUser = self.selectedUserList?[indexPath.row]
        cell.lblChatName.text = objUser?.name
        cell.userProfilePic.sd_setImage(with: URL.init(string: objUser?.photo ?? "")!, placeholderImage: #imageLiteral(resourceName: "user"))
        return cell
    }
}
