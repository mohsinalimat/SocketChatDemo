//
//  ViewController.swift
//  ChatDemo
//
//  Created by vishal on 14/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import SocketIO

class ViewController: UIViewController {
    @IBOutlet var txtMessage: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func btnSendAction(_ sender: UIButton) {
        let sendData = ["sender":"2",
                        "receiver":"1",
                        "chat_id":"",
                        "message":txtMessage.text!,
                        "is_read":"0",
                        "msg_id":"123",
                        "updated_at":"123456"] as [String : Any]
        
        appdelegate.objAPI.sendMessage(sendData) { (ack, error) in
            if let error = error {
                print(error)
            }else{
                if let ack = ack {
                    print(ack)
                    do {
                        let managedObjectContext = appdelegate.persistentContainer.viewContext
                        let decoder = JSONDecoder()
                        if let context = CodingUserInfoKey.managedObjectContext {
                            decoder.userInfo[context] = managedObjectContext
                        }
                        _ = try decoder.decode(ChatMessages.self, from: ack.toData())
                        try managedObjectContext.save()
                        print("saved")
                    } catch {
                        print("data not saved")
                    }
                }
            }
        }
    }
}

extension Dictionary {
    func toData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
}

extension Array {
    func toData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: [])
    }
}
