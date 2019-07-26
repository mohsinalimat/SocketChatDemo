//
//  ChatViewController.swift
//  ChatDemo
//
//  Created by Ravi Patel on 17/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices


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



class ChatViewController: UIViewController , UINavigationControllerDelegate, UIImagePickerControllerDelegate,UIDocumentPickerDelegate{
    
    

     
    @IBOutlet weak var constraintsBottom: NSLayoutConstraint!
    @IBOutlet weak var lblPlaceHolder: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textViewSenderChat: UITextView!
    
    var chatObj : ChatList?
    var chatMsgsArray = [ChatMessages]()
    
    var msgSent : Bool = false
    
    var imagePicker = UIImagePickerController()
    let iOSDocumentsDirectory = iOSAppFileSystemDirectory(using: .Temp)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setUpUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        appdelegate.objAPI.delegate = self
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if #available(iOS 11.0, *) {
                let window = UIApplication.shared.keyWindow
                _ = window?.safeAreaInsets.top
                guard let bottomPadding = window?.safeAreaInsets.bottom else { return }
                constraintsBottom.constant += keyboardSize.height - bottomPadding
            }else{
                constraintsBottom.constant += keyboardSize.height
            }
            
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if constraintsBottom.constant > 0 {
            constraintsBottom.constant = 0
        }
    }

    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: self)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: self)
        appdelegate.objAPI.delegate = nil
    }
    
    func setUpUI(){
        self.tableView.tableFooterView = UIView.init()
        
        self.navigationItem.title = chatObj?.channelName
        
        self.loadCurrentConversationMessages()
        
        
    }
    
    
    
    
    
    func loadCurrentConversationMessages() {
        
        let fetchRequest = NSFetchRequest<ChatMessages>(entityName: "ChatMessages")
        fetchRequest.predicate = NSPredicate(format: "chat_id == '\(chatObj!.chatid!)'")
        fetchRequest.returnsObjectsAsFaults = false
        let sort = NSSortDescriptor(key: #keyPath(ChatMessages.created_at), ascending: true)
        fetchRequest.sortDescriptors = [sort]

        
        do {
            
            let managedObjectContext = appdelegate.persistentContainer.viewContext
            guard let result = try managedObjectContext.fetch(fetchRequest) as? [ChatMessages] else { return }
            
            for i in result {
                if i.is_read != "3" && i.sender != UserDefaults.standard.userID! {
                    let dict = ["is_read":"3","id":i.id!,"sender":i.sender!] as [String:Any]
                    self.changeStatus(dict:dict)
                }
            }
            self.msgSent = result.count > 0
            self.chatMsgsArray = result
            self.tableView.reloadData()
            self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
            
        } catch {
            print("error executing fetch request: \(error.localizedDescription)")
            return
        }
    }
    
    
    //MARK:- Button Actions
    @IBAction func btnMsgSendAction(_ sender: Any) {
        if textViewSenderChat.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
            return
        }
        self.sendChatMsg()
    }
    @IBAction func btnBackAction(_ sender: Any) {
       
        
        _ = appdelegate.objAPI.updateUnReadMsgCount(self.chatObj!.chatid!)
        for i in self.navigationController!.viewControllers{
            if i is ChatListViewController{
                if !self.msgSent {
                    appdelegate.persistentContainer.viewContext.delete(chatObj!)
                }
                self.navigationController?.popToViewController(i, animated: true)
                break
            }
        }
    }
    @IBAction func btnAttachmentAction(_ sender: UIButton) {
        self.openActionSheet()
    }
    
    //MARK:- API Call
    func sendChatMsg(){
        
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        
        if let currentIndex = receiverArray?.firstIndex(where: {$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == UserDefaults.standard.userID!}){
            receiverArray?.remove(at: currentIndex)
        }
        
        
        
        let params = ["channelType" : "0","message":textViewSenderChat.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),"is_read":"0","chat_id":chatObj!.chatid! , "sender": UserDefaults.standard.userID! , "receiver" : receiverArray!.joined(separator: ",") , "created_at" : Date().millisecondsSince1970,"updated_at" : Date().millisecondsSince1970 , "id" : "\(Date().millisecondsSince1970)\(chatObj!.chatid!)" ] as [String : Any]
        
        
        appdelegate.objAPI.sendMessage(params) { (response, error) in
            if let error = error {
                print(error)
            }else{
                if let responseData = response {
                    if let objMsg = appdelegate.objAPI.insertMessage(dict: responseData){
                        
                        
                        
                        let array = [["channelName":self.chatObj!.channelName!,"channelType":self.chatObj!.channelType!,"chatid":self.chatObj!.chatid!,"created_at":objMsg.created_at,"last_message":objMsg.message!,"updated_at":objMsg.updated_at,"userIds":self.chatObj!.userIds!] as [String:Any]]
                        self.msgSent = true
                        _ = appdelegate.objAPI.checkChannelAvailable(array)
                        
                        self.chatMsgsArray.append(objMsg)
                        self.tableView.reloadData()
                        
                        self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
                        self.textViewSenderChat.text = ""
                    }
                }
            }
        }
    }
    func openActionSheet(){
        let alert = UIAlertController(title: "ChatDemo", message: "Please Select an Option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default , handler:{ (UIAlertAction)in
            self.openImageViewPicker(isOpenGallery: .camera)
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default , handler:{ (UIAlertAction)in
            self.openImageViewPicker(isOpenGallery: .photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "Documents", style: .default , handler:{ (UIAlertAction)in
            self.openDocumentViewController()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler:{ (UIAlertAction)in
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func openImageViewPicker(isOpenGallery : UIImagePickerController.SourceType){
        if UIImagePickerController.isSourceTypeAvailable(isOpenGallery){
            imagePicker.delegate = self
            imagePicker.sourceType = isOpenGallery
            imagePicker.mediaTypes = ["public.image", "public.movie"]

            imagePicker.allowsEditing = true
            present(imagePicker, animated: true, completion: nil)
        }
    }
    func openDocumentViewController(){
        
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.text", "com.apple.iwork.pages.pages", "public.data"], in: .import)
        
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    //MARK:- ImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var imagePath : String = ""
        
        self.dismiss(animated: true, completion: { () -> Void in
            
        })
        if let chosenImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            imagePath = saveImageIntoDocumentDirectory(chosenImage) ?? ""
        }else if let mediaPath = info[UIImagePickerController.InfoKey.mediaURL] as? URL{
            imagePath = mediaPath.path
        }
        
        self.callUploadMediaAPI(path: imagePath)
        
    }
    //MARK:- DocumentControl Delegate
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//
//
//        self.callUploadMediaAPI(path: urls[0]..path)
//
//    }
    func callUploadMediaAPI(path : String){
        MTPLAPIManager.shared.upload(ChatURLManager.file_upload, parameter: nil, videoPath: [path], filekey: "file") { (objData, error) in
        }
    }

}
extension ChatViewController {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("url = \(url)")
        
        let status = iOSDocumentsDirectory.moveFile(withName:  url.lastPathComponent, inDirectory: .Temp, toDirectory: .Documents)
        print(status)
        
        
        self.callUploadMediaAPI(path: url.path)
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
        
        if (data["sender"] as? String == self.getReceiverID()){
            self.navigationItem.title = "Typing..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.navigationItem.title = self.chatObj?.channelName
            }
        }
    }
    
    func receiveMsg(msg: ChatMessages) {
        
        if (msg.sender == self.getReceiverID()){
            self.chatMsgsArray.append(msg)
            self.tableView.reloadData()
            self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
            let dict = ["is_read":"3","id":msg.id!,"sender":msg.sender!] as [String:Any]
            self.changeStatus(dict: dict)
        }
    }
    
    func changeStatus(dict : [String:Any]){
        appdelegate.objAPI.emitStatus(dict) { (emitData, error) in
            
        }
    }
    
    func getReceiverID() -> String
    {
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        
        if let currentIndex = receiverArray?.firstIndex(where: {$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == UserDefaults.standard.userID!}){
            receiverArray?.remove(at: currentIndex)
        }
        
        
        return receiverArray!.joined(separator: ",")
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
            senderCell.lblTime.text = "\(chatObj.created_at)".timeStampToLocalDate().getLocalTime()
            
            
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
                senderCell.imgStatus.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                break
            default:
                senderCell.imgStatus.image = nil
                break
            }
            
            return senderCell
        }else{
            let receiverCell = tableView.dequeueReusableCell(withIdentifier: "ChatReceiverCell", for: indexPath) as! ChatReceiverCell
            receiverCell.lblChatReceiverMsg.text = chatObj.message
            receiverCell.lblTime.text = "\(chatObj.created_at)".timeStampToLocalDate().getLocalTime()
            return receiverCell
        }
        
        
        
    }
}
extension ChatViewController : UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
    }
    
    
    
    func textViewDidChange(_ textView: UITextView) {
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        
        if let currentIndex = receiverArray?.firstIndex(where: {$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == UserDefaults.standard.userID!}){
            receiverArray?.remove(at: currentIndex)
        }
        let param = ["sender": UserDefaults.standard.userID!, "receiver": receiverArray!.joined(separator: ",")]
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            lblPlaceHolder.isHidden = true
            appdelegate.objAPI.updateTyping(param)
        }else{
            lblPlaceHolder.isHidden = false
        }
       
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            lblPlaceHolder.isHidden = false
        }
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


