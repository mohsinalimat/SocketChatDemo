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
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var imgStatus: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}
class ChatReceiverCell: UITableViewCell {
    
    @IBOutlet var lblChatReceiverMsg: UILabel!
    
    @IBOutlet weak var lblTime: UILabel!
    
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
        
        self.navigationItem.title = chatObj?.channelName
        
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
        
        
        
        let params = ["channelType" : "0","message":self.textViewSenderChat.text!,"is_read":"0","chat_id":chatObj!.chatid! , "sender": UserDefaults.standard.userID! , "receiver" : receiverArray!.joined(separator: ",") , "created_at" : getCurrentDateTime(),"updated_at" : getCurrentDateTime() , "id" : "\(Date().millisecondsSince1970)\(chatObj!.chatid!)" ] as [String : Any]
        
        
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
    func updateStatus(data: [String : Any]) {
        if let index = self.chatMsgsArray.firstIndex(where: {$0.id == data["id"] as? String}){
            let obj = self.chatMsgsArray[index]
            obj.is_read = data["is_read"] as? String
            self.chatMsgsArray[index] = obj
            self.tableView.reloadData()
            
        }
    }

    
    func typingMsg(data: [String : Any]) {
        self.navigationItem.title = "Typing..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.navigationItem.title = self.chatObj?.channelName
        }
    }
    
    func receiveMsg(msg: ChatMessages) {
        self.chatMsgsArray.append(msg)
        self.tableView.reloadData()
        self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
        let dict = ["is_read":"3","id":msg.id]
        appdelegate.objAPI.emitStatus(dict as [String : Any]) { (emitData, error) in
            self.updateStatus(data: emitData!)
        }

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
            senderCell.lblTime.text = chatObj.created_at?.getLocalTime()
            
            
            switch chatObj.is_read {
            case "0":
                senderCell.imgStatus.image = nil
                break
            case "1":
                senderCell.imgStatus.image = #imageLiteral(resourceName: "single_tick")
                senderCell.imgStatus.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                break
            case "2":
                senderCell.imgStatus.image = #imageLiteral(resourceName: "tick_grey")
                senderCell.imgStatus.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                break
            case "3":
                senderCell.imgStatus.image = #imageLiteral(resourceName: "tick_blue")
                senderCell.imgStatus.tintColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
                break
            default:
                senderCell.imgStatus.image = nil
                break
            }
            
            return senderCell
        }else{
            let receiverCell = tableView.dequeueReusableCell(withIdentifier: "ChatReceiverCell", for: indexPath) as! ChatReceiverCell
            receiverCell.lblChatReceiverMsg.text = chatObj.message
            receiverCell.lblTime.text = chatObj.created_at?.getLocalTime()
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
    
    
    
    func textViewDidChange(_ textView: UITextView) {
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        
        if let currentIndex = receiverArray?.firstIndex(where: {$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == UserDefaults.standard.userID!}){
            receiverArray?.remove(at: currentIndex)
        }
        let param = ["sender": UserDefaults.standard.userID!, "receiver": receiverArray!.joined(separator: ",")]
        appdelegate.objAPI.updateTyping(param)
    }
    
    
}
extension UITableView{
    func scrollToBottom(index : Int){
        DispatchQueue.main.async {
            if index > 0{
                let indexPath = IndexPath(row: index, section: 0)
                self.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
}
func getCurrentDateTime() -> String{
    
    let dateFormatter : DateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let date = Date()
    return dateFormatter.string(from: date)
}

