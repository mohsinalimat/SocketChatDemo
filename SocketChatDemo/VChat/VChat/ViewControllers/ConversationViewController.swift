//
//  ConversationViewController.swift
//  VChat
//
//  Created by vishal on 8/16/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Cocoa

protocol InitiateChatDelegate {
    func initiateChat(_ objChat : ChatList, isFirstTimePrivateChat : Bool) -> Void
}

class SenderTableCellView: NSTableCellView {
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var lblTime: NSTextField!
}

class ReceiverTableCellView: NSTableCellView {
    @IBOutlet weak var lblName: NSTextField!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var lblTime: NSTextField!
}


class ConversationViewController: NSViewController,InitiateChatDelegate {

    var chatObj : ChatList?
    var chatMsgsArray = [ChatMessages]()
    var page : Int = 0
    var isPaginationEnable : Bool = false
    var pagelimit = 300
    var cacheImages = NSCache<NSString,NSImage>()
    var privateMsgSent = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func initiateChat(_ objChat: ChatList, isFirstTimePrivateChat: Bool) {
        chatObj = objChat
        privateMsgSent = isFirstTimePrivateChat
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
            return nil
            //return configureImageCell(message,index: row)
        case 2:
            return nil
            //return configureImageCell(message,index: row)
        case 3:
            return nil
            //return configureImageCell(message,index: row)
        default:
            return nil
        }
    }
    
    func configureTextCell(_ tableView:NSTableView, chatObjMsg:ChatMessages,index:Int) -> NSView? {
        if UserDefaults.standard.userID! == chatObjMsg.sender{
            let senderCell:SenderTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SenderTableCellView"), owner: self) as! SenderTableCellView
            senderCell.lblMessage.stringValue = chatObjMsg.message ?? ""
            senderCell.lblTime.stringValue = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime() ?? ""
            
//            switch chatObjMsg.is_read "{
//            case "0":
//                senderCell.imgStatus.image = nil
//                break
//            case "1":
//                senderCell.imgStatus.image = #imageLiteral(resourceName: "single_tick")
//                senderCell.imgStatus.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
//                break
//            case "2":
//                senderCell.imgStatus.image = #imageLiteral(resourceName: "tick_grey")
//                senderCell.imgStatus.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
//                break
//            case "3":
//                senderCell.imgStatus.image = #imageLiteral(resourceName: "tick_blue")
//                senderCell.imgStatus.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
//                break
//            default:
//                senderCell.imgStatus.image = nil
//                break
//            }"
            return senderCell
        }else{
            let receiverCell:ReceiverTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ReceiverTableCellView"), owner: self) as! ReceiverTableCellView
            receiverCell.lblMessage.stringValue = chatObjMsg.message ?? ""
            receiverCell.lblTime.stringValue = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime() ?? ""
            if self.chatObj?.channelType == channelTypeCase.privateChat.rawValue {
                receiverCell.lblName.stringValue = ""
                //receiverCell.heightLabelNameConstraints.constant = 0
            }else{
                receiverCell.lblName.stringValue = chatObjMsg.senderName ?? ""
                //receiverCell.heightLabelNameConstraints.constant = 30
            }
            return receiverCell
        }
    }
    
