//
//  DictionaryExtensions.swift
//  Simple
//
//  Created by Alexey Globchastyy on 23/01/2017.
//
//

import SwiftyJSON

public protocol OptionalType {
    associatedtype Wrapped
    func map<U>(_ f: (Wrapped) throws -> U) rethrows -> U?
}

extension Optional: OptionalType {}

extension Dictionary where Value: OptionalType {
    public var removedNils: [Key: Value] {
        var result = [Key: Value]()
        for el in self {
            guard let _ = el.value.map({ $0 }) else { continue }
            result[el.key] = el.value
        }
        return result
    }
}

extension Dictionary {
    public init(_ elements: [(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
}
