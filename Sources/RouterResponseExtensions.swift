//
//  RouterResponseExtensions.swift
//  Simple
//
//  Created by Alexey Globchastyy on 23/01/2017.
//
//

import Kitura
import SwiftyJSON

extension RouterResponse {
    @discardableResult
    func _send<T: OptionalType>(dict: [String: T]) -> RouterResponse {
        return send(json: JSON(dict.removedNils))
    }

    @discardableResult
    public func render(_ resource: String) throws -> RouterResponse {
        return try render(resource, context: [:])
    }
}
