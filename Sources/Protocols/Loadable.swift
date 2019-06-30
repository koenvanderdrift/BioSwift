import Foundation

// do we need identifier as a property here?

protocol Loadable {
    var identifier: String { get }
    init(identifier: String, info: [String: AnyObject])
}

func loadPList<T: Loadable>(filename: String) -> [String: T]? {
    guard let plistDict = loadPListFromBundle(filename: filename)
    else {
        print("plist not loaded")
        return nil
    }

    var dict = [String: T]()

    for (key, f) in plistDict {
        if let info = f as? [String: AnyObject] {
            let foo = T(identifier: key, info: info)
            dict[key] = foo
        }
    }

    return dict
}
