//
//  ConversationViewController.swift
//  VChat
//
//  Created by vishal on 8/16/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa
import SDWebImage
import AVKit
import AVFoundation
import PDFKit

protocol InitiateChatDelegate {
    func initiateChat(_ objChat : ChatList, isFirstTimePrivateChat : Bool) -> Void
}

class SenderTableCellView: NSTableCellView {
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var lblTime: NSTextField!
    @IBOutlet weak var imgTick: NSImageView!
    @IBOutlet weak var imgViewMedia: NSImageView!
    @IBOutlet weak var viewBoxSender: NSBox!
    
}

class ReceiverTableCellView: NSTableCellView {
    @IBOutlet weak var heightConstraintsName: NSLayoutConstraint!
    @IBOutlet weak var lblName: NSTextField!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var lblTime: NSTextField!
    @IBOutlet weak var imgViewMedia: NSImageView!
    @IBOutlet weak var viewBoxReceiver: NSBox!
}


class ConversationViewController: NSViewController,InitiateChatDelegate,NSWindowDelegate {
    
    var chatObj : ChatList?
    var chatMsgsArray = [ChatMessages]()
    var page : Int = 0
    var isPaginationEnable : Bool = false
    var pagelimit = 300
    var cacheImages = NSCache<NSString,NSImage>()
    var privateMsgSent = false
    @IBOutlet weak var txtMessage: NSTextField!
    
