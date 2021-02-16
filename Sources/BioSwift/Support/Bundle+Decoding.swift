//
//  Bundle+Decoding.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/27/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public let bioSwiftBundleIdentifier = "BioSwift"

public enum SharedResources {
    static public let aminoacidsURL = Bundle.module.url(forResource: "aminoacids", withExtension: "json")
    static public let elementsURL = Bundle.module.url(forResource: "elements", withExtension: "json")
    static public let enzymesURL = Bundle.module.url(forResource: "enzymes", withExtension: "json")
    static public let functionalgroupsURL = Bundle.module.url(forResource: "functionalgroups", withExtension: "json")
    static public let hydropathyURL = Bundle.module.url(forResource: "hydropathy", withExtension: "json")
    static public let unimodURL = Bundle.module.url(forResource: "unimod", withExtension: "xml")
}

// via https://www.hackingwithswift.com/example-code/system/how-to-decode-json-from-your-app-bundle-the-easy-way

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type,
                              from file: String,
                              dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                              keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy

        do {
            return try decoder.decode(T.self, from: data)
        } catch let DecodingError.keyNotFound(key, context) {
            fatalError("Failed to decode \(file) from bundle due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch let DecodingError.typeMismatch(_, context) {
            fatalError("Failed to decode \(file) from bundle due to type mismatch – \(context.debugDescription)")
        } catch let DecodingError.valueNotFound(type, context) {
            fatalError("Failed to decode \(file) from bundle due to missing \(type) value – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(_) {
            fatalError("Failed to decode \(file) from bundle because it appears to be invalid JSON")
        } catch {
            fatalError("Failed to decode \(file) from bundle: \(error.localizedDescription)")
        }
    }
}
