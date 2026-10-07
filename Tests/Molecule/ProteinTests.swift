//
//  ProteinTests.swift
//  BioSwift
//

import Foundation
import Testing

@testable import BioSwift

@Suite struct ProteinTests: BioSwiftTestSuite {
    var fixtures = BioSwiftTestFixtures()
    @Test func sequenceLength() throws {
        #expect(testProtein.sequenceLength == 418)
        #expect(testPeptide.sequenceString.count == 5)
    }

    @Test func moleculeExposesFirstChainSequenceProperties() throws {
        let protein = try Protein(sequences: ["PEPTIDE", "SECNDS"])

        #expect(protein.sequence == "PEPTIDE")
        #expect(protein.sequenceLength == 7)
        #expect(protein.sequence(chainIndex: 1) == "SECNDS")
        #expect(protein.sequenceLength(chainIndex: 1) == 6)
    }

    @Test func proteinPreservesSingleChainIdentityAndMetadata() throws {
        let id = UUID()
        var chain = try ProteinChain(sequence: "MKT", name: "alpha", id: id)
        chain.range = 4..<7
        chain.parentLength = 12

        let protein = Protein(chains: [chain])
        let storedChain = try #require(protein.chains.first)

        #expect(protein.chains.count == 1)
        #expect(storedChain.id == id)
        #expect(storedChain.name == "alpha")
        #expect(storedChain.sequenceString == "MKT")
        #expect(storedChain.range == 4..<7)
        #expect(storedChain.parentLength == 12)
    }

    @Test func proteinPreservesMultipleChainsInOrder() throws {
        let firstID = UUID()
        let secondID = UUID()
        let first = try ProteinChain(sequence: "MKT", name: "alpha", id: firstID)
        let second = try ProteinChain(sequence: "SEQUENCE", name: "beta", id: secondID)

        let protein = Protein(chains: [first, second])

        #expect(protein.chains.map(\.id) == [firstID, secondID])
        #expect(protein.chains.map(\.name) == ["alpha", "beta"])
        #expect(protein.chains.map(\.sequenceString) == ["MKT", "SEQUENCE"])
    }

    @Test func aminoAcidChainsAcceptNamesDuringInitialization() throws {
        let id = UUID()
        let proteinChain = try ProteinChain(sequence: "MKT", name: "heavy chain", id: id)
        let peptide = try Peptide(sequence: "PEPTIDE", name: "digest product")

        #expect(proteinChain.name == "heavy chain")
        #expect(proteinChain.id == id)
        #expect(peptide.name == "digest product")
        #expect(try ProteinChain(sequence: "MKT").name.isEmpty)
        #expect(try Peptide(sequence: "PEPTIDE").name.isEmpty)
    }

    @Test func moleculeAccessesChainsByName() throws {
        let first = try ProteinChain(sequence: "PEPTIDE", name: "alpha")
        let second = try ProteinChain(sequence: "SECNDS", name: "beta")
        let protein = Protein(chains: [first, second])

        #expect(protein.chain(named: "beta")?.sequenceString == "SECNDS")
        #expect(protein.chainIndex(named: "beta") == 1)
        #expect(protein.sequence(chainName: "beta") == "SECNDS")
        #expect(protein.sequenceLength(chainName: "beta") == 6)
        #expect(protein.aminoAcids(chainName: "beta")?.count == 6)
        #expect(protein.aminoAcid(at: 0, chainName: "beta")?.identifier == "S")
        #expect(protein.sequence(chainName: "missing") == nil)
    }

    @Test func duplicateChainNamesResolveToFirstChain() throws {
        let first = try ProteinChain(sequence: "FIRST", name: "shared")
        let second = try ProteinChain(sequence: "SECNDS", name: "shared")

        #expect(Protein(chains: [first, second]).sequence(chainName: "shared") == "FIRST")
    }

    @Test func structuresExposeFormulaStringsDirectly() throws {
        let peptide = try Peptide(sequence: "A")
        let protein = try Protein(sequence: "A")

        #expect(peptide.formulaString == peptide.formula.formulaString)
        #expect(protein.formulaString == protein.formula.formulaString)
    }

    @Test func proteinResidueCount() throws {
        let cysCount = testProtein.residueCount(for: "C")
        #expect(cysCount == 3)

        let glnCount = testProtein.residueCount(for: "Q")
        #expect(glnCount == 18)
    }

