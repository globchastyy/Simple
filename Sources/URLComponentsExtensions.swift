//
//  URLComponentsExtensions.swift
//  Simple
//
//  Created by Alexey Globchastyy on 23/01/2017.
//
//

import Foundation

public extension URLComponents {
    public init?(string: String, queryItems: [URLQueryItem]) {
        self.init(string: string)
        self.queryItems = queryItems
    }
}
