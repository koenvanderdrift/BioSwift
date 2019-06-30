import Foundation

public var enzymeLibrary: [Enzyme] = loadJSONFromBundle(fileName: "enzymes")


//enum CleaveDirection {
//    case C
//    case N
//}

public class Enzyme: Codable {
    public let name: String
    public let cleaveAt: [String]
    public let dontCleaveBefore: [String]
    public let cleaveDirection: String
    public let fullName: String
    public let alternativeName: String
    
    private enum CodingKeys: String, CodingKey {
        case name
        case cleaveAt
        case dontCleaveBefore
        case cleaveDirection
        case fullName
        case alternativeName
    }
    
    public init(name: String, cleaveAt: [String], dontCleaveBefore: [String] = [], cleaveDirection: String, fullName: String = "", alternativeName: String = "") {
        self.name = name
        self.cleaveAt = cleaveAt
        self.dontCleaveBefore = dontCleaveBefore
        self.cleaveDirection = cleaveDirection
        self.fullName = fullName
        self.alternativeName = alternativeName
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try values.decode(String.self, forKey: .name)
        cleaveAt = try values.decode([String].self, forKey: .cleaveAt)
        dontCleaveBefore = try values.decode([String].self, forKey: .dontCleaveBefore)
        cleaveDirection = try values.decode(String.self, forKey: .cleaveDirection)
        fullName = try values.decode(String.self, forKey: .fullName)
        alternativeName = try values.decode(String.self, forKey: .alternativeName)
    }
}

extension Enzyme {
    public func regex() -> String {
        var regex = ""

        if cleaveDirection == "C" {
            regex = String(format: "(?<=[%@])", cleaveAt)

            if !dontCleaveBefore.isEmpty {
                regex = regex + String(format: "(?=[^%@])", dontCleaveBefore)
            }
        } else if cleaveDirection == "N" {
            regex = String(format: "(?=[%@])", cleaveAt)
        }

        return regex
    }
}
