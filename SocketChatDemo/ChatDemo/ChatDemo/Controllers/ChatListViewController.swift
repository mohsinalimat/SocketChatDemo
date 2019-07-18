//
//  ChatListViewController.swift
//  ChatDemo
//
//  Created by vishal on 14/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit

class ChatListCell: UITableViewCell {
    
    @IBOutlet var lblChatName: UILabel!
    @IBOutlet var lblChatMsg: UILabel!
    @IBOutlet var lblChatDate: UILabel!
    
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
        appdelegate.objAPI.chnlDelegate = self
        getChatList()
        
    }
    
    func getChatList() -> Void {
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
        cell.lblChatDate.text = objChat?.created_at
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
    func receiveChnl(channel: [ChatList]) {
        if self.chatListArray != nil {
            self.chatListArray! += channel
        }else{
            self.chatListArray = channel
        }
        self.chatListTable.reloadData()
    }
}
