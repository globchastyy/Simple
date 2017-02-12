//
//  ClientResponseExtensions.swift
//  jtinsights
//
//  Created by Alexey Globchastyy on 23/01/2017.
//
//

import Foundation
import KituraNet
import SwiftyJSON
import Kitura


public extension RouterRequest {
    public func readJSON() -> JSON? {
        var data = Data()

        _ = try? self.read(into: &data)

        let json = JSON(data: data)
        if json == .null { return nil }

        return json
    }
}
