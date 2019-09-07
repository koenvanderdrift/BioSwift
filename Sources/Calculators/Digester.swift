import Foundation

// this can be an extension in BioSequence ?

public struct DigestParameters {
    let sequence: String
    let sequenceType: SequenceType
//    let minimumMass: Double
//    let maximumMass: Double
//    let minimumCharge: Int
//    let maximumCharge: Int
    let missedCleavages: Int
    let regex: String

    public init(sequence: String, sequenceType: SequenceType, missedCleavages: Int, regex: String) {
        self.sequence = sequence
        self.sequenceType = sequenceType
//        self.minimumMass = minimumMass
//        self.maximumMass = maximumMass
//        self.minimumCharge = minimumCharge
//        self.maximumCharge = maximumCharge
        self.missedCleavages = missedCleavages
        self.regex = regex
    }
    
    func cleavageSites() -> [Int] {
        return sequence.matches(for: regex).map { $0.range.location }
    }
}

//protocol Digest {}
public struct Digester {
    let parameters: DigestParameters
    
    public init(parameters: DigestParameters) {
        self.parameters = parameters
    }
}

extension Digester {
    public func digest() -> [BioSequence] {
        let subSequences = createSubSequences(sites: parameters.cleavageSites(), missedCleavages: parameters.missedCleavages)

        return subSequences
            .map { BioSequence(sequence: $0, type: parameters.sequenceType, charge: 0) }
        // this is UI and should not be here
//            .charge(minCharge: parameters.minimumCharge, maxCharge: parameters.maximumCharge)
//            .filter { parameters.minimumMass < $0.massOverCharge().monoisotopicMass && $0.massOverCharge().averageMass < parameters.maximumMass }
//            .sorted(by: { $0.masses.monoisotopicMass < $1.masses.monoisotopicMass })
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
