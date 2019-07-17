//
//  ChatList.swift
//  ChatDemo
//
//  Created by vishal on 14/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import CoreData

class ChatList : NSManagedObject, Codable {
    enum CodingKeys: String, CodingKey {
        case userIds = "userIds"
        case last_message = "last_message"
        case created_at = "created_at"
        case chatid = "chatid"
        case updated_at = "updated_at"
        case channelType = "channelType"
        case channelName = "channelName"
    }
    
    // MARK: - Core Data Managed Object
    @NSManaged var userIds: String?
    @NSManaged var last_message: String?
    @NSManaged var created_at: String?
    @NSManaged var chatid: String?
    @NSManaged var updated_at: String?
    @NSManaged var channelType : String?
    @NSManaged var channelName : String?
    
    // MARK: - Decodable
    required convenience init(from decoder: Decoder) throws {
        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "ChatList", in: managedObjectContext) else {
                fatalError("Failed to decode User")
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userIds = try container.decodeIfPresent(String.self, forKey: .userIds)
        self.last_message = try container.decodeIfPresent(String.self, forKey: .last_message)
        self.created_at = try container.decodeIfPresent(String.self, forKey: .created_at)
        self.chatid = try container.decodeIfPresent(String.self, forKey: .chatid)
        self.updated_at = try container.decodeIfPresent(String.self, forKey: .updated_at)
        self.channelType = try container.decodeIfPresent(String.self, forKey: .channelType)
        self.channelName = try container.decodeIfPresent(String.self, forKey: .channelName)
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userIds, forKey: .userIds)
        try container.encode(last_message, forKey: .last_message)
        try container.encode(created_at, forKey: .created_at)
        try container.encode(chatid, forKey: .chatid)
        try container.encode(updated_at, forKey: .updated_at)
        try container.encode(channelType, forKey: .channelType)
        try container.encode(channelName, forKey: .channelName)
    }
}
