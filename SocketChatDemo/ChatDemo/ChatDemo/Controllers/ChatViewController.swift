//
//  ChatViewController.swift
//  ChatDemo
//
//  Created by Ravi Patel on 17/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import CoreData



class ChatSenderCell : UITableViewCell {
    
    @IBOutlet var lblChatSenderMsg: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}
class ChatReceiverCell: UITableViewCell {
    
    @IBOutlet var lblChatReceiverMsg: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}



class ChatViewController: UIViewController {

     
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textViewSenderChat: UITextView!
    
    var chatObj : ChatList?
    var chatMsgsArray = [ChatMessages]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setUpUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        appdelegate.objAPI.delegate = self
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        appdelegate.objAPI.delegate = nil
    }
    func setUpUI(){
        self.tableView.tableFooterView = UIView.init()
        
        self.loadCurrentConversationMessages()
        
        
    }
    func loadCurrentConversationMessages() {
        
        
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ChatMessages")
        fetchRequest.predicate = NSPredicate(format: "chat_id == '\(chatObj!.chatid!)'")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            
            let managedObjectContext = appdelegate.persistentContainer.viewContext
            guard let result = try managedObjectContext.fetch(fetchRequest) as? [ChatMessages] else { return }
            self.chatMsgsArray = result
            self.tableView.reloadData()
            self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
            
        } catch {
            print("error executing fetch request: \(error.localizedDescription)")
            return
        }
    }
    
    
    
    @IBAction func btnMsgSendAction(_ sender: Any) {
        guard textViewSenderChat.text != ""  else {
            return
        }
        self.sendChatMsg()
    }
    @IBAction func btnBackAction(_ sender: Any) {
       
        for i in self.navigationController!.viewControllers{
            if i is ChatListViewController{
                self.navigationController?.popToViewController(i, animated: true)
                break
            }
            
        }
        
    }
    
    
    func sendChatMsg(){
        
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        
        if let currentIndex = receiverArray?.firstIndex(where: {$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == UserDefaults.standard.userID!}){
            receiverArray?.remove(at: currentIndex)
        }
        
        
        
        let params = ["channelType" : "0","message":self.textViewSenderChat.text!,"status":"0","chat_id":chatObj!.chatid! , "sender": UserDefaults.standard.userID! , "receiver" : receiverArray!.joined(separator: ",")] as [String : Any]
        print(params)
        
        appdelegate.objAPI.sendMessage(params) { (response, error) in
            if let error = error {
                print(error)
            }else{
                if let responseData = response {
                    if let objMsg = appdelegate.objAPI.insertMessage(dict: responseData){
                        self.chatMsgsArray.append(objMsg)
                        self.tableView.reloadData()
                        
                        self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
                        
                        
                        self.textViewSenderChat.text = ""
                    }
                }
            }
        }
    }
    

}
extension ChatViewController : ReceiveMessage{
    func receiveMsg(msg: ChatMessages) {
        self.chatMsgsArray.append(msg)
        self.tableView.reloadData()
        self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
    }
}

extension ChatViewController : UITableViewDataSource,UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatMsgsArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let chatObj = self.chatMsgsArray[indexPath.row]
        
        if UserDefaults.standard.userID! == chatObj.sender{
            let senderCell = tableView.dequeueReusableCell(withIdentifier: "ChatSenderCell", for: indexPath) as! ChatSenderCell
            senderCell.lblChatSenderMsg.text = chatObj.message
            return senderCell
        }else{
            let receiverCell = tableView.dequeueReusableCell(withIdentifier: "ChatReceiverCell", for: indexPath) as! ChatReceiverCell
            receiverCell.lblChatReceiverMsg.text = chatObj.message
            return receiverCell
        }
        
        
        
    }
}
extension ChatViewController : UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Type a message"
            textView.textColor = UIColor.lightGray
        }else{
            textView.text = ""
        }

    }
}
extension UITableView{
    func scrollToBottom(index : Int){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: index, section: 0)
            self.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}
