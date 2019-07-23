//
//  LoginUser+CoreDataClass.swift
//  
//
//  Created by Vishal's iMac on 22/07/19.
//
//

import Foundation
import CoreData


public class LoginUser: NSManagedObject,Codable {
    required convenience public init(from decoder: Decoder) throws {
        guard let codingUserInfoKeyManagedObjectContext = CodingUserInfoKey.managedObjectContext,
            let managedObjectContext = decoder.userInfo[codingUserInfoKeyManagedObjectContext] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "LoginUser", in: managedObjectContext) else {
                fatalError("Failed to decode User")
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photo = try container.decodeIfPresent(String.self, forKey: .photo)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
    }
}
