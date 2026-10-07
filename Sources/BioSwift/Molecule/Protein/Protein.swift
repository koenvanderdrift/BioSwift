//
//  Protein.swift
//  BioSwift
//
//  Created by Koen van der Drift on 7/18/21.
//  Copyright © 2021 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation

/// Protein contains one or more ``ProteinChain`` values.
public typealias Protein = BioMolecule<ProteinChain>

extension BioMolecule where ChainType == ProteinChain {
    public init(sequence: String) throws {
        self.init(chains: [try ProteinChain(sequence: sequence)])
    }

    public init(sequences: [String]) throws {
        self.init(chains: try sequences.map {
            try ProteinChain(sequence: $0)
        })
    }

    public init(fastaRecord: FastaRecord) throws {
        let name = fastaRecord.shortName.isEmpty ? fastaRecord.fullName : fastaRecord.shortName
        self.init(chains: [try ProteinChain(sequence: fastaRecord.sequence, name: name)])
    }

    public init(residues: [AminoAcid]) {
        self.init(chains: [ProteinChain(residues: residues)])
    }

    public func truncate(by range: Range<Int>) throws -> Protein {
        guard let chain = chains.first else {
            throw BioSwiftDiagnostics.logged(CrossLinkError.invalidChainIndex(0))
        }
        return Protein(chains: [try chain.removingResidues(in: range)])
    }

    public var nTermModifications: [Modification] {
        get throws {
            if let nTermAA = residues.first {
                var nTermGroups = try UnimodModificationReferenceDefaults.loadBundled().modifications.filter { mod in
                mod.specificities.contains { spec in
                    spec.position.contains("Protein N-term") && spec.site == nTermAA.oneLetterCode
                }
            }

            nTermGroups.append(hydrogenModification)

            return nTermGroups
        }

            return []
        }
    }

    public var cTermModifications: [Modification] {
        get throws {
            if let cTermAA = residues.last {
                var cTermGroups = try UnimodModificationReferenceDefaults.loadBundled().modifications.filter { mod in
                mod.specificities.contains { spec in
                    spec.position.contains("Protein C-term") && spec.site == cTermAA.oneLetterCode
                }
            }

            cTermGroups.append(hydroxylModification)

            return cTermGroups
        }

            return []
        }
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
