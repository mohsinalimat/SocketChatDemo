//
//  SocketManager.swift
//  ChatDemo
//
//  Created by vishal on 14/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import SocketIO
import CoreData

typealias completionHandler = ([String:Any]?, String?) -> Void
typealias completionHandlerArray = ([[String:Any]]?, String?) -> Void
typealias completionHandlerBool = (Bool?, String?) -> Void

protocol ReceiveMessage {
    func receiveMsg(msg : ChatMessages)
    func typingMsg(data : [String:Any])
    func updateStatus(data : [String:Any])
}
protocol ReceiveChannel {
    func receiveChnl()
}


class SocketManagerAPI: NSObject {
    
    let manager = SocketManager(socketURL: URL(string: "http://192.168.1.86:3000")!, config: [.log(true), .compress, .connectParams(["user_id":UserDefaults.standard.userID ?? ""])])
    let socket : SocketIOClient!
    
    var delegate : ReceiveMessage?
    var chnlDelegate : ReceiveChannel?
    
    static var shared : SocketManagerAPI {
        return SocketManagerAPI()
    }
    
    override init() {
        self.socket = manager.defaultSocket
    }
    
    func connectSocket(completion:completionHandlerBool? = nil) -> Void {
        socket.on(clientEvent: .connect) { data, ack in
            print("---------->> socket connected <<---------------")
            self.getData()
            if let completion = completion {
                completion(true,nil)
            }
        }
        socket.connect()
    }
    
    func socketDisconnect(completion:@escaping completionHandlerBool) -> Void {
        socket.on(clientEvent: .disconnect) { (data, ack) in
            print("---------->> socket disconnected <<---------------")
            completion(true,nil)
        }
        socket.disconnect()
    }
    
    func getData() -> Void {
        if UserDefaults.standard.userID != nil {
            
            
            self.socket.removeAllHandlers()
            
            self.getChannel()
            self.getTypingMessage()
            self.getChangeStatus()
            
            self.getMessages()
        
            
        }
        
    }
    
    func getUserList(ackCallBack:@escaping completionHandlerArray) -> Void {
        socket.emitWithAck("UserList").timingOut(after: 0) { (data) in
            print("got data \(data)")
            guard let data = data[0] as? [[String:Any]] else { ackCallBack(nil,"data Not availabel"); return }
            //            guard let data1 = data.toJSON() as? [[String:Any]] else { ackCallBack(nil,"data Not availabel"); return }
            ackCallBack(data,nil)
        }
    }
    
    func getChatList(_ data:[String:Any], ackCallBack:@escaping completionHandlerArray) -> Void {
        socket.emitWithAck("channelList" , data).timingOut(after: 0) { (data) in
            print("got data \(data)")
            guard let data = data[0] as? [[String:Any]] else { ackCallBack(nil,"data Not availabel"); return }
            
            ackCallBack(data,nil)
        }
    }
    func insertChannelList(arrayData : [[String:Any]]) -> [ChatList]?{
        do {
            let managedObjectContext = appdelegate.persistentContainer.viewContext
            let decoder = JSONDecoder()
            if let context = CodingUserInfoKey.managedObjectContext {
                decoder.userInfo[context] = managedObjectContext
            }
            let objUser = try decoder.decode([ChatList].self, from: arrayData.toData())
            appdelegate.saveContext()
            return objUser
        } catch {
            print("nodata found")
            return nil
        }
    }
    
    func getChangeStatus(){
        socket.on("ChangeStatus/\(UserDefaults.standard.userID!)") {data, ack in
            if let getData = data[0] as? [String:Any]{
                self.delegate?.updateStatus(data: getData)
            }
        }
    }
    
