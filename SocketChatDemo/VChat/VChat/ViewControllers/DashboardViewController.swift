//
//  DashboardViewController.swift
//  VChat
//
//  Created by vishal on 8/16/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa
import QuartzCore

protocol GroupBroadcastOpenProtocol {
    func openCreateGroupBroadcastView(_ objUsers:[LoginUser], channelType:String) -> Void
}


let screen = NSScreen.main
class DashboardViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, GroupBroadcastOpenProtocol {
    
    @IBOutlet weak var scrollTableDropDown: NSScrollView!
    @IBOutlet weak var dropDownMainView: NSTableView!
    @IBOutlet weak var ChatListTableView: NSTableView!
    @IBOutlet weak var imguserProfile: NSImageView!
    
    var chatListArray : [ChatList]?
    var dropDownList = ["Create Group","Create Broadcast","Logout"]
    override func viewDidLoad() {
        super.viewDidLoad()
        ChatListTableView.selectionHighlightStyle = .none
        let downloadURl = URL.init(string: UserDefaults.standard.userPhoto!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
        imguserProfile.sd_setImage(with: downloadURl, placeholderImage: #imageLiteral(resourceName: "user"))
        DispatchQueue.main.async {
            self.imguserProfile.layer?.cornerRadius = self.imguserProfile.frame.size.height/2
            self.getUserList()
        }
        self.chatListArray?.removeAll()
        appdelegate.objAPI.chnlDelegate = self
        self.checkDataAvailable()
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        self.scrollTableDropDown.isHidden = true
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.scrollTableDropDown.wantsLayer = true
        self.scrollTableDropDown.shadow = NSShadow()
        self.scrollTableDropDown.layer?.backgroundColor = NSColor.red.cgColor
        self.scrollTableDropDown.layer?.cornerRadius = 5.0
        self.scrollTableDropDown.layer?.shadowOpacity = 1.0
        self.scrollTableDropDown.layer?.shadowColor = NSColor.black.cgColor
        self.scrollTableDropDown.layer?.shadowOffset = NSMakeSize(0, 0)
        self.scrollTableDropDown.layer?.shadowRadius = 20
        self.scrollTableDropDown.isHidden = true
    }
    
    public func clearAllCoreData() {
        let entities = appdelegate.persistentContainer.managedObjectModel.entities
        do {
            try entities.compactMap({ $0.name }).forEach(clearDeepObjectEntity)
        }catch{}
    }
    
    @IBAction func btnPrivateChatAction(_ sender: NSButton) {
        self.performSegue(withIdentifier: "segueUserList", sender: channelTypeCase.privateChat.rawValue)
    }
    
    @IBAction func btnDropDownAction(_ sender: NSButton) {
        self.scrollTableDropDown.isHidden = !self.scrollTableDropDown.isHidden
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destination = segue.destinationController as? UserViewController {
            destination.channelType = sender as? String
        }else if let destination = segue.destinationController as? CreateGroupViewController {
            destination.selectedUserList = (sender as! [String:Any])["user"] as? [LoginUser]
            destination.channelType = (sender as! [String:Any])["channelType"] as? String
            destination.delegate = self.parent?.children[1] as? InitiateChatDelegate
        }
    }
    
    func checkDataAvailable(){
        do{
            let context = appdelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<ChatList>(entityName: "ChatList")
            //fetchRequest.predicate = NSPredicate(format: "channelType != '\(channelTypeCase.broadcast.rawValue)'")
            fetchRequest.returnsObjectsAsFaults = false
            let sort = NSSortDescriptor(key: #keyPath(ChatList.updated_at), ascending: false)
            fetchRequest.sortDescriptors = [sort]
            let dataArray = try context.fetch(fetchRequest)
            if dataArray.count > 0 {
                self.chatListArray = dataArray
                self.ChatListTableView.reloadData()
            }
        }catch let error{
            print(error.localizedDescription)
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
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return ChatListTableView == tableView ? (self.chatListArray?.count ?? 0) : dropDownList.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        if ChatListTableView == tableView {
            return configureChatList(tableView, row: row)
        }else {
            return configureDropDown(tableView, row: row)
        }
    }
    
    func configureDropDown(_ tableView:NSTableView,row:Int) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as! DropDownTableCellView
        cellView.nameTextField.stringValue = dropDownList[row]
        return cellView
    }
    
    func configureChatList(_ tableView:NSTableView,row:Int) -> NSView? {
        let result:ChatListTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChatListTableCellView"), owner: self) as! ChatListTableCellView
        let objChannel = self.chatListArray?[row]
        let downloadURl = URL.init(string: objChannel?.channelPic?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
        result.imgView.sd_setImage(with: downloadURl, placeholderImage: #imageLiteral(resourceName: "user"))
        DispatchQueue.main.async {
            result.imgView.layer?.cornerRadius = result.imgView.frame.size.height/2
        }
        result.nameTextField.stringValue = objChannel?.channelName ?? ""
        result.lastMessageTextField.stringValue = objChannel?.last_message ?? ""
        result.dateTextField.stringValue = "\(objChannel!.created_at)".timeStampToLocalDate()
        result.countTextField.stringValue = "\(objChannel!.unreadcount)"
        result.unreadCountBox.isHidden = objChannel!.unreadcount <= 0
        
        return result
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let table = notification.object as? NSTableView else {
            return
        }
        if table == ChatListTableView {
            let row = table.selectedRow
            if row >= 0 {
                if let objChannel = self.chatListArray?[row] {
                    appdelegate.objAPI.selectedChannelId = objChannel.chatid
                    (self.parent?.children[1] as! ConversationViewController).initiateChat(objChannel, isFirstTimePrivateChat: false)
                }
            }
        }else{
            let row = table.selectedRow
            self.scrollTableDropDown.isHidden = true
            switch row {
            case 0:
                self.performSegue(withIdentifier: "segueUserList", sender: channelTypeCase.group.rawValue)
                break
            case 1:
                self.performSegue(withIdentifier: "segueUserList", sender: channelTypeCase.broadcast.rawValue)
                break
            case 2:
                appdelegate.objAPI.socketDisconnect { (success, error) in
                    self.clearAllCoreData()
                    appdelegate.objAPI.socket.removeAllHandlers()
                    UserDefaults.standard.userID = nil
                    self.view.window?.contentViewController = NSStoryboard.loginViewController()
                }
                break
            default:
                break
            }
            table.deselectRow(row)
        }
    }
    
    func openCreateGroupBroadcastView(_ objUsers: [LoginUser], channelType: String) {
        let user = ["user":objUsers,"channelType":channelType] as [String : Any]
        self.performSegue(withIdentifier: "segueGroupBroadcast", sender: user)
    }
    
}

extension DashboardViewController : ReceiveChannel{
    func receiveChnl() {
        checkDataAvailable()
    }
}

class ChatListTableCellView: NSTableCellView {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var lastMessageTextField: NSTextField!
    @IBOutlet weak var dateTextField: NSTextField!
    @IBOutlet weak var countTextField: NSTextField!
    @IBOutlet weak var unreadCountBox: NSBox!
}

class DropDownTableCellView: NSTableCellView {
    @IBOutlet weak var nameTextField: NSTextField!
}
