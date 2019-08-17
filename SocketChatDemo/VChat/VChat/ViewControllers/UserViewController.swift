//
//  UserViewController.swift
//  VChat
//
//  Created by vishal on 8/17/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa

class UserViewController: NSViewController,NSTableViewDelegate,NSTableViewDataSource {
    
    @IBOutlet weak var UserTableView: NSTableView!
    
    var userList : [LoginUser]?
    var channelType : String?
    var selectedUserList = [LoginUser]()
    var privateChat = false
    var delegate : InitiateChatDelegate?
    var delegateOpenGroup : GroupBroadcastOpenProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserTableView.selectionHighlightStyle = .none
        getUserListFromLocal{ (usersData) in
            DispatchQueue.main.async {
                self.userList = usersData
                if let index = self.userList?.firstIndex(where: {$0.id == Int64(UserDefaults.standard.userID!)}){
                    self.userList?.remove(at: index)
                }
                self.UserTableView.reloadData()
            }
        }
    }
    
    func getUserListFromLocal(completion: @escaping ([LoginUser]?)->Void) -> Void {
        let fetchRequest = NSFetchRequest<LoginUser>(entityName: "LoginUser")
        do{
            let result = try appdelegate.persistentContainer.viewContext.fetch(fetchRequest)
            completion(result)
        }catch{
            completion(nil)
        }
    }
    
    @IBAction func btnBackAction(_ sender: NSButton) {
        self.dismiss(sender)
    }
    
    @IBAction func btnDoneAction(_ sender: NSButton) {
        delegateOpenGroup = self.presentingViewController as? GroupBroadcastOpenProtocol
        self.dismiss(sender)
        delegateOpenGroup?.openCreateGroupBroadcastView(selectedUserList,channelType: channelType!)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.userList?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let result:UserDataTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "UserDataTableCellView"), owner: self) as! UserDataTableCellView
        let objUser = self.userList?[row]
        result.imgUserProfile.image = NSImage(named:"NSUser")
        result.lblUserName.stringValue = objUser?.name ?? ""
        result.tickImage.isHidden = !selectedUserList.contains(objUser!)
        result.tickImage.image = NSImage.init(named: "NSMenuOnStateTemplate")
        return result
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let table = notification.object as? NSTableView else {
            return
        }
        let row = table.selectedRow
        if channelType != channelTypeCase.privateChat.rawValue {
            if selectedUserList.contains(self.userList![row]) {
                if let index = self.selectedUserList.firstIndex(where: {$0 == self.userList![row]}) {
                    selectedUserList.remove(at: index)
                }
            }else{
                selectedUserList.append(self.userList![row])
            }
            table.reloadData()
        }else{
            self.getStartChatID(index: row)
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 67
    }
    
    func getStartChatID(index : Int){

        let params = ["UserIDs":"\(self.userList![index].id),\(UserDefaults.standard.userID!)",
            "channelType":channelType ?? ""] as [String : Any]
        
        appdelegate.objAPI.getChatID(params) { (response, error) in
            if let error = error {
                print(error)
            }else{
                if let responseData = response {
                    do {
                        self.delegate = self.presentingViewController?.parent?.children[1] as? InitiateChatDelegate
                        let chatID = responseData["ChatId"] as! Int64
                        if let objUsr = appdelegate.objAPI.checkGetExist(chatID) {
                            self.dismiss(nil)
                            self.delegate?.initiateChat(objUsr, isFirstTimePrivateChat: false)
                            
                        }else{
                            let managedObjectContext = appdelegate.persistentContainer.viewContext
                            let decoder = JSONDecoder()
                            if let context = CodingUserInfoKey.managedObjectContext {
                                decoder.userInfo[context] = managedObjectContext
                            }
                            
                            var obj = [String:Any]()
                            obj["userIds"] = "\(self.userList![index].id),\(UserDefaults.standard.userID!)"
                            obj["chatid"] = chatID
                            obj["channelName"] = "\(self.userList![index].name!)"
                            obj["channelType"] = self.channelType
                            obj["channelPic"] = "\(self.userList![index].photo!)"
                            
                            let objUser = try decoder.decode(ChatList.self, from: obj.toData())
                            self.dismiss(nil)
                            self.delegate?.initiateChat(objUser, isFirstTimePrivateChat: true)
                        }
                        print("data saved")
                    } catch {
                        print("nodata found")
                    }
                }
            }
        }
    }
}

class UserDataTableCellView : NSTableCellView {
    @IBOutlet weak var imgUserProfile: NSImageView!
    @IBOutlet weak var lblUserName: NSTextField!
    @IBOutlet weak var tickImage: NSImageView!
}
