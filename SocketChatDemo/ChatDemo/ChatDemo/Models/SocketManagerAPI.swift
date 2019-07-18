//
//  SocketManager.swift
//  ChatDemo
//
//  Created by vishal on 14/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import SocketIO


typealias completionHandler = ([String:Any]?, String?) -> Void
typealias completionHandlerArray = ([[String:Any]]?, String?) -> Void

protocol ReceiveMessage {
    func receiveMsg(msg : ChatMessages)
}
protocol ReceiveChannel {
    func receiveChnl(channel : [ChatList])
}

class SocketManagerAPI: NSObject {
    
    let manager = SocketManager(socketURL: URL(string: "http://192.168.1.105:3000")!, config: [.log(true), .compress, .connectParams(["user_id":"2"])])
    let socket : SocketIOClient!
    
    var delegate : ReceiveMessage?
    var chnlDelegate : ReceiveChannel?
    
    static var shared : SocketManagerAPI {
        return SocketManagerAPI()
    }
    
    override init() {
        self.socket = manager.defaultSocket
    }
    
    func connectSocket() -> Void {
        socket.on(clientEvent: .connect) { data, ack in
            print("---------->> socket connected <<---------------")
            self.socket.removeAllHandlers()
            
        }
        socket.connect()
    }
    
    func getData() -> Void {
        if UserDefaults.standard.userID != nil {
            self.getMessages()
            self.getChannel()
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

            try managedObjectContext.save()
            return objUser
        } catch {
            print("nodata found")
            return nil
        }

    }
    
    func getMessages() -> Void {
        socket.on("receiveMessage/\(UserDefaults.standard.userID!)") {data, ack in
            print(data)
            if let getData = data[0] as? [String:Any]{
                if let msg =  self.insertMessage(dict: getData){
                    self.delegate?.receiveMsg(msg: msg)
                }
            }
            ack.with("Got your currentAmount", "dude")
        }
    }
    
    func getChannel() -> Void {
        socket.on("channelList/\(UserDefaults.standard.userID!)") {data, ack in
            print(data)
            
            guard let customData = data as? [[String:Any]] else { return }
            
            if let channelList = self.insertChannelList(arrayData: customData) {
                self.chnlDelegate?.receiveChnl(channel: channelList)
            }
            ack.with("Got your currentAmount", "dude")
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
//            guard let data1 = data.toJSON() as? [[String:Any]] else { completion(nil,"data Not availabel"); return }
//            if data1.count > 0 {
                completion(data,nil)
//            }else{
//                completion(nil,"invalid Credentials")
//            }
        }
    }
    
    func sendMessage(_ params : [String:Any], ackCallBack:@escaping completionHandler) -> Void {
        socket.emitWithAck("sendMessage", params).timingOut(after: 0) { data in
            print("got message")
            guard let data = data[0] as? [String:String] else { ackCallBack(nil,"data Not availabel"); return }
            ackCallBack(data,nil)
        }
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
