//
//  ChatMessages+CoreDataClass.swift
//  
//
//  Created by Vishal's iMac on 22/07/19.
//
//

import Foundation
import CoreData


public class ChatMessages: NSManagedObject, Codable {
    // MARK: - Decodable
    required convenience public init(from decoder: Decoder) throws {
        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "ChatMessages", in: managedObjectContext) else {
                fatalError("Failed to decode User")
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.chat_id = try (container.decodeIfPresent(Int64.self, forKey: .chat_id) ?? 0)
        self.is_read = try container.decodeIfPresent(String.self, forKey: .is_read)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.id = try (container.decodeIfPresent(Int64.self, forKey: .id) ?? 0)
        self.sender = try (container.decodeIfPresent(Int64.self, forKey: .sender) ?? 0)
        self.updated_at = try (container.decodeIfPresent(Double.self, forKey: .updated_at) ?? 0.0)
        self.receiver = try container.decodeIfPresent(String.self, forKey: .receiver)
        self.created_at = try (container.decodeIfPresent(Double.self, forKey: .created_at) ?? 0.0)
        self.mediaurl = try container.decodeIfPresent(String.self, forKey: .mediaurl)
        self.msgtype = try Int16(container.decodeIfPresent(Int.self, forKey: .msgtype) ?? 0)
        
        
    }
}
