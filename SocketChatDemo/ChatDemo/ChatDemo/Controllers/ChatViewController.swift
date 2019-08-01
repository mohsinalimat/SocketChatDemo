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
    var msgSent : Bool = false
    
    var page : Int = 0
    var isPaginationEnable : Bool = false
    var pagelimit = 300
    var cacheImages = NSCache<NSString,UIImage>()
    
    
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
        _ = appdelegate.objAPI.updateUnReadMsgCount(self.chatObj!.chatid!)
        self.loadCurrentConversationMessages()
    }
    
    func loadCurrentConversationMessages() {
        let fetchRequest = NSFetchRequest<ChatMessages>(entityName: "ChatMessages")
        fetchRequest.predicate = NSPredicate(format: "chat_id == '\(chatObj!.chatid!)'")
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
                    let dict = ["is_read":"3","id":i.id!,"sender":i.sender!,"updated_at":Date().millisecondsSince1970] as [String:Any]
                    self.changeStatus(dict:dict)
                }
            }
            self.msgSent = result.count > 0
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
    func sendChatMsg(msg : String,msgType : Int, mediaURL : String = ""){
        
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        
        if let currentIndex = receiverArray?.firstIndex(where: {$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == UserDefaults.standard.userID!}){
            receiverArray?.remove(at: currentIndex)
        }
        
        let params = ["channelType" : "0",
                      "message": msg,
                      "is_read": "0",
                      "chat_id": chatObj!.chatid!,
                      "sender": UserDefaults.standard.userID!,
                      "receiver" : receiverArray!.joined(separator: ","),
                      "created_at" : Date().millisecondsSince1970,
                      "updated_at" : Date().millisecondsSince1970,
                      "id" : "\(Date().millisecondsSince1970)\(chatObj!.chatid!)",
            "msgtype" : msgType,
            "mediaurl" : mediaURL] as [String : Any]
        
        appdelegate.objAPI.sendMessage(params) { (response, error) in
            if let error = error {
                print(error)
            }else{
                if let responseData = response {
                    if let objMsg = appdelegate.objAPI.insertMessage(dict: responseData){
                        
                        let array = [["channelName":self.chatObj!.channelName!,
                                      "channelType":self.chatObj!.channelType!,
                                      "chatid":self.chatObj!.chatid!,
                                      "created_at":objMsg.created_at,
                                      "last_message":objMsg.message!,
                                      "updated_at":objMsg.updated_at,
                                      "userIds":self.chatObj!.userIds! ]] as [[String:Any]]
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
                imagePath = mediaPath.path
                mediaTypeIndex = 2
            }
            self.callUploadMediaAPI(path: imagePath , mediaType: mediaTypeIndex)
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func callUploadMediaAPI(path : String , mediaType : Int){
        MTPLAPIManager.shared.upload(ChatURLManager.file_upload, parameter: nil, videoPath: [path], filekey: "file") { (objData, error) in
            if let error = error{
                print(error)
            }else{
                
                guard let data = objData else { return }
                do{
                    if let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]{
                        if let mediaUrl = jsonData["filename"] as? String{
                            self.sendChatMsg(msg: "", msgType: mediaType, mediaURL: mediaUrl)
                        }
                    }
                }catch{}
            }
        }
    }
    
}

extension ChatViewController {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        controller.dismiss(animated: true) {
            if let urlFile = moveFile(filepath: url) {
                self.callUploadMediaAPI(path: urlFile.path, mediaType: 3)
            }
        }
    }
}

extension ChatViewController : ReceiveMessage{
    func updateStatus(data: [String : Any]) {
        if let index = self.chatMsgsArray.firstIndex(where: {$0.id == data["id"] as? String}){
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
        if (msg.sender == self.getReceiverID()){
            self.chatMsgsArray.append(msg)
            self.tableView.reloadData()
            self.tableView.scrollToBottom(index: self.chatMsgsArray.count - 1)
            let dict = ["is_read":"3","id":msg.id!,"sender":msg.sender!,"updated_at":Date().millisecondsSince1970] as [String:Any]
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
    
    
    func configureImageCell(_ chatObj:ChatMessages, index:Int) -> UITableViewCell {
        if UserDefaults.standard.userID! == chatObj.sender{
            let senderCell = tableView.dequeueReusableCell(withIdentifier: "ChatSenderCellMedia") as! ChatSenderCell
            senderCell.btnShowPreview.tag = index
            senderCell.lblTime.text = "\(chatObj.created_at)".timeStampToLocalDate().getLocalTime()
            //senderCell.imgDownload.sd_setImage(with: URL(string: chatObj.mediaurl ?? ""), placeholderImage: UIImage(named: "placeholder"))
            senderCell.btnShowPreview.setImage(nil, for: .normal)
            let downloadURl = URL.init(string: chatObj.mediaurl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
            senderCell.imgDownload.image = self.pdfThumbnail(url: downloadURl)
//            let image = cacheImages.object(forKey:downloadURl.lastPathComponent as NSString)
//            if image == nil {
//                AVAsset(url: downloadURl).generateThumbnail { [weak self] (image) in
//                    DispatchQueue.main.async {
//                        if let image = image {
//                            self?.cacheImages.setObject(image, forKey: downloadURl.lastPathComponent as NSString)
//                        }
//                        senderCell.imgDownload.image = image
//                    }
//                }
//            }else{
//                senderCell.imgDownload.image = image as? UIImage
//            }
            senderCell.btnShowPreview.addTarget(self, action: #selector(playVideo(_:)), for: .touchUpInside)
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
            
            let receiverCell = tableView.dequeueReusableCell(withIdentifier: "ChatReceiverCellMedia") as! ChatReceiverCell
            receiverCell.lblTime.text = "\(chatObj.created_at)".timeStampToLocalDate().getLocalTime()
            //receiverCell.imgDownload.sd_setImage(with: URL(string: chatObj.mediaurl ?? ""), placeholderImage: UIImage(named: "placeholder"))
            receiverCell.btnShowPreview.setImage(nil, for: .normal)
            receiverCell.btnShowPreview.tag = index
            let downloadURl = URL.init(string: chatObj.mediaurl ?? "")!
            receiverCell.imgDownload.image = self.pdfThumbnail(url: downloadURl)

//            let image = cacheImages.object(forKey:downloadURl.lastPathComponent as NSString)
//            if image == nil {
//                AVAsset(url: downloadURl).generateThumbnail { [weak self] (image) in
//                    DispatchQueue.main.async {
//                        if let image = image {
//                            //if let resizeImage = self?.resizeImage(image: image, targetSize: CGSize.init(width: 100, height: 100)) {
//                                self?.cacheImages.setObject(image, forKey: downloadURl.lastPathComponent as NSString)
//
//                            //}
//                        }
//                        receiverCell.imgDownload.image = image
//                    }
//                }
//            }else{
//                receiverCell.imgDownload.image = image as? UIImage
//            }
            receiverCell.btnShowPreview.addTarget(self, action: #selector(playVideo(_:)), for: .touchUpInside)
            return receiverCell
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width:size.width * heightRatio,height:size.height * heightRatio)
        } else {
            newSize = CGSize(width:size.width * widthRatio,height:size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x:0, y:0, width:newSize.width, height:newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    @objc func playVideo(_ sender:UIButton) -> Void {
        let chatObj = self.chatMsgsArray[sender.tag]
        let player = AVPlayer(url: URL.init(string: chatObj.mediaurl ?? "")!)
        let vc = AVPlayerViewController()
        vc.player = player
        
        present(vc, animated: true) {
            vc.player?.play()
        }
    }
    
    func configureTextCell(_ chatObj:ChatMessages,index:Int) -> UITableViewCell {
        if UserDefaults.standard.userID! == chatObj.sender{
            let senderCell = tableView.dequeueReusableCell(withIdentifier: "ChatSenderCell") as! ChatSenderCell
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
            let receiverCell = tableView.dequeueReusableCell(withIdentifier: "ChatReceiverCell") as! ChatReceiverCell
            receiverCell.lblChatReceiverMsg.text = chatObj.message
            receiverCell.lblTime.text = "\(chatObj.created_at)".timeStampToLocalDate().getLocalTime()
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
    
    func pdfThumbnail(url: URL, width: CGFloat = 100) -> UIImage? {
        guard let data = try? Data(contentsOf: url),
            let page = PDFDocument(data: data)?.page(at: 0) else {
                return nil
        }
        
        let pageSize = page.bounds(for: .cropBox)
        let pdfScale = width / pageSize.width
        
        // Apply if you're displaying the thumbnail on screen
        let scale = UIScreen.main.scale * pdfScale
        let screenSize = CGSize(width: pageSize.width * scale,
                                height: pageSize.height * scale)
        
        return page.thumbnail(of: screenSize, for: .cropBox)
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


extension AVAsset {
    
    func generateThumbnail(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            let imageGenerator = AVAssetImageGenerator(asset: self)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let times = [NSValue(time: time)]
            imageGenerator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { _, image, _, _, _ in
                if let image = image {
                    completion(UIImage(cgImage: image))
                } else {
                    completion(nil)
                }
            })
        }
    }
}
