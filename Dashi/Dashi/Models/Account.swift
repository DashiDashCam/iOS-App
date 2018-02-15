//
//  Account.swift
//  Dashi
//
//  Created by Chris Henk on 1/25/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class Account {

    // Protected members
    var created: Date
    var id: Int

    // Public members
    public var fullName: String
    public var email: String

    init(account: JSON) {
        fullName = account["fullName"].stringValue
        created = DateConv.toDate(timestamp: account["created"].stringValue)
        id = account["id"].intValue
        email = account["email"].stringValue
    }

    public func toParameters() -> Parameters {
        let parameters: Parameters = [
            "id": self.id,
            "fullName": self.fullName,
            "email": self.email,
        ]
        return parameters
    }

    public func getCreated() -> Date {
        return created
    }

    public func getId() -> Int {
        return id
    }
}
