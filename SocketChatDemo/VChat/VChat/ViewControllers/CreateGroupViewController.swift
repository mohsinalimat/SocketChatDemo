//
//  CreateGroupViewController.swift
//  VChat
//
//  Created by vishal on 8/17/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa

class CreateGroupViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var ImageViewGroupProfile: NSImageView!
    @IBOutlet weak var txtGroupName: NSTextField!
    @IBOutlet weak var lblParticipants: NSTextField!
    @IBOutlet weak var ParticipantTableView: NSTableView!
    
    var selectedUserList : [LoginUser]?
    var imagePath : String = ""
    var channelType : String?
    var delegate : InitiateChatDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblParticipants.placeholderString = "PARTICIPANTS: \(selectedUserList?.count ?? 0) OF 10"
        self.txtGroupName.placeholderString = self.channelType == channelTypeCase.group.rawValue ? "Enter Group Name" : "Enter Broadcast Name"
    }
    
    @IBAction func btnChooseImageAction(_ sender: NSButton) {
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
                self.imagePath = path
                self.ImageViewGroupProfile.image = NSImage.init(contentsOfFile: path)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.selectedUserList?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let result:UserDataTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "UserDataTableCellView"), owner: self) as! UserDataTableCellView
        let objUser = self.selectedUserList?[row]
        result.imgUserProfile.image = NSImage(named:"NSUser")
        result.lblUserName.stringValue = objUser?.name ?? ""
        return result
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 67
    }
    
    @IBAction func btnBackAction(_ sender: NSButton) {
        self.dismiss(sender)
    }
    
    @IBAction func btnDoneAction(_ sender: NSButton) {
        if txtGroupName.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            print("Please enter group name")
        }else if imagePath == ""{
            print("Please select group Pic")
        }else{
            guard let tempIdArray = self.selectedUserList?.map({"\($0.id)"}) else{
                return
            }
            callUploadMediaAPI(path: imagePath, completion: { (jsonData , error) in
                if let mediaUrl = jsonData?["filename"] as? String{
                    let userIds = tempIdArray.joined(separator: ",")
                    let ids = userIds + "," + "\(UserDefaults.standard.userID!)"
                    self.createGroup(ids: ids, mediaUrl: mediaUrl)
                }
            })
        }
    }
    
    func createGroup(ids : String, mediaUrl:String){
        let channelData = ["userids":ids,
                           "channelName":txtGroupName.stringValue,
                           "createdBy":UserDefaults.standard.userID!,
                           "channelType":self.channelType!,
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
                        self.dismiss(nil)
                        self.delegate?.initiateChat(objUser, isFirstTimePrivateChat: false)
                        appdelegate.saveContext()
                    }catch {
                        
                    }
                }
            }
        }
    }
}

func callUploadMediaAPI(path : String, completion : @escaping completionHandler){
    MTPLAPIManager.shared.upload(ChatURLManager.file_upload, parameter: nil, videoPath: [path], filekey: "file") { (objData, error) in
        if let error = error{
            print(error)
            completion(nil,"wrongJson")
        }else{
            
            guard let data = objData else { return }
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]{
                    completion(jsonData,nil)
                }else{
                    completion(nil,"wrongJson")
                }
            }catch{
                completion(nil,"wrongJson")
            }
        }
    }
}