//    func configureImageCell(_ chatObjMsg:ChatMessages, index:Int) -> NSView? {
//        if UserDefaults.standard.userID! == chatObjMsg.sender{
//            let senderCell:SenderTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SenderTableCellView"), owner: self) as! SenderTableCellView
//            senderCell.btnShowPreview.tag = index
//            senderCell.lblTime.text = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime()
//
//            senderCell.btnShowPreview.setImage(nil, for: .normal)
//            let downloadURl = URL.init(string: chatObjMsg.mediaurl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
//
//            switch chatObjMsg.msgtype {
//            case 1:
//                senderCell.imgDownload.sd_setImage(with: downloadURl, placeholderImage: UIImage(named: "placeholder"))
//                senderCell.btnShowPreview.setImage(nil, for: .normal)
//            case 2:
//                let image = cacheImages.object(forKey:downloadURl.lastPathComponent as NSString)
//                if image == nil {
//                    AVAsset(url: downloadURl).generateThumbnail { [weak self] (image) in
//                        DispatchQueue.main.async {
//                            if let image = image {
//                                self?.cacheImages.setObject(image, forKey: downloadURl.lastPathComponent as NSString)
//                            }
//                            senderCell.imgDownload.image = image
//                        }
//                    }
//                }else{
//                    senderCell.imgDownload.image = image
//                }
//                senderCell.btnShowPreview.setImage(#imageLiteral(resourceName: "play-button"), for: .normal)
//            case 3:
//                self.imageFromServerURL(downloadURl, placeHolder: nil, completion: { (image) in
//                    senderCell.imgDownload.image = image
//                })
//                senderCell.btnShowPreview.setImage(#imageLiteral(resourceName: "document"), for: .normal)
//            default:
//                break
//            }
//
//            senderCell.btnShowPreview.addTarget(self, action: #selector(playVideo(_:)), for: .touchUpInside)
//            switch chatObjMsg.is_read {
//            case "0":
//                senderCell.imgStatus.image = nil
//                break
//            case "1":
//                senderCell.imgStatus.image = #imageLiteral(resourceName: "single_tick")
//                senderCell.imgStatus.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
//                break
//            case "2":
//                senderCell.imgStatus.image = #imageLiteral(resourceName: "tick_grey")
//                senderCell.imgStatus.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
//                break
//            case "3":
//                senderCell.imgStatus.image = #imageLiteral(resourceName: "tick_blue")
//                senderCell.imgStatus.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
//                break
//            default:
//                senderCell.imgStatus.image = nil
//                break
//            }
//            return senderCell
//        }else{
//
//            let receiverCell = tableView.dequeueReusableCell(withIdentifier: "ChatReceiverCellMedia") as! ChatReceiverCell
//            receiverCell.lblTime.text = "\(chatObjMsg.created_at)".timeStampToLocalDate().getLocalTime()
//
//            receiverCell.btnShowPreview.tag = index
//            let downloadURl = URL.init(string: chatObjMsg.mediaurl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!
//            if self.chatObj?.channelType == channelTypeCase.privateChat.rawValue {
//                receiverCell.lblName.text = ""
//                receiverCell.heightLabelNameConstraints.constant = 0
//            }else{
//                receiverCell.lblName.text = chatObjMsg.senderName
//                receiverCell.heightLabelNameConstraints.constant = 30
//            }
//            switch chatObjMsg.msgtype {
//            case 1:
//                receiverCell.imgDownload.sd_setImage(with: downloadURl, placeholderImage: UIImage(named: "placeholder"))
//                receiverCell.btnShowPreview.setImage(nil, for: .normal)
//            case 2:
//                let image = cacheImages.object(forKey:downloadURl.lastPathComponent as NSString)
//                if image == nil {
//                    AVAsset(url: downloadURl).generateThumbnail { [weak self] (image) in
//                        DispatchQueue.main.async {
//                            if let image = image {
//                                self?.cacheImages.setObject(image, forKey: downloadURl.lastPathComponent as NSString)
//                            }
//                            receiverCell.imgDownload.image = image
//                        }
//                    }
//                }else{
//                    receiverCell.imgDownload.image = image
//                }
//                receiverCell.btnShowPreview.setImage(#imageLiteral(resourceName: "play-button"), for: .normal)
//            case 3:
//                self.imageFromServerURL(downloadURl, placeHolder: nil, completion: { (image) in
//                    receiverCell.imgDownload.image = image
//                })
//                receiverCell.btnShowPreview.setImage(#imageLiteral(resourceName: "document"), for: .normal)
//            default:
//                break
//            }
//
//            receiverCell.btnShowPreview.addTarget(self, action: #selector(playVideo(_:)), for: .touchUpInside)
//            return receiverCell
//        }
//    }
    
}
