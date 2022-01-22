//
//  JSON.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

enum LoadError: Error {
    case fileNotFound(name: String)
    case fileConversionFailed(name: String)
    case fileDecodingFailed(name: String)
}

public func loadDataFromBundle(from fileName: String, withExtension fileExtension: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: fileName, withExtension: fileExtension) else {
        throw LoadError.fileNotFound(name: fileName)
    }

    guard let data = try? Data(contentsOf: url) else {
        throw LoadError.fileConversionFailed(name: fileName)
    }

    return data
}

public func parseJSONDataFromBundle<A: Decodable>(from fileName: String) throws -> [A] {
    do {
        let data = try loadDataFromBundle(from: fileName, withExtension: "json")
        return try JSONDecoder().decode([A].self, from: data)
    }
    catch {
        throw LoadError.fileDecodingFailed(name: fileName)
    }
}

public func loadData(from fileName: String, withExtension fileExtension: String) throws -> Data {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
        throw LoadError.fileNotFound(name: fileName)
    }

    guard let data = try? Data(contentsOf: url) else {
        throw LoadError.fileConversionFailed(name: fileName)
    }

    return data
}

public func parseJSONData<A: Decodable>(from fileName: String) throws -> [A] {
    do {
        let data = try loadData(from: fileName, withExtension: "json")
        return try JSONDecoder().decode([A].self, from: data)
    }
    catch {
        throw LoadError.fileDecodingFailed(name: fileName)
    }
}

