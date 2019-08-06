//
//  ChatMessages+CoreDataProperties.swift
//  
//
//  Created by Vishal's iMac on 22/07/19.
//
//

import Foundation
import CoreData


extension ChatMessages {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessages> {
        return NSFetchRequest<ChatMessages>(entityName: "ChatMessages")
    }
    
    @NSManaged public var chat_id: Int64
    @NSManaged public var created_at: Double
    @NSManaged public var id: Int64
    @NSManaged public var is_read: String?
    @NSManaged public var message: String?
    @NSManaged public var receiver: String?
    @NSManaged public var sender: Int64
    @NSManaged public var updated_at: Double
    @NSManaged public var msgtype: Int16
    @NSManaged public var mediaurl : String?
    
    
    enum CodingKeys: String, CodingKey {
        case chat_id = "chat_id"
        case is_read = "is_read"
        case message = "message"
        case id = "id"
        case sender = "sender"
        case updated_at = "updated_at"
        case receiver = "receiver"
        case created_at = "created_at"
        case msgtype = "msgtype"
        case mediaurl = "mediaurl"
    }
    
    
    // MARK: - Enpublic codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chat_id, forKey: .chat_id)
        try container.encode(is_read, forKey: .is_read)
        try container.encode(message, forKey: .message)
        try container.encode(id, forKey: .id)
        try container.encode(sender, forKey: .sender)
        try container.encode(updated_at, forKey: .updated_at)
        try container.encode(created_at, forKey: .created_at)
        try container.encode(receiver, forKey: .receiver)
        try container.encode(msgtype, forKey: .msgtype)
        try container.encode(mediaurl, forKey: .mediaurl)
    }
    
}
