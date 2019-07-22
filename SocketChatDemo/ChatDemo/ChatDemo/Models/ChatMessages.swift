//
//  ChatList.swift
//  ChatDemo
//
//  Created by vishal on 14/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import CoreData

//class ChatMessages: NSManagedObject, Codable {
//    enum CodingKeys: String, CodingKey {
//        case chat_id = "chat_id"
//        case is_read = "is_read"
//        case message = "message"
//        case id = "id"
//        case sender = "sender"
//        case updated_at = "updated_at"
//        case receiver = "receiver"
//        case created_at = "created_at"
//        
//    }
//    
//    // MARK: - Core Data Managed Object
//    @NSManaged var chat_id: String?
//    @NSManaged var is_read: String?
//    @NSManaged var message: String?
//    @NSManaged var id: String?
//    @NSManaged var sender: String?
//    @NSManaged var updated_at: NSNumber?
//    @NSManaged var receiver: String?
//    @NSManaged var created_at: NSNumber?
//    
//    
//    // MARK: - Decodable
//    required convenience init(from decoder: Decoder) throws {
//        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
//            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
//            let entity = NSEntityDescription.entity(forEntityName: "ChatMessages", in: managedObjectContext) else {
//                fatalError("Failed to decode User")
//        }
//        
//        self.init(entity: entity, insertInto: managedObjectContext)
//        
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.chat_id = try container.decodeIfPresent(String.self, forKey: .chat_id)
//        self.is_read = try container.decodeIfPresent(String.self, forKey: .is_read)
//        self.message = try container.decodeIfPresent(String.self, forKey: .message)
//        self.id = try container.decodeIfPresent(String.self, forKey: .id)
//        self.sender = try container.decodeIfPresent(String.self, forKey: .sender)
//        self.updated_at = try container.decodeIfPresent(Double.self, forKey: .updated_at)
//        self.receiver = try container.decodeIfPresent(String.self, forKey: .receiver)
//        self.created_at = try container.decodeIfPresent(Double.self, forKey: .created_at)
//    }
//    
//    // MARK: - Encodable
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(chat_id, forKey: .chat_id)
//        try container.encode(is_read, forKey: .is_read)
//        try container.encode(message, forKey: .message)
//        try container.encode(id, forKey: .id)
//        try container.encode(sender, forKey: .sender)
//        try container.encode(updated_at, forKey: .updated_at)
//        try container.encode(created_at, forKey: .created_at)
//        try container.encode(receiver, forKey: .receiver)
//    }
//}


public extension CodingUserInfoKey {
    // Helper property to retrieve the context
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")
}
