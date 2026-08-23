//
//  Utilities.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/21/19.
//  Copyright © 2019 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public enum BioSwiftDiagnostics {
    public static var isDebugLoggingEnabled = false

    public static func log(_ message: @autoclosure () -> Any) {
        guard isDebugLoggingEnabled else {
            return
        }

        debugPrint(message())
    }
}

public enum LoadError: Error {
    case fileNotFound(
        name:
            String)
    case fileReadFailed(
        name:
            String, underlyingError: Error)
    case fileConversionFailed(
        name:
            String, underlyingError: Error?)
    case fileDecodingFailed(
        name:
            String, underlyingError: Error)
    case fileParsingFailed(
        name:
            String, underlyingError: Error?)
}

public func loadData(
    from fileName: String, withExtension fileExtension: String, in bundle: Bundle = .main
) throws -> Data {
    let fullName = "\(fileName).\(fileExtension)"

    guard let url = bundle.url(forResource: fileName, withExtension: fileExtension) else {
        throw LoadError.fileNotFound(name: fullName)
    }

    do {
        return try Data(contentsOf: url)
    } catch {
        throw LoadError.fileReadFailed(name: fullName, underlyingError: error)
    }
}

public func loadText(from fileName: String, withExtension fileExtension: String, in bundle: Bundle = .main, encoding: String.Encoding = .utf8) throws -> String {
    let fullName = "\(fileName).\(fileExtension)"

    guard let url = bundle.url(forResource: fileName, withExtension: fileExtension) else {
        throw LoadError.fileNotFound(name: fullName)
    }

    do {
        return try String(contentsOf: url, encoding: encoding)
    } catch {
        throw LoadError.fileReadFailed(name: fullName, underlyingError: error)
    }
}

public func loadText(from url: URL, encoding: String.Encoding = .utf8) throws -> String {
    do {
        return try String(contentsOf: url, encoding: encoding)
    } catch {
        throw LoadError.fileReadFailed(name: url.lastPathComponent, underlyingError: error)
    }
}

func measure<T>(_ name: String, operation: () -> T) -> T {
    let start = DispatchTime.now().uptimeNanoseconds

    let result = operation()

    let end = DispatchTime.now().uptimeNanoseconds
    let milliseconds = Double(end - start) / 1_000_000

    BioSwiftDiagnostics.log("\(name): \(String(format: "%.3f ms", milliseconds))")

    return result
}