    @Test func peptideResidueCount() throws {
        let countedSet = testPeptide.residueCounts

        if let ser = try ReferenceLibraryDefaults.loadBundled().aminoAcids.first(where: { $0.identifier == "S" }) {
            let aaCount = countedSet.count(for: ser)
            #expect(aaCount == 2)
        }
    }

    @Test func sequenceWithIllegalCharactersThrows() throws {
        #expect(
            throws: SequenceValidationError.invalidResidue(
                "_", position: 1, sequenceType: "protein")
        ) {
            try Protein(sequence: "D___WS83SD")
        }
    }

    @Test func proteinFormula() throws {
        #expect(testProtein.formula.elementCount(for: "C") == 2112)
    }  // C2112H3313N539O629S13

    @Test func proteinFormulaMatchesExplicitResidueFormulaSum() throws {
        let chain = try #require(testProtein.chains.first)
        var explicitFormula = zeroFormula

        for residue in chain.residues {
            explicitFormula += residue.formula

            if let modification = residue.modification {
                explicitFormula += modification.formula
            }
        }

        explicitFormula += chain.nTerminal.formula + chain.cTerminal.formula

        #expect(chain.formula == explicitFormula)
    }

    @Test func peptideFormula() throws {
        let peptide = try Peptide(sequence: "DWSSD")
        #expect(peptide.formula.elementCount(for: "C") == 25)
        #expect(peptide.formula.elementCount(for: "P") == 0)
    }

    @Test func elementInitializedWithExplicitMassesRetainsThem() throws {
        let element = ChemicalElement(
            name: "Test", symbol: "T", monoisotopicMass: decimal("12.6"),
            averageMass: decimal("12.75"))

        #expect(element.monoisotopicMass == decimal("12.6"))
        #expect(element.averageMass == decimal("12.75"))
        #expect(element.nominalMass == 13)
    }

    @Test func decodedFormulaRecalculatesMasses() throws {
        let formula = try Formula("H2O")
        let data = try JSONEncoder().encode(formula)
        let decodedFormula = try JSONDecoder().decode(Formula.self, from: data)

        #expect(decodedFormula.monoisotopicMass == formula.monoisotopicMass)
        #expect(decodedFormula.averageMass == formula.averageMass)
        #expect(decodedFormula.nominalMass == formula.nominalMass)
    }

    @Test func modifiedPeptideFormula() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var peptide = try Peptide(sequence: "DWSSD")
            try peptide.addModification(modification, at: 3)
            #expect(peptide.formula.elementCount(for: "P") == 1)
        }
    }

    @Test func waterAverageMass() throws {  // H2O
        #expect(water.averageMass.rounded(scale: 4) == decimal("18.0153"))
    }

    @Test func ammoniaAverageMass() throws {  // NH3
        #expect(ammonia.averageMass.rounded(scale: 4) == decimal("17.0305"))
    }

    @Test func methylAverageMass() throws {  // CH3
        // Expected values use isotope-abundance-weighted masses from the bundled NIST data.
        #expect(methyl.averageMass.rounded(scale: 4) == decimal("15.0346"))
    }

    @Test func formulaAverageMass() throws {  // C4H5NO3 + C11H10N2O + C3H5NO2 + C3H5NO2 + C4H5NO3 + H2O
        // Expected values use isotope-abundance-weighted masses from the bundled NIST data.
        let group = try FunctionalGroup(
            name: "", formula: "C4H5NO3" + "C11H10N2O" + "C3H5NO2" + "C3H5NO2" + "C4H5NO3" + "H2O")

        #expect(group.averageMass.rounded(scale: 3) == decimal("608.556"))
    }

    @Test func completeSequenceMassMatchesExplicitResidueSum() throws {
        let peptide = try Peptide(sequence: "SAMPLER")
        let explicitMasses = peptide.residues.reduce(zeroMass) {
            $0 + $1.masses
        } + peptide.terminalMasses()

        #expect(peptide.masses == explicitMasses)
    }

    @Test func modifiedCompleteSequenceMassMatchesExplicitResidueSum() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var peptide = try Peptide(sequence: "DWSSD")
            try peptide.addModification(modification, at: 3)
            let explicitMasses = peptide.residues.reduce(zeroMass) {
                $0 + $1.masses
            } + peptide.terminalMasses()

            #expect(peptide.masses == explicitMasses)
        }
    }

    @Test func chainMassesForIndividualResidues() throws {
        let peptide = try Peptide(sequence: "SAMPLER")
        BioSwiftDiagnostics.log(peptide.monoisotopicMass)

        #expect(peptide.monoisotopicMass.rounded(scale: 5) == decimal("802.40072"))
        #expect(peptide.nominalMass == 802)
        #expect(
            peptide.masses.applying(adducts: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("803.4080"))

        let peptideIon = try peptide.ionized(with: [protonAdduct, protonAdduct])
        #expect(peptideIon.monoisotopicMass.rounded(scale: 4) == decimal("402.2076"))
        #expect(peptideIon.nominalMass == 402)

        var sum = water.masses

        for aa in peptide.residues {
            sum += aa.masses
        }
        BioSwiftDiagnostics.log(sum.monoisotopicMass)

        #expect(sum.monoisotopicMass.rounded(scale: 5) == decimal("802.40072"))
        #expect(sum.applying(adducts: [protonAdduct, protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("402.2076"))

        sum = water.masses

        for aa in peptide.residues[1..<7] {
            sum += aa.masses
        }
        BioSwiftDiagnostics.log(sum.monoisotopicMass)

        #expect(sum.monoisotopicMass.rounded(scale: 5) == decimal("715.36870"))
        #expect(sum.applying(adducts: [protonAdduct, protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("358.6916"))

        // https://www.chemcalc.org/peptides?digestion=%5Bobject%20Object%5D&filter=%5Bobject%20Object%5D&fragmentation=a%3Dfalse%26b%3Dfalse%26c%3Dfalse%26i%3Dfalse%26n%3Dfalse%26x%3Dfalse%26y%3Dfalse%26ya%3Dfalse%26yb%3Dfalse%26z%3Dfalse&ionizations=H%2B.%28H%2B%292.%28H%2B%293&protonation=false&sequence=SAMPLER%0A%0A
    }

    @Test func peptideMonoisotopicMass() throws {
        #expect(try testPeptide.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("609.2151"))
        #expect(try testPeptide.ionized(with: [protonAdduct, protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("305.1112"))
    }

    @Test func massPropertiesApplyAdductsOnce() throws {
        let peptide = try Peptide(sequence: "DWSSD")
        let singlyCharged = try peptide.ionized(with: [protonAdduct])
        #expect(singlyCharged.charge == 1)
        #expect(singlyCharged.masses.monoisotopicMass == singlyCharged.monoisotopicMass)
        #expect(singlyCharged.monoisotopicMass.rounded(scale: 4) == decimal("609.2151"))

        let doublyCharged = try peptide.ionized(with: [protonAdduct, protonAdduct])
        #expect(doublyCharged.charge == 2)
        #expect(doublyCharged.masses.averageMass == doublyCharged.averageMass)
        #expect(doublyCharged.masses.nominalMass == doublyCharged.nominalMass)
        #expect(doublyCharged.monoisotopicMass.rounded(scale: 4) == decimal("305.1112"))
    }

    @Test func protonatedCreatesExactChargeStates() throws {
        let peptide = try Peptide(sequence: "DWSSD")
        let chargedPeptides = try [peptide].protonated(chargeStates: 1...2)

        #expect(chargedPeptides.map(\.charge) == [1, 2])
        #expect(chargedPeptides.allSatisfy { $0.adducts.allSatisfy { $0 == protonAdduct } })
        #expect(throws: MassCalculationError.invalidChargeState(-1)) {
            try [peptide].protonated(chargeStates: -1...2)
        }
    }

    @Test func peptideAverageMass() throws {
        // Expected values use isotope-abundance-weighted masses from the bundled NIST data.
        #expect(try testPeptide.ionized(with: [protonAdduct]).averageMass.rounded(scale: 4) == decimal("609.5630"))
        #expect(try testPeptide.ionized(with: [protonAdduct, protonAdduct]).averageMass.rounded(scale: 4) == decimal("305.2852"))
    }

    @Test func peptideSerinePhosphorylationMonoisotopicMass() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var peptide = testPeptide
            try peptide.addModification(modification, at: 3)

            #expect(try peptide.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("689.1814"))
            #expect(try peptide.ionized(with: [protonAdduct, protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("345.0944"))

            try peptide.removeModification(at: 3)
            #expect(try peptide.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("609.2151"))
        }
    }

    @Test func peptideReplaceModificationMonoisotopicMass() throws {
        let phosphorylations = try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253")
        let oxidations = try modifications(unimodName: "Oxidation", psiModAccession: "MOD:00425")

        for (phosphorylation, oxidation) in zip(phosphorylations, oxidations) {
            var peptide = testPeptide
            try peptide.addModification(phosphorylation, at: 3)

            #expect(try peptide.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("689.1814"))
            #expect(try peptide.ionized(with: [protonAdduct, protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("345.0944"))

            try peptide.addModification(oxidation, at: 3)
            #expect(peptide.modification(at: 3) == oxidation)
            #expect(try peptide.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("625.2100"))
        }
    }

    @Test func proteinMonoisotopicMass() throws {
        #expect(
            try testProtein.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 1)
                == decimal("46708.0267").rounded(scale: 1))
    }

    @Test mutating func proteinNTermMetLossMonoisotopicMass() throws {
        if let metLoss = try testProtein.nTermModifications.first(where: {
            $0.name == "Met-loss"
        }),
            let nTermLocation = testProtein.nTermLocation
        {
            try testProtein.addModification(metLoss, at: nTermLocation)
            #expect(
                try testProtein.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 1)
                    == (decimal("46708.0267") - decimal("131.040485)")).rounded(scale: 1))

            try testProtein.removeModification(at: nTermLocation)
            #expect(
                try testProtein.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 1)
                    == decimal("46708.0267").rounded(scale: 1))
        }
    }

    @Test mutating func proteinCTermLysLossMonoisotopicMass() throws {
        if let lysLoss = try testProtein.cTermModifications.first(where: {
            $0.name == "Lys-loss"
        }),
            let cTermLocation = testProtein.cTermLocation
        {
            try testProtein.addModification(lysLoss, at: cTermLocation)
            #expect(testProtein.chains[0].residues.last?.modification == lysLoss)
            #expect(
                try testProtein.ionized(with: [protonAdduct]).monoisotopicMass.formatted(fractionDigits: 1)
                    == (decimal("46708.0267") - decimal("128.094963)")).formatted(fractionDigits: 1))

            try testProtein.removeModification(at: cTermLocation)
            #expect(
                try testProtein.ionized(with: [protonAdduct]).monoisotopicMass.formatted(fractionDigits: 4)
                    == decimal("46708.0267").formatted(fractionDigits: 4))
        }
    }

    @Test func proteinAverageMass() throws {
        #expect(
            try testProtein.ionized(with: [protonAdduct]).averageMass.formatted(fractionDigits: 1) == decimal("46737.0703").formatted(fractionDigits: 1))
    }

    @Test func proteinSerinePhosphorylationMonoisotopicMass() throws {
        for modification in try modifications(
            unimodName: "Phospho", psiModAccession: "MOD:00046",
            uniProtPTMAccession: "PTM-0253") {
            var protein = testProtein
            try protein.addModification(modification, at: 3)
            #expect(
                try protein.ionized(with: [protonAdduct]).monoisotopicMass.formatted(fractionDigits: 1)
                    == decimal("46787.9931").formatted(fractionDigits: 1))  // 46787.9930

            #expect(
                try protein.ionized(with: [protonAdduct, protonAdduct]).monoisotopicMass.formatted(fractionDigits: 1)
                    == decimal("23394.5002").formatted(fractionDigits: 1))
        }
    }

    @Test func unimodModificationFullName() throws {
        let unimodModifications = try ReferenceLibraryDefaults.loadBundled().unimodLibrary.modifications

        if let pnTAG = unimodModifications.first(where: { $0.name == "PnTAG" }) {
            #expect(pnTAG.fullName == "6-Phosphonohexanoylation")

        }

        if let TMTpro = unimodModifications.first(where: { $0.name == "Label:13C(6)15N(2)+TMTpro" }) {
            #expect(TMTpro.fullName == "TMTpro Tandem Mass Tag 13C(6) 15N(2) Silac label")
        }
    }

    @Test func modifyResidues() throws {
        for modification in try modifications(unimodName: "Carbamidomethyl", psiModAccession: "MOD:01060") {
            var protein = testProtein
            try protein.modifyResidues(for: "C", with: modification)

            #expect(protein.residueCount(for: "C") == 3)
        }
    }

    @Test func invalidFormulaThrows() throws {
        #expect(throws: FormulaParser.ParseError.self) {
            try Formula("NotAnElement")
        }
    }

    @Test func emptyFormulaIsValid() throws {
        let formula = Formula()

        #expect(formula.countedElements.isEmpty)
        #expect(formula.formulaString.isEmpty)
    }

    @Test func addFormulas() throws {
        let formula1 = try Formula("C12H23O7N5")
        let formula2 = try Formula("C2H2O2")
        let formula3 = formula1 + formula2

        BioSwiftDiagnostics.log(formula3.formulaString)

        #expect(formula3.elementCount(for: "C") == 14)
        #expect(formula3.elementCount(for: "N") == 5)
    }

    @Test func formulaStringUsesHillSystemWithCarbon() throws {
        let formula = try Formula(elements: ["O": 6, "H": 12, "C": 6, "N": 1])

        #expect(formula.formulaString == "C6H12NO6")
    }

    @Test func formulaStringUsesHillSystemWithoutCarbon() throws {
        let formula = try Formula(elements: ["S": 1, "O": 4, "H": 2])

        #expect(formula.formulaString == "H2O4S")
    }

    @Test func formulaPreservesInputString() throws {
        let formula = try Formula("CH3(CH2)4CH3")

        #expect(formula.inputString == "CH3(CH2)4CH3")
        #expect(formula.formulaString == "C6H14")
    }

    @Test func subtractFormulas() throws {
        let formula1 = try Formula("C12H23O7N5")
        let formula2 = try Formula("C2H2O2")
        let formula3 = formula1 - formula2

        BioSwiftDiagnostics.log(formula3.formulaString)

        #expect(formula3.elementCount(for: "C") == 10)
        #expect(formula3.elementCount(for: "N") == 5)
    }

    @Test mutating func proteinAtomCount() throws {
        #expect(testProtein.formula.elementCount == 6606)
    }

    @Test func symbolAtIndex() throws {
        if let chain = testProtein.chains.first {
            let symbol = chain.symbol(at: 14)
            #expect(symbol?.identifier == "L")
        }
    }

    @Test func proteinAminoAcidAndTermLocationsAreOptional() throws {
        #expect(testProtein.aminoAcid(at: 0)?.identifier == "M")
        #expect(testProtein.aminoAcid(at: -1) == nil)
        #expect(testProtein.aminoAcid(at: 0, chainIndex: 10) == nil)
        #expect(testProtein.nTermLocation == 0)
        #expect(testProtein.nTermLocation(chainIndex: 10) == nil)
        #expect(try Protein(sequence: "").nTermLocation == nil)
        #expect(testProtein.cTermLocation == 417)
        #expect(testProtein.cTermLocation(chainIndex: 10) == nil)
        #expect(try Protein(sequence: "").cTermLocation == nil)
    }

    @Test mutating func replaceAminoAcid() throws {
        #expect(testPeptide.sequenceString == "DWSSD")

        if let gly = try ReferenceLibraryDefaults.loadBundled().aminoAcids.first(where: { $0.identifier == "G" }) {
            try testPeptide.replaceResidue(at: 0, with: gly)
            #expect(testPeptide.sequenceString == "GWSSD")
        }
    }

    @Test mutating func removeAminoAcid() throws {
        #expect(testPeptide.sequenceString == "DWSSD")
        try testPeptide.removeResidue(at: 3)
        #expect(testPeptide.sequenceString == "DWSD")
    }

    @Test mutating func insertAminoAcid() throws {
        #expect(testPeptide.sequenceString == "DWSSD")
        if let gly = try ReferenceLibraryDefaults.loadBundled().aminoAcids.first(where: { $0.identifier == "G" }) {
            try testPeptide.insertResidue(gly, at: 2)
        }

        #expect(testPeptide.sequenceString == "DWGSSD")
    }

    @Test mutating func insertAminoAcids() throws {
        #expect(testPeptide.sequenceString == "DWSSD")
        if let gly = try ReferenceLibraryDefaults.loadBundled().aminoAcids.first(where: {
            $0.identifier == "G"
        }),
            let pro = try ReferenceLibraryDefaults.loadBundled().aminoAcids.first(where: {
                $0.identifier == "P"
            })
        {
            try testPeptide.insertResidues([gly, pro, pro], at: 2)
        }

        #expect(testPeptide.sequenceString == "DWGPPSSD")
    }

    @Test func parseFasta() async throws {
        let fastaRecords = try await FastaParser().parseBundleFile("ecoli-k12-proteome")
        #expect(fastaRecords.count == 4392)

        let record = try #require(fastaRecords.first(where: { $0.accession == "P02919" }))
        #expect(record.shortName == "PBPB_ECOLI")
        #expect(record.fullName == "Penicillin-binding protein 1B")
        #expect(record.organism == "Escherichia coli (strain K12)")
        #expect(
            record.sequence
                == "MAGNDREPIGRKGKPTRPVKQKVSRRRYEDDDDYDDYDDYEDEEPMPRKGKGKGKGRKPRGKRGWLWLLLKLAIVFAVLIAIYGVYLDQKIRSRIDGKVWQLPAAVYGRMVNLEPDMTISKNEMVKLLEATQYRQVSKMTRPGEFTVQANSIEMIRRPFDFPDSKEGQVRARLTFDGDHLATIVNMENNRQFGFFRLDPRLITMISSPNGEQRLFVPRSGFPDLLVDTLLATEDRHFYEHDGISLYSIGRAVLANLTAGRTVQGASTLTQQLVKNLFLSSERSYWRKANEAYMALIMDARYSKDRILELYMNEVYLGQSGDNEIRGFPLASLYYFGRPVEELSLDQQALLVGMVKGASIYNPWRNPKLALERRNLVLRLLQQQQIIDQELYDMLSARPLGVQPRGGVISPQPAFMQLVRQELQAKLGDKVKDLSGVKIFTTFDSVAQDAAEKAAVEGIPALKKQRKLSDLETAIVVVDRFSGEVRAMVGGSEPQFAGYNRAMQARRSIGSLAKPATYLTALSQPKIYRLNTWIADAPIALRQPNGQVWSPQNDDRRYSESGRVMLVDALTRSMNVPTVNLGMALGLPAVTETWIKLGVPKDQLHPVPAMLLGALNLTPIEVAQAFQTIASGGNRAPLSALRSVIAEDGKVLYQSFPQAERAVPAQAAYLTLWTMQQVVQRGTGRQLGAKYPNLHLAGKTGTTNNNVDTWFAGIDGSTVTITWVGRDNNQPTKLYGASGAMSIYQRYLANQTPTPLNLVPPEDIADMGVDYDGNFVCSGGMRILPVWTSDPQSLCQQSEMQQQPSGNPFDQSSQPQQQPQQQPAQQEQKDSDGVAGWIKDMFGSN"
        )
    }

    @Test func subChain() throws {
        if let chain = testProtein.chains.first {
            let range1: Range<Int> = 2..<9
            let subChain1 = chain.subChain(range: range1)
            #expect(subChain1.sequenceString == "SSVSWGI")

            let range2: Range<Int> = 0..<10
            let subChain2 = chain.removing(range2)
            #expect(
                subChain2.sequenceString
                    == "LLAGLCCLVPVSLAEDPQGDAAQKTDTSHHDQDHPTFNKITPNLAEFAFSLYRQLAHQSNSTNIFFSPIVSIATAFAMLSLGTKADTHDEILEGLNFNLTEIPEAQIHEGFQELLRTLNQPDSQLQLTTGNGLFLSEGLKLVDKFLEDVKKLYHSEAFTVNFGDTEEAKKQINDYVEKGTQGKIVDLVKELDRDTVFALVNYIFFKGKWERPFEVKDTEEEDFHVDQVTTVKVPMMKRLGMFNIQHCKKLSSWVLLMKYLGNATAIFFLPDEGKLQHLENELTHDIITKFLENEDRRSASLHLPKLSITGTYDLKSVLGQLGITKVFSNGADLSGVTEEAPLKLSKAVHKAVLTIDEKGTEAAGAMFLEAIPMSIPPEVKFNKPFVFMIEQNTKSPLFMGKVVNPTQK"
            )

            let range3: Range<Int> = (10..<400)
            let subChain3 = chain.removing(range3)
            #expect(subChain3.sequenceString == "MPSSVSWGILQNTKSPLFMGKVVNPTQK")
        }
    }

    @Test func subSequence() throws {
        if let chain = testProtein.chains.first {
            #expect(chain.subSequence(range: 0..<1) == "M")
            #expect(chain.subSequence(range: 2..<9) == "SSVSWGI")
            #expect(chain.subSequence(range: -1..<2) == "MP")
            #expect(chain.subSequence(range: 0..<500) == chain.sequenceString)
        }
    }

    @Test func subChainWithModification() throws {
        let carboxymethylModifications = try modifications(
            unimodName: "Carboxymethyl",
            psiModAccession: "MOD:01061"
        )

        #expect(carboxymethylModifications.first?.fullName == "Iodoacetic acid derivative")

        for cysMod in carboxymethylModifications {
            var peptide = try Peptide(sequence: "SAMPLEVCAAAGQTHR")
            #expect(try peptide.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("1641.7836"))

            try peptide.addModification(cysMod, at: 8)
            #expect(try peptide.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("1699.7891"))

            let range = (2..<12)
            let subChain = peptide.subChain(range: range)
            #expect(subChain.sequenceString == "MPLEVCAAAG")
            #expect(subChain.modification(at: 6) == cysMod)
            #expect(try subChain.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("1019.4536"))
        }
    }

    @Test func emptySequence() throws {
        let peptide = try Peptide(sequence: "")
        #expect(peptide.masses == zeroMass)
    }

    @Test func emptySelection() throws {
        #expect(testProtein.selectionMass(zeroRange) == zeroMass)
    }

    @Test func selectionMassRangeMatchesSubChain() throws {
        let chain = try #require(testProtein.chains.first)
        let range = 10..<200

        let subChain = chain.subChain(range: range)
        #expect(testProtein.selectionMass(range) == subChain.masses)
    }

    @Test func chargedSelectionMassRangeMatchesSubChain() throws {
        let chain = try #require(testProtein.chains.first)
        let range = 10..<200
        let subChain = chain.subChain(range: range)

        #expect(testProtein.selectionMass(range).applying(adducts: [protonAdduct, protonAdduct])
            == subChain.masses.applying(adducts: [protonAdduct, protonAdduct]))
    }

    @Test func chargedSelectionAppliesAdductsOnce() throws {
        let protein = try Protein(sequence: "DWSSD")

        #expect(protein.selectionMass(0..<5).applying(adducts: [protonAdduct, protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("305.1112"))
    }

    @Test func selectionMassUsesActualAdducts() throws {
        let protein = try Protein(sequence: "DWSSD")
        let chain = try #require(protein.chains.first)

        let selectionMass = protein.selectionMass(0..<5).applying(adducts: [sodiumAdduct])
        let expectedMass = chain.masses.applying(adducts: [sodiumAdduct])
        let protonatedMass = chain.masses.applying(adducts: [protonAdduct])

        #expect(selectionMass == expectedMass)
        #expect(selectionMass != protonatedMass)
    }

    @Test func isoelectricPointPropertyUsesDefaultCalculation() throws {
        let chain = try #require(testProtein.chains.first)

        #expect(try chain.isoelectricPoint == chain.isoelectricPoint())
        #expect(try testProtein.isoelectricPoint == testProtein.isoelectricPoint())
    }

    @Test func isoelectricPointRangeMatchesSubChain() throws {
        let chain = try #require(testProtein.chains.first)
        let range = 10..<200

        #expect(try testProtein.isoelectricPoint(range: range) == chain.subChain(range: range).isoelectricPoint())
    }

    @Test func isoelectricPointClampsRangeToSequence() throws {
        let chain = try #require(testProtein.chains.first)

        #expect(
            try testProtein.isoelectricPoint(range: -1..<2)
                == chain.subChain(range: 0..<2).isoelectricPoint()
        )
        #expect(try Peptide(sequence: "").isoelectricPoint() == 0.0)
    }

    @Test func isoelectricPointSupportsTerminalIonization() throws {
        let alanine = try Peptide(sequence: "A")
        #expect(try abs(alanine.isoelectricPoint() - 5.925) < 0.01)

        let customTermini = try alanine.isoelectricPoint(
            nTerminalIonization: .custom(pKa: 6.0),
            cTerminalIonization: .custom(pKa: 8.0)
        )

        #expect(abs(customTermini - 7.0) < 0.01)

        let lysine = try Peptide(sequence: "K")
        let blockedNTerminal = try lysine.isoelectricPoint(nTerminalIonization: .blocked)
        #expect(abs(blockedNTerminal - 7.22) < 0.01)

        let asparticAcid = try Peptide(sequence: "D")
        let blockedCTerminal = try asparticAcid.isoelectricPoint(cTerminalIonization: .blocked)
        #expect(abs(blockedCTerminal - 6.055) < 0.01)
    }

    @Test func hydrophobicityProfileUsesCenteredWindows() throws {
        let peptide = try Peptide(sequence: "AVIL")
        let profile = try peptide.hydrophobicityProfile(for: .kyteDoolittle, windowSize: 3)

        #expect(profile.count == 2)
        let firstPoint = try #require(profile.first)
        let lastPoint = try #require(profile.last)
        #expect(firstPoint.position == 2.0)
        #expect(abs(firstPoint.value - 3.5) < 0.000_001)
        #expect(lastPoint.position == 3.0)
        #expect(abs(lastPoint.value - (12.5 / 3.0)) < 0.000_001)
    }

    @Test func hydrophobicityProfileRejectsInvalidInputs() throws {
        let peptide = try Peptide(sequence: "AVIL")

        #expect(throws: HydropathyError.invalidWindowSize(0, residueCount: 4)) {
            try peptide.hydrophobicityProfile(for: .kyteDoolittle, windowSize: 0)
        }
        #expect(throws: HydropathyError.invalidWindowSize(2, residueCount: 4)) {
            try peptide.hydrophobicityProfile(for: .kyteDoolittle, windowSize: 2)
        }
        #expect(throws: HydropathyError.invalidWindowSize(5, residueCount: 4)) {
            try peptide.hydrophobicityProfile(for: .kyteDoolittle, windowSize: 5)
        }
        #expect(throws: HydropathyError.scaleNotFound("Unknown")) {
            try peptide.hydrophobicityProfile(for: "Unknown")
        }
    }

    @Test func biomolecule() throws {
        let chain1 = ProteinChain(residues: [alanine, alanine, serine, alanine, serine])
        #expect(chain1.sequenceLength == 5)

        #expect(try chain1.ionized(with: [protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("406.1932"))
        let chain2 = ProteinChain(residues: chain1.residues + [serine, serine, alanine])
        #expect(chain2.sequenceLength == 8)

        #expect(try chain2.ionized(with: [protonAdduct, protonAdduct]).monoisotopicMass.rounded(scale: 4) == decimal("326.1508"))

        let protein = Protein(chains: [chain1, chain2])

        #expect(protein.sequence(chainIndex: 0) == "AASAS")
        #expect(protein.sequence(chainIndex: 1) == "AASASSSA")

        #expect(protein.aminoAcids.map {
            $0.oneLetterCode
        } == ["A", "A", "S", "A", "S"])
        #expect(
            protein.aminoAcids(chainIndex: 1).map {
                $0.oneLetterCode
            } == [
                "A", "A", "S", "A", "S", "S", "S", "A",
            ])

        let combinedMasses = chain1.masses + chain2.masses
        let expectedChargedMasses = combinedMasses.applying(adducts: [protonAdduct, protonAdduct])

        #expect(protein.masses == combinedMasses)
        #expect(try protein.ionized(with: [protonAdduct, protonAdduct]).masses == expectedChargedMasses)
    }

    @Test func crossLinkWithinOneChainContributesItsModificationOnce() throws {
        var protein = try Protein(sequence: "ACDC")
        let unlinkedFormula = protein.formula
        let unlinkedMasses = protein.masses

        let crossLink = try protein.addCrossLink(
            modification: disulfideBond,
            between: 1,
            and: 3)

        #expect(protein.crossLinks == [crossLink])
        #expect(protein.formula.elementCount(for: "H") == unlinkedFormula.elementCount(for: "H") - 2)
        #expect(protein.masses == unlinkedMasses + disulfideBond.masses)
    }

    @Test func crossLinkCanConnectDifferentProteinChainsAndRoundTripThroughCodable() throws {
        var protein = Protein(chains: [try ProteinChain(sequence: "AC"), try ProteinChain(sequence: "CA")])

        let crossLink = try protein.addCrossLink(
            modification: disulfideBond,
            between: 1,
            inChain: 0,
            and: 0,
            inChain: 1)

        #expect(crossLink.firstSite.chainID == protein.chains[0].id)
        #expect(crossLink.secondSite.chainID == protein.chains[1].id)
        #expect(protein.crossLinks(at: crossLink.firstSite) == [crossLink])

        let encoded = try JSONEncoder().encode(protein)
        let decoded = try JSONDecoder().decode(Protein.self, from: encoded)
        #expect(decoded == protein)
    }

}