    func getMessages() -> Void {
        socket.on("receiveMessage/\(UserDefaults.standard.userID!)") {data, ack in
            
            if let getData = data[0] as? [String:Any]{
                if let msg =  self.insertMessage(dict: getData){
                    
//                    let status = self.updateUnReadMsgCount(msg)
//                    if status{
//                        self.chnlDelegate?.receiveChnl()
//                    }
                    
                    
                    let dict = ["is_read":"2","id":msg.id!,"sender":msg.sender!] as [String:Any]
                    self.emitStatus(dict) { (dict, error) in
                        
                    }
                    self.delegate?.receiveMsg(msg: msg)
                }
            }else{
                let arrayData = data[0] as? [[String:Any]]
                self.insertMsgArray(array: arrayData!)
            }
            ack.with("got it")
        }
    }
    
    func emitStatus(_ params : [String:Any], ackCallBack:@escaping completionHandler) -> Void {
        socket.emitWithAck("ChangeStatus", params).timingOut(after: 0) { data in
            guard let data = data[0] as? [String:String] else { ackCallBack(nil,"data Not availabel"); return }
            
            let status = self.updateMessageStatus(data)
            
            if status{
                ackCallBack(data,nil)
            }
        }
    }
    func updateMessageStatus(_ arrayData : [String:Any]) -> Bool {
       
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ChatMessages")
        fetchRequest.predicate = NSPredicate(format: "id = '\(arrayData["id"] ?? "")'")
        
        do {
            guard let result = try? appdelegate.persistentContainer.viewContext.fetch(fetchRequest)  as? [ChatMessages] else { return false }
            if result.count > 0 {
                let objResult = result[0]
                
                objResult.is_read = arrayData["is_read"] as? String
                appdelegate.saveContext()
            }
            return true
        } catch {
            print("error executing fetch request: \(error.localizedDescription)")
            return false
        }
    }
    
    func getChannel() -> Void {
        socket.on("channelList/\(UserDefaults.standard.userID!)") {data, ack in
            print(data)
            
            guard let customData = data as? [[String:Any]] else { return }
            
            let updated = self.checkChannelAvailable(customData)
            if updated {
                self.chnlDelegate?.receiveChnl()
            }
            ack.with("Got your currentAmount", "dude")
        }
    }
    
    func getTypingMessage() -> Void{
        socket.on("getTyping/\(UserDefaults.standard.userID!)") {data, ack in
            print(data)
            
            guard let customData = data as? [[String:Any]] else { return }
            self.delegate?.typingMsg(data: customData[0])
            ack.with("Got your currentAmount", "dude")
        }
    }
    func updateUnReadMsgCount(_ chatID : String , count : Int = 0) -> Bool{
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ChatList")
        fetchRequest.predicate = NSPredicate(format: "chatid = '\(chatID)'")
        
        
        do {
        guard let result = try? appdelegate.persistentContainer.viewContext.fetch(fetchRequest)  as? [ChatList] else { return false }
            if result.count > 0 {
                let objResult = result[0]
                
                objResult.unreadcount = Int16(count)
                
                appdelegate.saveContext()
            }
            return true
        } catch {
            print("error executing fetch request: \(error.localizedDescription)")
            return false
        }

    }
    
    
    
