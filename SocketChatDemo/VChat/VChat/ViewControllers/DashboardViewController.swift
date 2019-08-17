//
//  DashboardViewController.swift
//  VChat
//
//  Created by vishal on 8/16/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa

protocol GroupBroadcastOpenProtocol {
    func openCreateGroupBroadcastView(_ objUsers:[LoginUser], channelType:String) -> Void
}


let screen = NSScreen.main
class DashboardViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, GroupBroadcastOpenProtocol {
    

    @IBOutlet weak var ChatListTableView: NSTableView!
    
    var chatListArray : [ChatList]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ChatListTableView.selectionHighlightStyle = .none
        DispatchQueue.main.async {
            self.getUserList()
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.chatListArray?.removeAll()
        appdelegate.objAPI.chnlDelegate = self
        self.checkDataAvailable()
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
    
    @IBAction func btnGroupAction(_ sender: NSButton) {
        self.performSegue(withIdentifier: "segueUserList", sender: channelTypeCase.group.rawValue)
    }
    
    @IBAction func btnBroadcastAction(_ sender: NSButton) {
        self.performSegue(withIdentifier: "segueUserList", sender: channelTypeCase.broadcast.rawValue)
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
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatList")
            fetchRequest.predicate = NSPredicate(format: "channelType != '\(channelTypeCase.broadcast.rawValue)'")
            if let dataArray = try context.fetch(fetchRequest) as? [ChatList]{
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
        return self.chatListArray?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let result:ChatListTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChatListTableCellView"), owner: self) as! ChatListTableCellView
        let objChannel = self.chatListArray?[row]
        result.imgView.image = NSImage(named:"NSUser")
        result.nameTextField.stringValue = objChannel?.channelName ?? ""
        result.lastMessageTextField.stringValue = objChannel?.last_message ?? ""
        result.dateTextField.stringValue = "\(objChannel!.created_at)".timeStampToLocalDate()
        result.countTextField.stringValue = "\(objChannel!.unreadcount)"
        result.unreadCountBox.isHidden = objChannel!.unreadcount <= 0
        
        return result
     }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 67
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
