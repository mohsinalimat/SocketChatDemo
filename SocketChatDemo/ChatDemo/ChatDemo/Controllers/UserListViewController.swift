//
//  UserListViewController.swift
//  ChatDemo
//
//  Created by Vishal's iMac on 16/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import CoreData

class UserListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var chatListTable: UITableView!
    
    var userList : [LoginUser]?
    var channelType : String?
    var selectedUserList = [LoginUser]()
    var privateChat = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.chatListTable.tableFooterView = UIView.init()
        getUserListFromLocal { (usersData) in
            DispatchQueue.main.async {
                self.userList = usersData
                if let index = self.userList?.firstIndex(where: {$0.id == Int64(UserDefaults.standard.userID!)}){
                    self.userList?.remove(at: index)
                }
                self.chatListTable.reloadData()
            }
        }
    }
    
    func getUserListFromLocal(completion: @escaping ([LoginUser]?)->Void) -> Void {
        let fetchRequest = NSFetchRequest<LoginUser>(entityName: "LoginUser")
        do {
            let result = try appdelegate.persistentContainer.viewContext.fetch(fetchRequest)
            completion(result)
        }catch{
            completion(nil)
        }
    }
    
    @IBAction func btnBackAction(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func btnGroupDone(_ sender: UIBarButtonItem) {
        if selectedUserList.count > 1 {
            self.performSegue(withIdentifier: "ChatGroup", sender: selectedUserList)
        }else{
            print("User Selected Less then one")
        }
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
                        let chatID = responseData["ChatId"] as! Int64
                        if let objUsr = appdelegate.objAPI.checkGetExist(chatID) {
                            self.privateChat = false
                            self.performSegue(withIdentifier: "ChatConversation", sender: objUsr)
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
                            self.privateChat = true
                            self.performSegue(withIdentifier: "ChatConversation", sender: objUser)
                        }
                        print("data saved")
                    } catch {
                        print("nodata found")
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ChatViewController{
            destination.chatObj = sender as? ChatList
            destination.privateMsgSent = self.privateChat
        }else if let destination = segue.destination as? CreateGroupViewController {
            destination.selectedUserList = sender as? [LoginUser]
            destination.channelType = self.channelType
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userList?.count ??  0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell") as! ChatListCell
        let objUser = self.userList?[indexPath.row]
        cell.lblChatName.text = objUser?.name
        cell.userProfilePic.sd_setImage(with: URL.init(string: objUser?.photo ?? "")!, placeholderImage: #imageLiteral(resourceName: "user"))
        cell.ImageViewSelection.isHidden = !selectedUserList.contains(objUser!)
        cell.ImageViewSelection.image = #imageLiteral(resourceName: "single_tick")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if channelType != channelTypeCase.privateChat.rawValue {
            if selectedUserList.contains(self.userList![indexPath.row]) {
                if let index = self.selectedUserList.firstIndex(where: {$0 == self.userList![indexPath.row]}) {
                    selectedUserList.remove(at: index)
                }
            }else{
                selectedUserList.append(self.userList![indexPath.row])
            }
            tableView.reloadData()
        }else{
            self.getStartChatID(index: indexPath.row)
        }
    }
}

