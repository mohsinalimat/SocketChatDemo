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
import SDWebImage

class ChatListCell: UITableViewCell {
    
    @IBOutlet var lblChatName: UILabel!
    @IBOutlet var lblChatMsg: UILabel!
    @IBOutlet var lblChatDate: UILabel!
    @IBOutlet weak var lblUnReadCount: UILabel!
    @IBOutlet weak var viewUnReadCount: UIView!
    @IBOutlet weak var userProfilePic: UIImageView!
    
    @IBOutlet weak var ImageViewSelection: UIImageView!
    
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
        DispatchQueue.main.async {
            self.getUserList()
        }
    }
    
    func getUserList() -> Void {
        do{
            try clearDeepObjectEntity("LoginUser")
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
                            _ = try decoder.decode([LoginUser].self, from: objresponse.toData())
                            appdelegate.saveContext() 
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }catch{
                
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.chatListArray?.removeAll()
        appdelegate.objAPI.chnlDelegate = self
        self.checkDataAvailable()
    }
    
    @IBAction func btnOneToOneChatAction(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "segueUserList", sender: channelTypeCase.privateChat.rawValue)
    }
    
    
    @IBAction func btnGroupAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: "segueUserList", sender: channelTypeCase.group.rawValue)
    }
    
    @IBAction func btnBroadcastAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: "broadcastSegue", sender: channelTypeCase.broadcast.rawValue)
    }
    
    @IBAction func btnLogoutAction(_ sender: UIBarButtonItem) {
        appdelegate.objAPI.socketDisconnect { (success, error) in
            self.clearAllCoreData()
            appdelegate.objAPI.socket.removeAllHandlers()
            UserDefaults.standard.userID = nil
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    public func clearAllCoreData() {
        let entities = appdelegate.persistentContainer.managedObjectModel.entities
        do {
            try entities.compactMap({ $0.name }).forEach(clearDeepObjectEntity)
        }catch{}
    }
    
    func checkDataAvailable(){
        do{
            let context = appdelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatList")
            fetchRequest.predicate = NSPredicate(format: "channelType != '\(channelTypeCase.broadcast.rawValue)'")
            fetchRequest.returnsObjectsAsFaults = false
            let sort = NSSortDescriptor(key: #keyPath(ChatList.updated_at), ascending: false)
            fetchRequest.sortDescriptors = [sort]
            if let dataArray = try context.fetch(fetchRequest) as? [ChatList]{
                if dataArray.count == 0{
                    
                }else{
                    self.chatListArray = dataArray
                    self.chatListTable.reloadData()
                }
            }
        }catch let error{
            print(error.localizedDescription)
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
        cell.userProfilePic.sd_setImage(with: URL.init(string: objChat?.channelPic ?? ""), placeholderImage: #imageLiteral(resourceName: "user"))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let objChat = self.chatListArray?[indexPath.row]
        performSegue(withIdentifier: "ChatConversation", sender: objChat)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ChatViewController{
            destination.chatObj = sender as? ChatList
        }else if let destination = segue.destination as? UserListViewController {
            destination.channelType = sender as? String
        }else if let destination = segue.destination as? BroadcastListVC{
            destination.channelType = sender as? String
        }
        
    }
}
extension ChatListViewController : ReceiveChannel{
    func receiveChnl() {
        checkDataAvailable()
    }
}
