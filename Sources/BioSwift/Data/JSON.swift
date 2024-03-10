//
//  JSON.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/21/19.
//  Copyright © 2019 - 2024 Koen van der Drift. All rights reserved.
//

import Foundation

public func parseJSONData<A: Decodable>(from fileName: String) throws -> [A] {
    do {
        let data = try loadData(from: fileName, withExtension: "json")
        return try JSONDecoder().decode([A].self, from: data)
    } catch {
        throw LoadError.fileDecodingFailed(name: fileName)
    }
}

public func parseJSONDataFromBundle<A: Decodable>(from fileName: String) throws -> [A] {
    do {
        let data = try loadDataFromBundle(from: fileName, withExtension: "json")
        return try JSONDecoder().decode([A].self, from: data)
    } catch {
        throw LoadError.fileDecodingFailed(name: fileName)
    }
}