    @IBOutlet weak var tableScrollView: NSScrollView!
    @IBOutlet weak var BottomBox: NSBox!
    @IBOutlet weak var btnAttachment: NSButton!
    @IBOutlet weak var columnTabl: NSTableColumn!
    @IBOutlet weak var tableConversation: NSTableView!
    @IBOutlet weak var imgReceiverProfile: NSImageView!
    @IBOutlet weak var lblReceiverName: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnAttachment.isHidden = true
        self.BottomBox.isHidden = true
        self.tableScrollView.isHidden = true
        appdelegate.objAPI.delegate = self
        tableConversation.selectionHighlightStyle = .none
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.delegate = self
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        DispatchQueue.main.async {
            self.columnTabl.width = self.view.frame.size.width
            self.columnTabl.minWidth = self.view.frame.size.width
            self.columnTabl.maxWidth = self.view.frame.size.width
            self.tableConversation.reloadData()
        }
        DispatchQueue.main.async {
            self.tableConversation.scrollRowToVisible(self.chatMsgsArray.count-1)
        }
        return frameSize
    }
    
    func windowDidResize(_ notification: Notification) {
        DispatchQueue.main.async {
            self.columnTabl.width = self.view.frame.size.width
            self.columnTabl.minWidth = self.view.frame.size.width
            self.columnTabl.maxWidth = self.view.frame.size.width
            self.tableConversation.reloadData()
        }
        DispatchQueue.main.async {
            self.tableConversation.scrollRowToVisible(self.chatMsgsArray.count-1)
        }
    }
    
    func initiateChat(_ objChat: ChatList, isFirstTimePrivateChat: Bool) {
        chatObj = objChat
        privateMsgSent = isFirstTimePrivateChat
        self.chatMsgsArray.removeAll()
        self.isPaginationEnable = false
        cacheImages.removeAllObjects()
        self.page = 0
        self.tableConversation.reloadData()
        self.tableConversation.isHidden = true
        self.btnAttachment.isHidden = false
        self.BottomBox.isHidden = false
        self.tableScrollView.isHidden = false
        DispatchQueue.main.async {
            self.setUpUI()
        }
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        (self.parent?.children[0] as! DashboardViewController).scrollTableDropDown.isHidden = true
    }
    
    @IBAction func btnAttachment(_ sender: NSButton) {
        let dialog = NSOpenPanel()
        dialog.title                   = "Choose file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["jpeg","png","jpg","pdf","mov","mp4"];

        if (dialog.runModal() == .OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                callUploadMediaAPI(path: path) { (jsonData, error) in
                    if let error = error {
                        print(error)
                    }else{
                        if let mediaUrl = jsonData!["filename"] as? String{
                            var index = 0
                            if ["jpeg","png","jpg"].contains(result?.pathExtension){
                                index = 1
                            }else if ["mov","mp4"].contains(result?.pathExtension){
                                index = 2
                            }else if result?.pathExtension == "pdf"{
                                index = 3
                            }
                            if index > 0{
                                self.sendChatMsg(msg: "", msgType: index, mediaURL: mediaUrl)
                            }
                        }
                    }
                }
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    
    func setUpUI(){
        self.lblReceiverName.stringValue = chatObj?.channelName ?? ""
        let downloadURl = URL.init(string: chatObj?.channelPic?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
        self.imgReceiverProfile.sd_setImage(with: downloadURl, placeholderImage: #imageLiteral(resourceName: "user"))
        DispatchQueue.main.async {
            self.imgReceiverProfile.layer?.cornerRadius = self.imgReceiverProfile.frame.size.height/2
        }
        columnTabl.width = tableConversation.frame.size.width
        columnTabl.minWidth = tableConversation.frame.size.width
        columnTabl.maxWidth = tableConversation.frame.size.width
        _ = appdelegate.objAPI.updateUnReadMsgCount(self.chatObj!.chatid)
        
        (self.parent?.children[0] as! DashboardViewController).receiveChnl()
        self.loadCurrentConversationMessages()
    }
    
    func loadCurrentConversationMessages() {
        let fetchRequest = NSFetchRequest<ChatMessages>(entityName: "ChatMessages")
        fetchRequest.predicate = NSPredicate(format: "chat_id == \(chatObj!.chatid)")
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
                    let dict = ["is_read":"3","id":i.id,"sender":i.sender] as [String:Any]
                    self.changeStatus(dict:dict)
                }
            }
            self.chatMsgsArray += result
            self.tableConversation.isHidden = false
            self.tableConversation.reloadData()
            DispatchQueue.main.async {
                let point = NSPoint(x: 0, y: self.tableConversation.frame.height)
                self.tableConversation.scroll(point)
            }
        } catch {
            print("error executing fetch request: \(error.localizedDescription)")
            return
        }
    }
    
    
    @IBAction func btnSendAction(_ sender: NSButton) {
        if txtMessage.stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
            return
        }
        self.sendChatMsg(msg: txtMessage.stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), msgType: 0)
    }
    
    
    
    //MARK:- API Call
    func sendChatMsg(msg : String,msgType : Int, mediaURL : String = ""){
        var receiverArray = chatObj?.userIds?.components(separatedBy: ",")
        if let currentIndex = receiverArray?.firstIndex(where: { Int64($0)! == UserDefaults.standard.userID!}){
            receiverArray?.remove(at: currentIndex)
        }
        
        if chatObj?.channelType == "3" {
            sendPrivateAndGroupMsg(msg: msg, msgType: msgType, mediaURL: mediaURL)
            var broadCastMsg = [[String : Any]]()
            for receiverid in receiverArray ?? [] {
                
                let params = ["channelType" : "1",
                              "message": msg,
                              "is_read": "0",
                              "chat_id": "",
                              "sender": UserDefaults.standard.userID!,
                              "receiver" : receiverid,
                              "id" : "",
                              "msgtype" : msgType,
                              "mediaurl" : mediaURL,
                              "name": UserDefaults.standard.userName!,
                              "photo": UserDefaults.standard.userPhoto!,
                              "senderName":UserDefaults.standard.userName!,
                              "created_at":""] as [String : Any]
                broadCastMsg.append(params)
            }
            if broadCastMsg.count > 0{
                sendBroadcastMsg(params: broadCastMsg)
            }
        }else{
            sendPrivateAndGroupMsg(msg: msg, msgType: msgType, mediaURL: mediaURL)
        }
    }
    
    func fetchUserData(userID:String) -> LoginUser?{
        let fetchRequest = NSFetchRequest<LoginUser>(entityName: "LoginUser")
        fetchRequest.predicate = NSPredicate(format: "id = \(userID)")
        do {
            let result = try appdelegate.persistentContainer.viewContext.fetch(fetchRequest)
            if result.count == 1 {
                return result [0]
            }else{
                return nil
            }
        }catch{
            return nil
        }
    }
    
    func sendPrivateAndGroupMsg(msg : String,msgType : Int, mediaURL : String = "") -> Void {
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
                      "id" : Date().millisecondsSince1970,
                      "msgtype" : msgType,
                      "mediaurl" : mediaURL,
                      "name": chatObj!.channelType! != channelTypeCase.privateChat.rawValue ? chatObj!.channelName! : UserDefaults.standard.userName!,
                      "photo":chatObj!.channelType! != channelTypeCase.privateChat.rawValue ? chatObj!.channelPic! : UserDefaults.standard.userPhoto!,
                      "senderName":UserDefaults.standard.userName!,
                      "created_at":"",
                      "updated_at":""] as [String : Any]
        
        appdelegate.objAPI.sendMessage(params) { (response, error) in
            if let error = error {
                print(error)
            }else{
                if let responseData = response {
                    if let objMsg = appdelegate.objAPI.insertMessage(dict: responseData){
                        if self.chatObj!.created_at == 0.0 {
                            self.chatObj!.created_at = objMsg.created_at
                        }
                        self.chatObj!.last_message = objMsg.message!
                        self.chatObj!.updated_at = objMsg.created_at
                        
                        let updated = appdelegate.objAPI.checkChannelAvailableInModel(self.chatObj!,isUpdatedUnread: false)
                        if updated {
                            
                            self.privateMsgSent = false
                            self.chatMsgsArray.append(objMsg)
                            self.tableConversation.insertRows(at: IndexSet.init(integer: self.chatMsgsArray.count-1), withAnimation: .effectFade)
                            let indexset = IndexSet.init(integer: self.chatMsgsArray.count-1)
                            let indexset1 = IndexSet(integer: 0)
                            self.tableConversation.reloadData(forRowIndexes: indexset, columnIndexes: indexset1)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                                self.tableConversation.scrollToBottom(index: self.chatMsgsArray.count-1)
                            })
                            self.txtMessage.stringValue = ""
                            (self.parent?.children[0] as! DashboardViewController).checkDataAvailable()
                        }
                    }
                }
            }
        }
    }
    
    func sendBroadcastMsg(params:[[String:Any]]) -> Void {
        
        appdelegate.objAPI.sendBroadcastMessage(params) { (response, error) in
            if let error = error {
                print(error)
            }else{
                if let responseData = response {
                    print(responseData)
                    for data in responseData{
                        if let objMsg = appdelegate.objAPI.insertMessage(dict: data){
                            guard let user = self.fetchUserData(userID: data["receiver"] as! String) else { return }
                            var params = ["channelName":user.name!,
                                          "channelPic":user.photo!,
                                          "channelType":"1",
                                          "chatid":objMsg.chat_id,
                                          "last_message":objMsg.message!,
                                          "unreadcount":0,
                                          "updated_at":objMsg.created_at,
                                          "userIds": "\(objMsg.sender),\(objMsg.receiver!)"] as [String : Any]
                            if appdelegate.objAPI.checkGetExist(objMsg.chat_id) == nil {
                                params["created_at"] = objMsg.created_at
                            }
                            let channel = appdelegate.objAPI.checkChannelAvailable([params], isUpdatedUnread: false)
                            if channel {
                                print("inserted")
                            }
                        }
                    }
                    (self.parent?.children[0] as! DashboardViewController).checkDataAvailable()
                    print("broadcast process done")
                }
            }
        }
    }
}

