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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.chatListArray?.removeAll()
        appdelegate.objAPI.chnlDelegate = self
        self.checkDataAvailable()
    }
    
    @IBAction func btnOneToOneChatAction(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "segueUserList", sender: "0")
    }
    
    
    @IBAction func btnGroupAction(_ sender: UIButton) {
        self.performSegue(withIdentifier: "segueUserList", sender: "1")
    }
    
    @IBAction func btnBroadcastAction(_ sender: UIButton) {
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
        do {
            try entities.compactMap({ $0.name }).forEach(clearDeepObjectEntity)
        }catch{}
    }
    
    func checkDataAvailable(){
        do{
            let context = appdelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatList")
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
        }
    }
}
extension ChatListViewController : ReceiveChannel{
    func receiveChnl() {
        checkDataAvailable()
    }
}
