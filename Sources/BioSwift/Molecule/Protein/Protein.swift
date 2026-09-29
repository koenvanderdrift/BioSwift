//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// Protein contains one or more ``Peptide`` chains.
public typealias Protein = BioMolecule<Peptide>

extension BioMolecule where ChainType == Peptide {
    public init(sequence: String) {
        self.init(chains: [Peptide(sequence: sequence)])
    }

    public init(sequences: [String]) {
        self.init(chains: sequences.map {
            Peptide(sequence: $0)
        })
    }

    public init(fastaRecord: FastaRecord) {
        var peptide = Peptide(sequence: fastaRecord.sequence)
        peptide.name = fastaRecord.shortName.isEmpty ? fastaRecord.fullName : fastaRecord.shortName

        self.init(chains: [peptide])
    }

    public init(residues: [AminoAcid]) {
        self.init(chains: [Peptide(residues: residues)])
    }

    public func truncate(by range: Range<Int>) -> Protein {
        if let subChain = chains.first?.removing(range) {
            return Protein(chains: [subChain])
        }

        return self
    }

    public var nTermModifications: [Modification] {
        if let nTermAA = residues.first {
            var nTermGroups = UnimodModificationReferenceDefaults.bundled.modifications.filter { mod in
                mod.specificities.contains { spec in
                    spec.position.contains("Protein N-term") && spec.site == nTermAA.oneLetterCode
                }
            }

            nTermGroups.append(hydrogenModification)

            return nTermGroups
        }

        return []
    }

    public var cTermModifications: [Modification] {
        if let cTermAA = residues.last {
            var cTermGroups = UnimodModificationReferenceDefaults.bundled.modifications.filter { mod in
                mod.specificities.contains { spec in
                    spec.position.contains("Protein C-term") && spec.site == cTermAA.oneLetterCode
                }
            }

            cTermGroups.append(hydroxylModification)

            return cTermGroups
        }

        return []
    }

    public var nTermLocation: Int? {
        nTermLocation(chainIndex: 0)
    }

    public func nTermLocation(chainIndex: Int) -> Int? {
        guard chains.indices.contains(chainIndex), chains[chainIndex].sequenceLength > 0 else {
            return nil
        }

        return 0
    }

    public func nTermLocation(chainName: String) -> Int? {
        guard let chain = chain(named: chainName), chain.sequenceLength > 0 else {
            return nil
        }
        return 0
    }

    public var cTermLocation: Int? {
        cTermLocation(chainIndex: 0)
    }

    public func cTermLocation(chainIndex: Int) -> Int? {
        guard chains.indices.contains(chainIndex), chains[chainIndex].sequenceLength > 0 else {
            return nil
        }

        return chains[chainIndex].sequenceLength - 1
    }

    public func cTermLocation(chainName: String) -> Int? {
        guard let chain = chain(named: chainName), chain.sequenceLength > 0 else {
            return nil
        }
        return chain.sequenceLength - 1
    }

    public func aminoAcid(at location: Int, chainIndex: Int = 0) -> AminoAcid? {
        let aminoAcids = aminoAcids(chainIndex: chainIndex)
        guard aminoAcids.indices.contains(location) else {
            return nil
        }

        return aminoAcids[location]
    }

    public func aminoAcid(at location: Int, chainName: String) -> AminoAcid? {
        guard let aminoAcids = aminoAcids(chainName: chainName), aminoAcids.indices.contains(location) else {
            return nil
        }
        return aminoAcids[location]
    }

    public var aminoAcids: [AminoAcid] {
        aminoAcids(chainIndex: 0)
    }

    public func aminoAcids(chainIndex: Int) -> [AminoAcid] {
        residues(chainIndex: chainIndex) as? [AminoAcid] ?? []
    }

    public func aminoAcids(chainName: String) -> [AminoAcid]? {
        chain(named: chainName)?.residues
    }
}
