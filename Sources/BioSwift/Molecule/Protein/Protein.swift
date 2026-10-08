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
        residue(at: location, chainIndex: chainIndex)
    }

    public func aminoAcid(at location: Int, chainName: String) -> AminoAcid? {
        residue(at: location, chainName: chainName)
    }

    public var aminoAcids: [AminoAcid] {
        residues
    }

    public func aminoAcids(chainIndex: Int) -> [AminoAcid] {
        residues(chainIndex: chainIndex)
    }

    public func aminoAcids(chainName: String) -> [AminoAcid]? {
        residues(chainName: chainName)
    }
}
