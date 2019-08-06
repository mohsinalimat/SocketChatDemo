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
import SDWebImage
import AVKit
import AVFoundation
import PDFKit
class ChatSenderCell : UITableViewCell {
    
    @IBOutlet var lblChatSenderMsg: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var imgStatus: UIImageView!
    @IBOutlet weak var imgDownload: UIImageView!
    @IBOutlet weak var btnShowPreview: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}

class ChatReceiverCell: UITableViewCell {
    
    @IBOutlet var lblChatReceiverMsg: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var imgDownload: UIImageView!
    @IBOutlet weak var btnShowPreview: UIButton!
    @IBOutlet weak var lblName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}

class ChatViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate {
    
    
    
    @IBOutlet weak var constraintsBottom: NSLayoutConstraint!
    @IBOutlet weak var lblPlaceHolder: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textViewSenderChat: UITextView!
    
    var chatObj : ChatList?
    var chatMsgsArray = [ChatMessages]()
    var page : Int = 0
    var isPaginationEnable : Bool = false
    var pagelimit = 300
    var cacheImages = NSCache<NSString,UIImage>()
    var privateMsgSent = false
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
                if constraintsBottom.constant <= 20 {
                    constraintsBottom.constant += keyboardSize.height - bottomPadding
                }
            }else{
                if constraintsBottom.constant <= 20 {
                    constraintsBottom.constant += keyboardSize.height
                }
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
        _ = appdelegate.objAPI.updateUnReadMsgCount(self.chatObj!.chatid)
        self.loadCurrentConversationMessages()
    }
    
    func loadCurrentConversationMessages() {
        let fetchRequest = NSFetchRequest<ChatMessages>(entityName: "ChatMessages")
        fetchRequest.predicate = NSPredicate(format: "chat_id == '\(chatObj!.chatid)'")
        fetchRequest.returnsObjectsAsFaults = false
        let sort = NSSortDescriptor(key: #keyPath(ChatMessages.created_at), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        fetchRequest.fetchLimit = pagelimit
        fetchRequest.fetchOffset = fetchRequest.fetchLimit * page
        do {
            let managedObjectContext = appdelegate.persistentContainer.viewContext
            let result = try managedObjectContext.fetch(fetchRequest)
            if result.count >= pagelimit {
                isPaginationEnable = true
            }else{
                isPaginationEnable = false
            }
            for i in result {
                if i.is_read != "3" && i.sender != UserDefaults.standard.userID! {
                    let dict = ["is_read":"3","id":i.id,"sender":i.sender,"updated_at":Date().millisecondsSince1970] as [String:Any]
                    self.changeStatus(dict:dict)
                }
            }
            self.chatMsgsArray += result
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
        self.sendChatMsg(msg: textViewSenderChat.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), msgType: 0)
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        _ = appdelegate.objAPI.updateUnReadMsgCount(self.chatObj!.chatid)
        for i in self.navigationController!.viewControllers{
            if i is ChatListViewController{
                if privateMsgSent {
                    appdelegate.persistentContainer.viewContext.delete(self.chatObj!)
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
    func sendChatMsg(msg : String,msgType : Int, mediaURL : String = ""){
        
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        if let currentIndex = receiverArray?.firstIndex(where: { Int64($0)! == UserDefaults.standard.userID!}){
            receiverArray?.remove(at: currentIndex)
        }
        
        let params = ["channelType" : chatObj!.channelType!,
                      "message": msg,
                      "is_read": "0",
                      "chat_id": chatObj!.chatid,
                      "sender": UserDefaults.standard.userID!,
                      "receiver" : receiverArray!.joined(separator: ","),
                      "created_at" : Date().millisecondsSince1970,
                      "updated_at" : Date().millisecondsSince1970,
                      "id" : Date().millisecondsSince1970,
                      "msgtype" : msgType,
                      "mediaurl" : mediaURL,
                      "name": chatObj!.channelType! == "1" ? chatObj!.channelName! : UserDefaults.standard.userName!,
                      "photo":chatObj!.channelType! == "1" ? chatObj!.channelPic! : UserDefaults.standard.userPhoto!,
                      "name":UserDefaults.standard.userName!] as [String : Any]
        
        appdelegate.objAPI.sendMessage(params) { (response, error) in
            if let error = error {
                print(error)
            }else{
                if let responseData = response {
                    if let objMsg = appdelegate.objAPI.insertMessage(dict: responseData){
                        self.chatObj!.created_at = objMsg.created_at
                        self.chatObj!.last_message = objMsg.message!
                        self.chatObj!.updated_at = objMsg.updated_at
                        
                        let updated = appdelegate.objAPI.checkChannelAvailable(self.chatObj!)
                        if updated {
                            self.privateMsgSent = false
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
    
    func openActionSheet(){
        let alert = UIAlertController(title: "ChatDemo", message: "Please Select an Option", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default , handler:{ (UIAlertAction)in
            openImageViewPicker(isOpenGallery: .camera,viewController: self)
        }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default , handler:{ (UIAlertAction)in
            openImageViewPicker(isOpenGallery: .photoLibrary,viewController: self)
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
    
    func openDocumentViewController(){
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.text", "com.apple.iwork.pages.pages", "public.data"], in: .import)
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    //MARK:- ImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var imagePath : String = ""
        var mediaTypeIndex : Int = 0
        
        picker.dismiss(animated: true, completion: { () -> Void in
            if let chosenImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
                imagePath = saveImageIntoDocumentDirectory(chosenImage) ?? ""
                mediaTypeIndex = 1
            }else if let mediaPath = info[UIImagePickerController.InfoKey.mediaURL] as? URL{
                imagePath = moveFile(filepath: mediaPath)?.path ?? ""
                mediaTypeIndex = 2
            }
            callUploadMediaAPI(path: imagePath,completion: { (jsonData,error) in
                if let mediaUrl = jsonData!["filename"] as? String{
                    self.sendChatMsg(msg: "", msgType: mediaTypeIndex, mediaURL: mediaUrl)
                }
            })
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    

    
}

extension ChatViewController {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        controller.dismiss(animated: true) {
            if let urlFile = moveFile(filepath: url) {
                callUploadMediaAPI(path: urlFile.path,completion: { (jsonData,error) in
                    if let mediaUrl = jsonData!["filename"] as? String{
                        self.sendChatMsg(msg: "", msgType: 3, mediaURL: mediaUrl)
                    }
                })
            }
        }
    }
}

extension ChatViewController : ReceiveMessage{
    
    func updateStatus(data: [String : Any]) {
        if let index = self.chatMsgsArray.firstIndex(where: {$0.id == data["id"] as? Int64}){
            let obj = self.chatMsgsArray[index]
            if Int(obj.is_read!)! < Int(data["is_read"] as! String)!{
                obj.is_read = data["is_read"] as? String
                self.chatMsgsArray[index] = obj
            }
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
        if (msg.chat_id == chatObj?.chatid){
            self.chatMsgsArray.append(msg)
            self.tableView.reloadData()
            self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
            let dict = ["is_read":"3","id":msg.id,"sender":msg.sender,"updated_at":Date().millisecondsSince1970] as [String:Any]
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.changeStatus(dict: dict)
            })
        }
    }
    
    func changeStatus(dict : [String:Any]){
        appdelegate.objAPI.emitStatus(dict)
    }
    
    func getReceiverID() -> String {
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        
        if let currentIndex = receiverArray?.firstIndex(where: { Int64($0)! == UserDefaults.standard.userID!}){
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
        switch chatObj.msgtype {
        case 0:
            return configureTextCell(chatObj,index: indexPath.row)
        case 1:
            return configureImageCell(chatObj,index: indexPath.row)
        case 2:
            return configureImageCell(chatObj,index: indexPath.row)
        case 3:
            return configureImageCell(chatObj,index: indexPath.row)
        default:
            return UITableViewCell()
        }
    }
    
    func configureImageCell(_ chatObjMsg:ChatMessages, index:Int) -> UITableViewCell {
        if UserDefaults.standard.userID! == chatObjMsg.sender{
            let senderCell = tableView.dequeueReusableCell(withIdentifier: "ChatSenderCellMedia") as! ChatSenderCell
            senderCell.btnShowPreview.tag = index
            senderCell.lblTime.text = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime()
            
            senderCell.btnShowPreview.setImage(nil, for: .normal)
            let downloadURl = URL.init(string: chatObjMsg.mediaurl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
            
            switch chatObjMsg.msgtype {
            case 1:
                senderCell.imgDownload.sd_setImage(with: downloadURl, placeholderImage: UIImage(named: "placeholder"))
                senderCell.btnShowPreview.setImage(nil, for: .normal)
            case 2:
                let image = cacheImages.object(forKey:downloadURl.lastPathComponent as NSString)
                if image == nil {
                    AVAsset(url: downloadURl).generateThumbnail { [weak self] (image) in
                        DispatchQueue.main.async {
                            if let image = image {
                                self?.cacheImages.setObject(image, forKey: downloadURl.lastPathComponent as NSString)
                            }
                            senderCell.imgDownload.image = image
                        }
                    }
                }else{
                    senderCell.imgDownload.image = image
                }
                senderCell.btnShowPreview.setImage(#imageLiteral(resourceName: "play-button"), for: .normal)
            case 3:
                self.imageFromServerURL(downloadURl, placeHolder: nil, completion: { (image) in
                    senderCell.imgDownload.image = image
                })
                senderCell.btnShowPreview.setImage(#imageLiteral(resourceName: "document"), for: .normal)
            default:
                break
            }
            
            senderCell.btnShowPreview.addTarget(self, action: #selector(playVideo(_:)), for: .touchUpInside)
            switch chatObjMsg.is_read {
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
            
            let receiverCell = tableView.dequeueReusableCell(withIdentifier: "ChatReceiverCellMedia") as! ChatReceiverCell
            receiverCell.lblTime.text = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime()
            
            receiverCell.btnShowPreview.tag = index
            let downloadURl = URL.init(string: chatObjMsg.mediaurl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
            if self.chatObj?.channelType == "0" {
                receiverCell.lblName.text = ""
            }else{
                receiverCell.lblName.text = chatObjMsg.name
            }
            switch chatObjMsg.msgtype {
            case 1:
                receiverCell.imgDownload.sd_setImage(with: downloadURl, placeholderImage: UIImage(named: "placeholder"))
                receiverCell.btnShowPreview.setImage(nil, for: .normal)
            case 2:
                let image = cacheImages.object(forKey:downloadURl.lastPathComponent as NSString)
                if image == nil {
                    AVAsset(url: downloadURl).generateThumbnail { [weak self] (image) in
                        DispatchQueue.main.async {
                            if let image = image {
                                self?.cacheImages.setObject(image, forKey: downloadURl.lastPathComponent as NSString)
                            }
                            receiverCell.imgDownload.image = image
                        }
                    }
                }else{
                    receiverCell.imgDownload.image = image
                }
                receiverCell.btnShowPreview.setImage(#imageLiteral(resourceName: "play-button"), for: .normal)
            case 3:
                self.imageFromServerURL(downloadURl, placeHolder: nil, completion: { (image) in
                    receiverCell.imgDownload.image = image
                })
                receiverCell.btnShowPreview.setImage(#imageLiteral(resourceName: "document"), for: .normal)
            default:
                break
            }
            
            receiverCell.btnShowPreview.addTarget(self, action: #selector(playVideo(_:)), for: .touchUpInside)
            return receiverCell
        }
    }
    
    @objc func playVideo(_ sender:UIButton) -> Void {
        let chatObj = self.chatMsgsArray[sender.tag]
        switch chatObj.msgtype {
        case 1:
            self.performSegue(withIdentifier: "ImgDocView", sender: chatObj.mediaurl)
            break
        case 2:
            let player = AVPlayer(url: URL.init(string: chatObj.mediaurl ?? "")!)
            let vc = AVPlayerViewController()
            vc.player = player
            present(vc, animated: true) {
                vc.player?.play()
            }
            break
        case 3:
            self.performSegue(withIdentifier: "ImgDocView", sender: chatObj.mediaurl)
            break
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ImgDocumentOpenViewController{
            vc.imgDocUrl = sender as? String
        }
    }
    
    func configureTextCell(_ chatObjMsg:ChatMessages,index:Int) -> UITableViewCell {
        if UserDefaults.standard.userID! == chatObjMsg.sender{
            let senderCell = tableView.dequeueReusableCell(withIdentifier: "ChatSenderCell") as! ChatSenderCell
            senderCell.lblChatSenderMsg.text = chatObjMsg.message
            senderCell.lblTime.text = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime()
            
            switch chatObjMsg.is_read {
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
            let receiverCell = tableView.dequeueReusableCell(withIdentifier: "ChatReceiverCell") as! ChatReceiverCell
            receiverCell.lblChatReceiverMsg.text = chatObjMsg.message
            receiverCell.lblTime.text = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime()
            if self.chatObj?.channelType == "0" {
                receiverCell.lblName.text = ""
            }else{
                receiverCell.lblName.text = chatObjMsg.name
            }
            return receiverCell
        }
    }
}

extension ChatViewController : UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        if let currentIndex = receiverArray?.firstIndex(where: {Int64($0)! == UserDefaults.standard.userID!}){
            receiverArray?.remove(at: currentIndex)
        }
        let param = ["sender": UserDefaults.standard.userID!, "receiver": receiverArray!.joined(separator: ",")] as [String : Any]
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

extension ChatViewController {
    
    //MARK:- ScrollView Method
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 500 && isPaginationEnable {
            page += 1
            self.loadCurrentConversationMessages()
        }
    }
}

extension ChatViewController : UIDocumentInteractionControllerDelegate{
    
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    public func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {}
}

extension ChatViewController {
    
    func imageFromServerURL(_ url: URL, placeHolder: UIImage? , completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = cacheImages.object(forKey: url.lastPathComponent as NSString) {
            completion(cachedImage)
            return
        }
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if error != nil {
                print("ERROR LOADING IMAGES FROM URL: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                if let data = data {
                    guard let page = PDFDocument(data: data)?.page(at: 0) else {
                        completion(nil)
                        return
                    }
                    let pageSize = page.bounds(for: .cropBox)
                    let pdfScale = 100 / pageSize.width
                    
                    // Apply if you're displaying the thumbnail on screen
                    let scale = UIScreen.main.scale * pdfScale
                    let screenSize = CGSize(width: pageSize.width * scale,
                                            height: pageSize.height * scale)
                    
                    let image =  page.thumbnail(of: screenSize, for: .cropBox)
                    self.cacheImages.setObject(image, forKey: url.lastPathComponent as NSString)
                    completion(image)
                }
            }
        }).resume()
    }
}

func callUploadMediaAPI(path : String, completion : @escaping completionHandler){
    MTPLAPIManager.shared.upload(ChatURLManager.file_upload, parameter: nil, videoPath: [path], filekey: "file") { (objData, error) in
        if let error = error{
            print(error)
            completion(nil,"wrongJson")
        }else{
            
            guard let data = objData else { return }
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]{
//                    let fileManager = FileManager.default
//                    fileManager.clearDocumentDirectory()
                    completion(jsonData,nil)
                }else{
                    completion(nil,"wrongJson")
                }
            }catch{
                completion(nil,"wrongJson")
            }
        }
    }
}
