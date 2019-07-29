//
//  ChatListViewController.swift
//  ChatDemo
//
//  Created by vishal on 14/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import CoreData
import MBProgressHUD

class ChatListCell: UITableViewCell {
    
    @IBOutlet var lblChatName: UILabel!
    @IBOutlet var lblChatMsg: UILabel!
    @IBOutlet var lblChatDate: UILabel!
    @IBOutlet weak var lblUnReadCount: UILabel!
    @IBOutlet weak var viewUnReadCount: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}


class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var chatListTable: UITableView!
    var chatListArray : [ChatList]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chatListTable.tableFooterView = UIView.init()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.chatListArray?.removeAll()
        appdelegate.objAPI.chnlDelegate = self
        self.checkDataAvailable()
    }
    
    @IBAction func btnLogoutAction(_ sender: UIBarButtonItem) {
        appdelegate.objAPI.socketDisconnect { (success, error) in
            self.clearAllCoreData()
            appdelegate.objAPI.socket.removeAllHandlers()
            UserDefaults.standard.userID = nil
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    public func clearAllCoreData() {
        let entities = appdelegate.persistentContainer.managedObjectModel.entities
        entities.compactMap({ $0.name }).forEach(clearDeepObjectEntity)
    }
    
    private func clearDeepObjectEntity(_ entity: String) {
        let context = appdelegate.persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
    }
    
    func checkDataAvailable(){
        do{
            let context = appdelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatList")
            if let dataArray = try context.fetch(fetchRequest) as? [ChatList]{
                if dataArray.count == 0{
                    getChatList()
                }else{
                    self.chatListArray = dataArray
                    self.chatListTable.reloadData()
                }
            }
        }catch let error{
            print(error.localizedDescription)
        }
    }
    
    func getChatList() -> Void {
        let mbProgress = MBProgressHUD.showAdded(to: self.view, animated: true)
        mbProgress.label.text = "Sync Data..."
        
        let params = ["senderId": "\(UserDefaults.standard.userID!)"]
        
        appdelegate.objAPI.getChatList(params) { (chatList, error) in
            if let error = error {
                print(error)
            }else{
                if let chatlist = chatList, chatlist.count > 0 {
                    if let objChatList = appdelegate.objAPI.insertChannelList(arrayData: chatlist){
                        self.chatListArray = objChatList
                        self.chatListTable.reloadData()
                    }
                }else{
                    print("nodata found")
                }
            }
            mbProgress.hide(animated: true)
        }
        
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatListArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell") as! ChatListCell
        let objChat = self.chatListArray?[indexPath.row]
        cell.lblChatName.text = objChat?.channelName
        cell.lblChatMsg.text = objChat?.last_message
        cell.lblChatDate.text = "\(objChat!.created_at)".timeStampToLocalDate()
        cell.viewUnReadCount.isHidden = Int(objChat!.unreadcount) <= 0
        cell.lblUnReadCount.text = "\(objChat!.unreadcount)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let objChat = self.chatListArray?[indexPath.row]
        performSegue(withIdentifier: "ChatConversation", sender: objChat)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ChatViewController{
            destination.chatObj = sender as? ChatList
        }
    }
}
extension ChatListViewController : ReceiveChannel{
    func receiveChnl() {
        checkDataAvailable()
    }
}
