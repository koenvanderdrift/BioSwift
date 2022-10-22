//
//  Utilities.swift
//  BioSwift
//
//  Created by Koen van der Drift on 3/21/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public enum LoadError: Error {
    case fileNotFound(name: String)
    case fileConversionFailed(name: String)
    case fileDecodingFailed(name: String)
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

public func loadDataFromBundle(from fileName: String, withExtension fileExtension: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: fileName, withExtension: fileExtension) else {
        throw LoadError.fileNotFound(name: fileName)
    }

    guard let data = try? Data(contentsOf: url) else {
        throw LoadError.fileConversionFailed(name: fileName)
    }

    return data
}




// via:  http://stackoverflow.com/questions/41402770/swift-parse-string-with-different-formats/41402868#41402868
//
// This type alias is just here to make the next line a bit more readable.
// A `BoolInstanceMethod<T, U>` is a closure type that represents an unapplied
// instance method that ultimately returns a Bool.
//
// For example, `String.hasPrefix` has type `(String) -> (String) -> Bool`.
// The first argument, of type `T` (String, in this case) is the instance
// this method will be called on.
//
// Say we call this: String.hasPrefix("The quick brown fox").
// The result has type `(String) -> Bool`.
// It's equivalent to "The quick brown fox".hasPrefix.
//
// We then call the resulting closure with the arguement to hasPrefix
// For example: String.hasPrefix("The quick brown fox")("The")
// This has type `Bool`. It's the same as: "The quick brown fox".hasPrefix("The)
//
//typealias BoolInstanceMethod<T, U> = (_ instance: T) -> (_ arg: U) -> Bool
//
// This function wraps a given instance method, in such a way as to reverse the
// order of the curried arguements. The given instance method is usually called as:
// Type.instanceMethod(instance)(arg), but this function allows you to swap it, to
// call it as: apply(Type.instanceMethod)(arg)(instance)
//
//func apply<T, U>(instanceMethod: @escaping BoolInstanceMethod<T, U>) -> (_ arg: U) -> (_ instance: T) -> Bool {
//    return { arg in
//        { instance in
//            instanceMethod(instance)(arg)
//        }
//    }
//}
//
// This pattern matching operator defines what it means to have a closure as a pattern.  If the closure evaluates to true when called
// with `value` as an arg, then the `pattern` matches the `value`.
//
//func ~= <T>(pattern: (T) -> Bool, value: T) -> Bool {
//    return pattern(value)
//}
//
//
//typealias SortDescriptor<A> = (A, A) -> Bool
//
// func sortDescriptor<Value, Property>(property: @escaping (Value) -> Property, comparator: @escaping (Property) -> (Property) -> ComparisonResult) -> SortDescriptor<Value> {
//    return { value1, value2 in
//        comparator(property(value1))(property(value2)) == .orderedAscending
//    }
// }
//
// func sortDescriptor<Value, Property>(property: @escaping (Value) -> Property) -> SortDescriptor<Value> where Property: Comparable {
//    return { value1, value2 in
//        property(value1) < property(value2)
//    }
// }
//
// func combine<A>(sortDescriptors: [SortDescriptor<A>]) -> SortDescriptor<A> {
//    return { value1, value2 in
//        for descriptor in sortDescriptors {
//            if descriptor(value1, value2) { return true }
//            if descriptor(value2, value1) { return false }
//        }
//
//        return false
//    }
// }
//
// @discardableResult
// public func measure<A>(_ name: String = "", _ block: () -> A) -> A {
//    let startTime = CACurrentMediaTime()
//    let result = block()
//    let timeElapsed = CACurrentMediaTime() - startTime
//    debugPrint("Time: \(name) - \(timeElapsed)")
//    return result
// }
//
// public func loadPListFromBundle(filename: String) -> [String: AnyObject]? {
//    if let bundle = Bundle(identifier: bioSwiftBundleIdentifier) {
//        do {
//            let url = bundle.url(forResource: filename, withExtension: "plist")
//            let data = try Data(contentsOf: url!)
//            let dict = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: AnyObject]
//
//            return dict
//        } catch {
//            debugPrint(error.localizedDescription)
//        }
//    }
//
//    return nil
// }
//
// public func loadTextFromBundle(filename: String, type: String) -> String? {
//    guard
//        let path = Bundle.main.path(forResource: filename, ofType: type)
//    else { return nil }
//
//    let text: String
//
//    do {
//        text = try String(contentsOfFile: path)
//    } catch {
//        text = ""
//    }
//
//    return text
// }
//
// @discardableResult public func time<Result>(name: StaticString = #function, line: Int = #line, _ f: () -> Result) -> Result {
//    // via: https://talk.objc.io/episodes/S01E90-concurrent-map
//    let startTime = DispatchTime.now()
//    let result = f()
//    let endTime = DispatchTime.now()
//    let diff = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000 as Double
//    debugPrint("\(name) (line \(line)): \(diff) sec")
//    return result
// }
//
//
