//
//  JSON.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public func loadJSONFromBundle<A: Decodable>(fileName: String) -> [A] {
    guard let url = Bundle.module.url(forResource: fileName, withExtension: "json") else {
        fatalError("Unable to find unimod.xml")
    }

    return loadJSONFromURL(url: url)
}

public func loadJSONFromURL<A: Decodable>(url: URL) -> [A] {
    guard let data = try? Data(contentsOf: url) else {
        fatalError("Unable to load \(url).json")
    }

    let decoder = JSONDecoder()

    guard let result = try? decoder.decode([A].self, from: data) else {
        fatalError("Failed to decode \(url).json")
    }

    return result
}
