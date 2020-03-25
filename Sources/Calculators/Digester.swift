import Foundation

public struct DigestParameters {
    let sequence: BioSequence
    let missedCleavages: Int
    let regex: String

    public init(sequence: BioSequence, missedCleavages: Int, regex: String) {
        self.sequence = sequence
        self.missedCleavages = missedCleavages
        self.regex = regex
    }
    
    var string: String {
        return sequence.sequenceString
    }
    
    func cleavageSites() -> [Int] {
        return string.matches(for: regex).map { $0.range.location }
    }
}

public struct Digester<T: BioSequence> {
    let parameters: DigestParameters
    
    public init(parameters: DigestParameters) {
        self.parameters = parameters
    }
}

extension Digester {
    public func digest() -> [T] {
        let subSequences = createSubSequences(sites: parameters.cleavageSites(), missedCleavages: parameters.missedCleavages)

        return subSequences
    }

    func createSubSequences(sites: [Int], missedCleavages: Int) -> [T] {
        var subSequences = [T]()
        let residues = parameters.sequence.residueSequence
        
        var start = residues.startIndex
        var end = start

        for site in sites {
            end = residues.index(residues.startIndex, offsetBy: site)

            let new: T = parameters.sequence.subSequence(from: start, to: end)
            subSequences.append(new)

            start = end
        }

        let final: T = parameters.sequence.subSequence(from: start, to: residues.endIndex)
        
        subSequences.append(final)

        guard missedCleavages > 0 else {
            return subSequences
        }
        
        var joinedSubSequences = [T]()

        for mc in 0 ... missedCleavages {
            for (index, _) in subSequences.enumerated() {
                let newIndex = index + mc
                if subSequences.indices.contains(newIndex) {
                    let res = subSequences[index...newIndex]
                        .reduce([], { $0 + $1.residueSequence })
                    let new = T(residues: res, library: parameters.sequence.symbolLibrary)
                    
                    joinedSubSequences.append(new)
                }
            }
        }
        
        return joinedSubSequences
    }
}