    func checkChannelAvailable(_ arrayData : [[String:Any]]) -> Bool {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ChatList")
        fetchRequest.predicate = NSPredicate(format: "chatid = '\(arrayData[0]["chatid"] ?? "")'")
        
        do {
            guard let result = try? appdelegate.persistentContainer.viewContext.fetch(fetchRequest)  as? [ChatList] else { return false }
            if result.count > 0 {
                let objResult = result[0]
                let updatedData = arrayData[0]
                objResult.userIds = updatedData["userIds"] as? String
                objResult.last_message = updatedData["last_message"] as? String
                objResult.chatid = updatedData["chatid"] as? String
                objResult.channelType = updatedData["channelType"] as? String
                objResult.channelName = updatedData["channelName"] as? String
                objResult.updated_at = updatedData["updated_at"] as? Double ?? 0.0
                objResult.unreadcount += 1
                if let createdAt = updatedData["created_at"] as? Double {
                    objResult.created_at = createdAt
                }
                appdelegate.saveContext()
            }else{
                self.insertChannelList(arrayData: arrayData)
            }
            return true
        } catch {
            print("error executing fetch request: \(error.localizedDescription)")
            return false
        }
    }
    func insertMsgArray(array : [[String:Any]]) {
        do{
            let managedObjectContext = appdelegate.persistentContainer.viewContext
            let decoder = JSONDecoder()
            if let context = CodingUserInfoKey.managedObjectContext {
                decoder.userInfo[context] = managedObjectContext
            }
            
            let obj = try decoder.decode([ChatMessages].self, from: array.toData())
            
            let finalC_ids: [String] = obj.filter({ $0.is_read != "3" }).map({ $0.chat_id ?? "" }).uniqueElements.filter({ $0 != nil && $0.count > 0})
            
            for i in finalC_ids{
                    let arrayObj = obj.filter({ $0.is_read != "3" && $0.chat_id == i && $0.receiver == UserDefaults.standard.userID!})
                    self.updateUnReadMsgCount(i, count: arrayObj.count)
            }
            try managedObjectContext.save()
            
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func insertMessage(dict : [String:Any]) -> ChatMessages?{
        do{
            let managedObjectContext = appdelegate.persistentContainer.viewContext
            let decoder = JSONDecoder()
            if let context = CodingUserInfoKey.managedObjectContext {
                decoder.userInfo[context] = managedObjectContext
            }
            
            let objUser = try decoder.decode(ChatMessages.self, from: dict.toData())
            try managedObjectContext.save()
            
            return objUser
            
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
        
    }
    
    func authenticateUser(_ data:[String:Any], completion:@escaping completionHandler) -> Void {
        socket.emitWithAck("Authenticate",data).timingOut(after: 0) { (data) in
            if let Maindata = data as? [Any], Maindata.count > 0 {
                if let arrayData = Maindata as? [[String:Any]],arrayData.count > 0 {
                    let dataDict = arrayData[0]
                    completion(dataDict,nil)
                }else{
                    completion(nil,"data Not availabel")
                }
            }else{
                completion(nil,"data Not availabel")
            }
        }
    }
    
    func userSignUp(_ data:[String:Any], completion:@escaping completionHandler) -> Void {
        socket.emitWithAck("SignUp",data).timingOut(after: 0) { (data) in
            print("got data \(data)")
            guard let data = data[0] as? [String:Any] else { completion(nil,"data Not availabel"); return }
            completion(data,nil)
        }
    }
    
    func sendMessage(_ params : [String:Any], ackCallBack:@escaping completionHandler) -> Void {
        socket.emitWithAck("sendMessage", params).timingOut(after: 0) { data in
            print("got message")
            guard let data = data[0] as? [String:Any] else { ackCallBack(nil,"data Not availabel"); return }
            ackCallBack(data,nil)
        }
        print(socket.sid)
    }
    func updateTyping(_ params : [String:Any]) -> Void {
        socket.emit("UserTyping", params)
    }
    
    
    func getChatID(_ params : [String:Any], ackCallBack:@escaping completionHandler) -> Void {
        socket.emitWithAck("GetChatId", params).timingOut(after: 0) { data in
            print("got message")
            guard let data1 = data[0] as? [String:String] else { ackCallBack(nil,"data Not availabel"); return }
            ackCallBack(data1,nil)
        }
    }
    
    
}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}


extension UserDefaults {
    var userID : String? {
        get{
            return self.value(forKey: "userID") as? String ?? nil
        }
        set {
            self.set(newValue, forKey: "userID")
        }
    }
}

extension Array {
    func toData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions(rawValue: 0))
    }
}

extension Dictionary {
    func toData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions(rawValue: 0))
    }
}

public extension Sequence where Element: Equatable {
    var uniqueElements: [Element] {
        return self.reduce(into: []) {
            uniqueElements, element in
            
            if !uniqueElements.contains(element) {
                uniqueElements.append(element)
            }
        }
    }
}
