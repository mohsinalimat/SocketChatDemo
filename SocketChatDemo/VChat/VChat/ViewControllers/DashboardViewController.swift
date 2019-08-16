//
//  DashboardViewController.swift
//  VChat
//
//  Created by vishal on 8/16/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa
let screen = NSScreen.main
class DashboardViewController: NSViewController,NSTableViewDelegate,NSTableViewDataSource {

    @IBOutlet weak var ChatListTableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ChatListTableView.selectionHighlightStyle = .none
        
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 10
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let result:ChatListTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChatListTableCellView"), owner: self) as! ChatListTableCellView
        result.imgView.image = NSImage(named:"NSUser")
        result.nameTextField.stringValue = "Vishal Kalola"
        result.lastMessageTextField.stringValue = "Message"
        result.dateTextField.stringValue = "10 May 1994 10:00 AM"
        result.countTextField.stringValue = "100"
        
        return result;
     }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 67
    }
}

class ChatListTableCellView: NSTableCellView {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var lastMessageTextField: NSTextField!
    @IBOutlet weak var dateTextField: NSTextField!
    @IBOutlet weak var countTextField: NSTextField!
}
