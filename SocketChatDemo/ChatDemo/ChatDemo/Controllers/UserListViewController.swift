//
//  UserListViewController.swift
//  ChatDemo
//
//  Created by Vishal's iMac on 16/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit

class UserListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet var chatListTable: UITableView!
    
    var userList : [LoginUser]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getUserList()
    }
    
    func getUserList() -> Void {
        appdelegate.objAPI.getUserList { (objResponse, error) in
            if let error = error {
                print(error)
            }else{
                if let objresponse = objResponse {
                    do {
                        let managedObjectContext = appdelegate.persistentContainer.viewContext
                        let decoder = JSONDecoder()
                        if let context = CodingUserInfoKey.managedObjectContext {
                            decoder.userInfo[context] = managedObjectContext
                        }
                        var objUser = try decoder.decode([LoginUser].self, from: objresponse.toData())
                        if let index = objUser.firstIndex(where: {$0.id == UserDefaults.standard.userID!}){
                            objUser.remove(at: index)
                        }
                        self.userList = objUser
                        self.chatListTable.reloadData()
                        print("data saved")
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func getStartChatID(index : Int){
        
        let params = ["UserIDs":"\(self.userList![index].id!), \(UserDefaults.standard.userID!)"]
            
        
        appdelegate.objAPI.getChatID(params) { (response, error) in
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
                        
                        var obj = [String:Any]()
                        obj["userIds"] = "\(self.userList![index].id!), \(UserDefaults.standard.userID!)"
                        obj["chatid"] = responseData["ChatId"] as? String
                        obj["channelName"] = "\(self.userList![index].name!)"
                        obj["channelType"] = "0"
                        
                        let objUser = try decoder.decode(ChatList.self, from: obj.toData())
                        
                        
                        self.performSegue(withIdentifier: "ChatConversation", sender: objUser)
                        
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.getStartChatID(index: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

