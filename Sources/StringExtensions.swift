//
//  StringExtensions.swift
//  Simple
//
//  Created by Alexey Globchastyy on 24/01/2017.
//
//

import Foundation

extension String {
    var asPath: String {
        return self.lowercased()
            .replacingOccurrences(of: " - ", with: "-")
            .replacingOccurrences(of: " / ", with: "-")
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "-")
            .replacingOccurrences(of: "&", with: "and")
    }

}
