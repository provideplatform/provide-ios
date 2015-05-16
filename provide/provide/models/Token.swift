//
//  Token.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Token: Model {

    var id: NSNumber!
    var uuid: String!
    var token: String!
    var userId: NSNumber!
    var user: User!

    class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "uuid": "uuid",
            "token": "token",
            "user_id": "userId"
        ])
        mapping.addRelationshipMappingWithSourceKeyPath("user", mapping: User.mapping())
        return mapping
    }

    var authorizationHeaderString: String {
        return "Basic " + "\(token):\(uuid)".base64EncodedString
    }

    override func toDictionary() -> [String : AnyObject] {
        return [
            "id": id,
            "uuid": uuid,
            "token": token,
            "userId": userId
        ]
    }

    class func fromJSON(json: String!) -> Token! {
        var token: Token!
        if let obj = json.toJSONObject() {
            token = Token()
            token.id = obj["id"] as! Int
            token.uuid = obj["uuid"] as! String
            token.token = obj["token"] as! String
            token.userId = obj["userId"] as! Int
        }
        return token
    }

}
