import Foundation

public struct DigestParameters {
    let sequence: String
    let missedCleavages: Int
    let regex: String

    public init(sequence: String, missedCleavages: Int, regex: String) {
        self.sequence = sequence
        self.missedCleavages = missedCleavages
        self.regex = regex
    }
    
    func cleavageSites() -> [Int] {
        return sequence.matches(for: regex).map { $0.range.location }
    }
}

//protocol Digest {} ?
public struct Digester {
    let parameters: DigestParameters
    
    public init(parameters: DigestParameters) {
        self.parameters = parameters
    }
}

extension Digester {
    public func digest() -> [String] {
        let subSequences = createSubSequences(sites: parameters.cleavageSites(), missedCleavages: parameters.missedCleavages)

        return subSequences
    }

    func createSubSequences(sites: [Int], missedCleavages: Int) -> [String] {
        var subSequences = [String]()

        var start = parameters.sequence.startIndex
        var end = start

        for site in sites {
            end = parameters.sequence.index(parameters.sequence.startIndex, offsetBy: site)

            subSequences.append(String(parameters.sequence[start ..< end]))

            start = end
        }

        subSequences.append(String(parameters.sequence[start ..< parameters.sequence.endIndex]))

        guard missedCleavages > 0 else {
            return subSequences
        }
        
        var joinedSubSequences = [String]()

        for mc in 0 ... missedCleavages {
            for (index, _) in subSequences.enumerated() {
                let newIndex = index + mc

                if subSequences.indices.contains(newIndex) {
                    joinedSubSequences.append(subSequences[index ... newIndex].joined())
                }
            }
        }

        return joinedSubSequences
    }
}