extension ConversationViewController : ReceiveMessage{
    
    func updateStatus(data: [String : Any]) {
        if let index = self.chatMsgsArray.firstIndex(where: {$0.id == data["id"] as? Int64}){
            let obj = self.chatMsgsArray[index]
            if Int(obj.is_read!)! < Int(data["is_read"] as! String)!{
                obj.is_read = data["is_read"] as? String
                self.chatMsgsArray[index] = obj
            }
            let indexset = IndexSet(integer: index)
            let indexset1 = IndexSet(integer: 0)
            self.tableConversation.reloadData(forRowIndexes: indexset, columnIndexes: indexset1)
        }
    }
    
    func typingMsg(data: [String : Any]) {
//        if (data["sender"] as? String == self.getReceiverID()){
//            self.navigationItem.title = "Typing..."
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                self.navigationItem.title = self.chatObj?.channelName
//            }
//        }
    }
    
    func receiveMsg(msg: ChatMessages) {
        if (msg.chat_id == chatObj?.chatid){
            self.chatMsgsArray.append(msg)
            self.tableConversation.insertRows(at: IndexSet.init(integer: self.chatMsgsArray.count-1), withAnimation: .effectFade)
            let indexset = IndexSet.init(integer: self.chatMsgsArray.count-1)
            let indexset1 = IndexSet(integer: 0)
            self.tableConversation.reloadData(forRowIndexes: indexset, columnIndexes: indexset1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.tableConversation.scrollToBottom(index: self.chatMsgsArray.count-1)
            })
            let dict = ["is_read":"3","id":msg.id,"sender":msg.sender] as [String:Any]
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

extension ConversationViewController : NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return chatMsgsArray.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let message = chatMsgsArray[row]
        switch message.msgtype {
        case 0:
            return configureTextCell(tableView,chatObjMsg: message,index: row)
        case 1:
            return configureImageCell(tableView,chatObjMsg:message,index: row)
        case 2:
            return configureImageCell(tableView,chatObjMsg:message,index: row)
        case 3:
            return configureImageCell(tableView,chatObjMsg:message,index: row)
        default:
            return nil
        }
    }
    
