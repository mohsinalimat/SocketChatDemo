//
//  ChatList+CoreDataClass.swift
//  
//
//  Created by Vishal's iMac on 22/07/19.
//
//

import Foundation
import CoreData


public class ChatList: NSManagedObject,Codable {
    
    
    // MARK: - Decodable
    required convenience public init(from decoder: Decoder) throws {
        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "ChatList", in: managedObjectContext) else {
                fatalError("Failed to decode User")
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userIds = try container.decodeIfPresent(String.self, forKey: .userIds)
        self.last_message = try container.decodeIfPresent(String.self, forKey: .last_message)
        self.created_at = try (container.decodeIfPresent(Double.self, forKey: .created_at) ?? 0.0)
        self.chatid = try container.decodeIfPresent(String.self, forKey: .chatid)
        self.updated_at = try (container.decodeIfPresent(Double.self, forKey: .updated_at) ?? 0.0)
        self.channelType = try container.decodeIfPresent(String.self, forKey: .channelType)
        self.channelName = try container.decodeIfPresent(String.self, forKey: .channelName)
    }
}
