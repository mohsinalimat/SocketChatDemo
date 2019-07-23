//
//  ChatList+CoreDataProperties.swift
//  
//
//  Created by Vishal's iMac on 22/07/19.
//
//

import Foundation
import CoreData


extension ChatList {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatList> {
        return NSFetchRequest<ChatList>(entityName: "ChatList")
    }
    
    @NSManaged public var channelName: String?
    @NSManaged public var channelType: String?
    @NSManaged public var chatid: String?
    @NSManaged public var created_at: Double
    @NSManaged public var last_message: String?
    @NSManaged public var updated_at: Double
    @NSManaged public var userIds: String?
    
    
    
    enum CodingKeys: String, CodingKey {
        case userIds = "userIds"
        case last_message = "last_message"
        case created_at = "created_at"
        case chatid = "chatid"
        case updated_at = "updated_at"
        case channelType = "channelType"
        case channelName = "channelName"
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