    func configureTextCell(_ tableView:NSTableView, chatObjMsg:ChatMessages,index:Int) -> NSView? {
        if UserDefaults.standard.userID! == chatObjMsg.sender{
            let senderCell:SenderTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SenderTableCellView"), owner: self) as! SenderTableCellView
            senderCell.lblMessage.stringValue = chatObjMsg.message ?? ""
            senderCell.lblTime.stringValue = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime() ?? ""
            DispatchQueue.main.async {
                senderCell.viewBoxSender.layer?.cornerRadius = 5.0
            }
            switch chatObjMsg.is_read {
            case "0":
                senderCell.imgTick.image = nil
                break
            case "1":
                senderCell.imgTick.image = #imageLiteral(resourceName: "single_tick")
                senderCell.imgTick.contentTintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                break
            case "2":
                senderCell.imgTick.image = #imageLiteral(resourceName: "tick_grey")
                senderCell.imgTick.contentTintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                break
            case "3":
                senderCell.imgTick.image = #imageLiteral(resourceName: "tick_blue")
                senderCell.imgTick.contentTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                break
            default:
                senderCell.imgTick.image = nil
                break
            }
            return senderCell
        }else{
            let receiverCell:ReceiverTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ReceiverTableCellView"), owner: self) as! ReceiverTableCellView
            DispatchQueue.main.async {
                receiverCell.viewBoxReceiver.layer?.cornerRadius = 5.0
            }
            receiverCell.lblMessage.stringValue = chatObjMsg.message ?? ""
            receiverCell.lblTime.stringValue = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime() ?? ""
            if self.chatObj?.channelType == channelTypeCase.privateChat.rawValue {
                receiverCell.lblName.stringValue = ""
                receiverCell.heightConstraintsName.constant = 0
            }else{
                receiverCell.lblName.stringValue = chatObjMsg.senderName ?? ""
                receiverCell.heightConstraintsName.constant = 20
            }
            return receiverCell
        }
    }
    
