//
//  JSON.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public func loadJSONFromBundle<A: Decodable>(fileName: String) -> [A] {
    guard let bundle = Bundle(identifier: bioSwiftBundleIdentifier) else {
        fatalError("Unable to load bundle")
    }

    guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
        fatalError("Unable to find \(fileName).json")
    }

    guard let data = try? Data(contentsOf: url) else {
        fatalError("Unable to load \(fileName).json")
    }

    let decoder = JSONDecoder()

    guard let result = try? decoder.decode([A].self, from: data) else {
        fatalError("Failed to decode \(fileName).json")
    }

    return result
}
