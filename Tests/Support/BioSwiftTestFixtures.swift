//
//  BioSwiftTestFixtures.swift
//  BioSwift
//
//  Created by Koen van der Drift on 26.12.2025.
//  Copyright © 2025 - 2026 Koen van der Drift. All rights reserved.
//

import Foundation
import Testing

@testable import BioSwift

func decimal(_ value: String) -> Decimal {
    guard let result = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
        preconditionFailure("Invalid Decimal test value: \(value)")
    }

    return result
}

private func formula(_ value: String) -> Formula {
    do {
        return try Formula(value)
    } catch {
        preconditionFailure("Invalid Formula test value: \(value): \(error)")
    }
}

private func protein(_ sequence: String) -> Protein {
    do {
        return try Protein(sequence: sequence)
    } catch {
        preconditionFailure("Unable to create test protein: \(error)")
    }
}

private func peptide(_ sequence: String) -> Peptide {
    do {
        return try Peptide(sequence: sequence)
    } catch {
        preconditionFailure("Unable to create test peptide: \(error)")
    }
}

struct BioSwiftTestFixtures {
    var testProtein = protein(
            "MPSSVSWGILLLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK"
    )
    var testPeptide = peptide("DWSSD")
    var alanine = AminoAcid(
        name: "Alanine", oneLetterCode: "A", threeLetterCode: "Ala", formula: formula("C3H5NO"))
    var serine = AminoAcid(
        name: "Serine", oneLetterCode: "S", threeLetterCode: "Ser", formula: formula("C3H5NO2"))

}

protocol BioSwiftTestSuite {
    var fixtures: BioSwiftTestFixtures { get set }
}

extension BioSwiftTestSuite {
    var testProtein: Protein {
        _read { yield fixtures.testProtein }
        _modify { yield &fixtures.testProtein }
    }

    var testPeptide: Peptide {
        _read { yield fixtures.testPeptide }
        _modify { yield &fixtures.testPeptide }
    }

    var alanine: AminoAcid {
        _read { yield fixtures.alanine }
        _modify { yield &fixtures.alanine }
    }

    var serine: AminoAcid {
        _read { yield fixtures.serine }
        _modify { yield &fixtures.serine }
    }

    func modifications(
        unimodName: String,
        psiModAccession: String,
        uniProtPTMAccession: String? = nil
    ) throws -> [Modification] {
        let libraries = try ReferenceLibraryDefaults.loadBundled()
        let unimodModification = try #require(
            libraries.unimodLibrary.modification(named: unimodName))
        let psiModModification = try #require(
            libraries.psiModLibrary.modification(accession: psiModAccession))
        var result = [unimodModification, psiModModification]

        if let uniProtPTMAccession {
            result.append(try #require(
                libraries.uniProtPTMLibrary.modification(accession: uniProtPTMAccession)))
        }

        return result
    }
}