    func configureImageCell(_ tableView:NSTableView, chatObjMsg:ChatMessages, index:Int) -> NSView? {
        if UserDefaults.standard.userID! == chatObjMsg.sender{
            let senderCell:SenderTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SenderTableCellViewImage"), owner: self) as! SenderTableCellView
            DispatchQueue.main.async {
                senderCell.viewBoxSender.layer?.cornerRadius = 5.0
            }
            //senderCell.btnShowPreview.tag = index
            senderCell.lblTime.stringValue = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime() ?? ""

            //senderCell.btnShowPreview.setImage(nil, for: .normal)
            let downloadURl = URL.init(string: chatObjMsg.mediaurl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!

            switch chatObjMsg.msgtype {
            case 1:
                senderCell.imgViewMedia.sd_setImage(with: downloadURl, placeholderImage: NSImage(named: "placeholder"))
                //senderCell.btnShowPreview.setImage(nil, for: .normal)
            case 2:
                let image = cacheImages.object(forKey:downloadURl.lastPathComponent as NSString)
                if image == nil {
                    AVAsset(url: downloadURl).generateThumbnail { [weak self] (image) in
                        DispatchQueue.main.async {
                            if let image = image {
                                self?.cacheImages.setObject(image, forKey: downloadURl.lastPathComponent as NSString)
                            }
                            senderCell.imgViewMedia.image = image
                        }
                    }
                }else{
                    senderCell.imgViewMedia.image = image
                }
                //senderCell.btnShowPreview.setImage(#imageLiteral(resourceName: "play-button"), for: .normal)
            case 3:
                self.imageFromServerURL(downloadURl, placeHolder: nil, completion: { (image) in
                    senderCell.imgViewMedia.image = image
                })
                //senderCell.btnShowPreview.setImage(#imageLiteral(resourceName: "document"), for: .normal)
            default:
                break
            }

            //senderCell.btnShowPreview.addTarget(self, action: #selector(playVideo(_:)), for: .touchUpInside)
            switch chatObjMsg.is_read {
            case "0":
                senderCell.imgTick.image = nil
                break
            case "1":
                senderCell.imgTick.image = #imageLiteral(resourceName: "single_tick")
                senderCell.imgTick.contentTintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                break
            case "2":
                senderCell.imgTick.image = #imageLiteral(resourceName: "tick_grey")
                senderCell.imgTick.contentTintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                break
            case "3":
                senderCell.imgTick.image = #imageLiteral(resourceName: "tick_blue")
                senderCell.imgTick.contentTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                break
            default:
                senderCell.imgTick.image = nil
                break
            }
            return senderCell
        }else{

            let receiverCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ReceiverTableCellViewImage"), owner: self) as! ReceiverTableCellView
            DispatchQueue.main.async {
                receiverCell.viewBoxReceiver.layer?.cornerRadius = 5.0
            }
            receiverCell.lblTime.stringValue = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime() ?? ""

            //receiverCell.btnShowPreview.tag = index
            let downloadURl = URL.init(string: chatObjMsg.mediaurl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
            if self.chatObj?.channelType == channelTypeCase.privateChat.rawValue {
                receiverCell.lblName.stringValue = ""
                receiverCell.heightConstraintsName.constant = 0
            }else{
                receiverCell.lblName.stringValue = chatObjMsg.senderName ?? ""
                receiverCell.heightConstraintsName.constant = 20
            }
            switch chatObjMsg.msgtype {
            case 1:
                receiverCell.imgViewMedia.sd_setImage(with: downloadURl, placeholderImage: NSImage(named: "placeholder"))
                //receiverCell.btnShowPreview.setImage(nil, for: .normal)
            case 2:
                let image = cacheImages.object(forKey:downloadURl.lastPathComponent as NSString)
                if image == nil {
                    AVAsset(url: downloadURl).generateThumbnail { [weak self] (image) in
                        DispatchQueue.main.async {
                            if let image = image {
                                self?.cacheImages.setObject(image, forKey: downloadURl.lastPathComponent as NSString)
                            }
                            receiverCell.imgViewMedia.image = image
                        }
                    }
                }else{
                    receiverCell.imgViewMedia.image = image
                }
                //receiverCell.btnShowPreview.setImage(#imageLiteral(resourceName: "play-button"), for: .normal)
            case 3:
                self.imageFromServerURL(downloadURl, placeHolder: nil, completion: { (image) in
                    receiverCell.imgViewMedia.image = image
                })
                //receiverCell.btnShowPreview.setImage(#imageLiteral(resourceName: "document"), for: .normal)
            default:
                break
            }

            //receiverCell.btnShowPreview.addTarget(self, action: #selector(playVideo(_:)), for: .touchUpInside)
            return receiverCell
        }
    }
}

extension ConversationViewController {
    
    func imageFromServerURL(_ url: URL, placeHolder: NSImage? , completion: @escaping (NSImage?) -> Void) {
        if let cachedImage = cacheImages.object(forKey: url.lastPathComponent as NSString) {
            completion(cachedImage)
            return
        }
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if error != nil {
                print("ERROR LOADING IMAGES FROM URL: \(String(describing: error))")
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
                    let scale = NSScreen.main!.backingScaleFactor * pdfScale
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
