//
//  LoginUser+CoreDataProperties.swift
//  
//
//  Created by Vishal's iMac on 22/07/19.
//
//

import Foundation
import CoreData


extension LoginUser {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LoginUser> {
        return NSFetchRequest<LoginUser>(entityName: "LoginUser")
    }
    
    @NSManaged public var email: String?
    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var photo: String?
    
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case email = "email"
        case photo = "photo"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(photo, forKey: .photo)
    }
    
}
