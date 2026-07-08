//
//  JSON.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/21/19.
//  Copyright © 2019 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public func parseJSONData<A: Decodable>(_: A.Type, from fileName: String) throws -> [A] {
    let fullName = "\(fileName).json"

    let data = try loadData(from: fileName, withExtension: "json")

    do {
        return try JSONDecoder().decode([A].self, from: data)
    } catch {
        throw LoadError.fileDecodingFailed(name: fullName, underlyingError: error)
    }
}

public func parseJSONDataFromBundle<A: Decodable>(_: A.Type, from fileName: String) throws -> [A] {
    let fullName = "\(fileName).json"

    let data = try loadData(
        from: fileName,
        withExtension: "json",
        in: .module)

    do {
        return try JSONDecoder().decode([A].self, from: data)
    } catch {
        throw LoadError.fileDecodingFailed(
            name: fullName,
            underlyingError: error)
    }
}
