import Testing
import BioSwift

@Suite struct AminoAcidModificationValidatorTests {
    @Test func attachmentRulesRequireExplicitMatchingLocations() {
        let sideChain = modification(.init(site: "K", attachmentPositions: ["Amino acid side chain."]))
        let backbone = modification(.init(site: "K", attachmentPositions: ["Amino acid backbone."]))
        #expect(AminoAcidModificationValidator.validate(sideChain, in: .init(residue: "K", attachment: .sideChain)) == .allowed)
        #expect(AminoAcidModificationValidator.validate(backbone, in: .init(residue: "K", attachment: .backbone)) == .allowed)
        #expect(AminoAcidModificationValidator.validate(sideChain, in: .init(residue: "K", attachment: .backbone)) != .allowed)
        #expect(AminoAcidModificationValidator.validate(backbone, in: .init(residue: "K", attachment: .sideChain)) != .allowed)
        #expect(AminoAcidModificationValidator.validate(sideChain, in: .init(residue: "K")) != .allowed)
        #expect(AminoAcidModificationValidator.validate(backbone, in: .init(residue: "K")) != .allowed)
        #expect(AminoAcidModificationValidator.validate(sideChain, in: .init(residue: "M", attachment: .sideChain)) != .allowed)
    }

    @Test func attachmentRulesDoNotOverrideTerminalRestrictions() {
        let mod = modification(.init(site: "K", position: "Protein N-term", attachmentPositions: ["Amino acid backbone."]))
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(residue: "K", attachment: .backbone)) != .allowed)
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(
            residue: "K", attachment: .nTerminus, isNTerminal: true, isProteinNTerminal: false
        )) != .allowed)
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(
            residue: "K", attachment: .nTerminus, isNTerminal: true, isProteinNTerminal: true
        )) == .allowed)
    }

    @Test func unsupportedAndConflictingAttachmentRulesAreRejected() {
        for rules in [
            ["Unknown"],
            ["Amino acid side chain-Amino acid backbone."],
            ["Amino acid side chain.", "Amino acid backbone."]
        ] {
            let mod = modification(.init(site: "K", attachmentPositions: rules))
            #expect(AminoAcidModificationValidator.validate(mod, in: .init(residue: "K", attachment: .sideChain)) != .allowed)
        }
    }

    @Test func bundledUniProtSideChainRuleCanBeValidated() throws {
        let mod = try #require(ReferenceLibrary.uniProtPTM.modification(accession: "PTM-0369"))
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(residue: "N", attachment: .sideChain)) == .allowed)
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(residue: "N", attachment: .backbone)) != .allowed)
    }

    private func modification(_ rules: ModificationSpecificity...) -> Modification {
        Modification(name: "Same name", reactions: [], specificities: rules)
    }

    @Test func proteinNTerminusRequiresOriginalTerminus() {
        let mod = modification(.init(site: "K", position: "Protein N-term"))
        let internalResult = AminoAcidModificationValidator.validate(mod, in: .init(residue: "K"))
        #expect(internalResult == .rejected(reasons: ["Requires the protein's N-terminus."]))
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(
            residue: "K", isNTerminal: true, isProteinNTerminal: false
        )) == internalResult)
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(
            residue: "K", isNTerminal: true
        )) == .rejected(reasons: ["The protein N-terminal context is unknown."]))
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(
            residue: "K", isNTerminal: true, isProteinNTerminal: true
        )) == .allowed)
    }

    @Test func alternativeRulesMustMatchAsCompleteRules() {
        let mod = modification(
            .init(site: "K", position: "Protein N-term"), .init(site: "M")
        )
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(residue: "K")) != .allowed)
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(residue: "M")) == .allowed)
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(
            residue: "S", isNTerminal: true, isProteinNTerminal: true
        )) != .allowed)
    }

    @Test func terminalGroupsAndResidueAttachmentsDiffer() {
        let mod = modification(.init(site: "N-term"))
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(
            residue: "K", isNTerminal: true
        )) != .allowed)
        #expect(AminoAcidModificationValidator.validate(mod, in: .init(
            residue: "K", attachment: .nTerminus, isNTerminal: true
        )) == .allowed)
        #expect(AminoAcidModificationValidator.validate(
            modification(.init(site: "K")), in: .init(
                residue: "K", attachment: .nTerminus, isNTerminal: true
            )
        ) != .allowed)
    }

    @Test func peptideAndProteinCTermini() {
        let context = AminoAcidModificationContext(
            residue: "K", attachment: .cTerminus, isCTerminal: true,
            isProteinCTerminal: false
        )
        #expect(AminoAcidModificationValidator.validate(
            modification(.init(site: "C-term", position: "Any C-term")), in: context
        ) == .allowed)
        #expect(AminoAcidModificationValidator.validate(
            modification(.init(site: "C-term", position: "Protein C-term")), in: context
        ) != .allowed)
        #expect(AminoAcidModificationValidator.validate(
            modification(.init(site: "K", position: "Protein C-term")), in: .init(
                residue: "K", isCTerminal: true, isProteinCTerminal: true
            )
        ) == .allowed)
    }

    @Test func missingAndUnknownRulesAreNotPermission() {
        let context = AminoAcidModificationContext(residue: "K")
        #expect(AminoAcidModificationValidator.validate(modification(), in: context)
            == .rejected(reasons: ["No attachment rules are available."]))
        #expect(AminoAcidModificationValidator.validate(
            modification(.init(site: "K", position: "Unknown")), in: context
        ) == .rejected(reasons: ["Unsupported position rule: Unknown."]))
        #expect(AminoAcidModificationValidator.validate(
            modification(.init(site: "X")), in: context
        ) == .allowed)
    }

    @Test func inconsistentContextIsRejected() {
        let mod = modification(.init(site: "X"))
        for context in [
            AminoAcidModificationContext(residue: ""),
            .init(residue: "Lys"),
            .init(residue: "K", attachment: .nTerminus),
            .init(residue: "K", isProteinNTerminal: true)
        ] {
            #expect(AminoAcidModificationValidator.validate(mod, in: context) != .allowed)
        }
    }

    @Test(arguments: ["N-term", "C-term"])
    func terminalPositionAliasesPreserveConstraints(position: String) {
        let isN = position == "N-term"
        let matching: AminoAcidModificationContext.Attachment = isN ? .nTerminus : .cTerminus
        let opposite: AminoAcidModificationContext.Attachment = isN ? .cTerminus : .nTerminus
        for spelling in [position, "Any " + position] {
            let mod = modification(.init(site: "K", position: spelling))
            #expect(AminoAcidModificationValidator.validate(mod, in: .init(residue: "K")) != .allowed)
            #expect(AminoAcidModificationValidator.validate(mod, in: .init(
                residue: "K", isNTerminal: isN, isCTerminal: !isN
            )) == .allowed)
            #expect(AminoAcidModificationValidator.validate(mod, in: .init(
                residue: "K", isNTerminal: !isN, isCTerminal: isN
            )) != .allowed)
            #expect(AminoAcidModificationValidator.validate(mod, in: .init(
                residue: "K", attachment: matching, isNTerminal: isN, isCTerminal: !isN
            )) == .allowed)
            #expect(AminoAcidModificationValidator.validate(mod, in: .init(
                residue: "K", attachment: opposite, isNTerminal: !isN, isCTerminal: isN
            )) != .allowed)
            #expect(AminoAcidModificationValidator.validate(mod, in: .init(
                residue: "K", attachment: matching, isNTerminal: true, isCTerminal: true
            )) == .allowed)
            #expect(AminoAcidModificationValidator.validate(mod, in: .init(
                residue: "K", attachment: opposite, isNTerminal: true, isCTerminal: true
            )) != .allowed)
            #expect(AminoAcidModificationValidator.validate(mod, in: .init(
                residue: "M", attachment: matching, isNTerminal: true, isCTerminal: true
            )) != .allowed)
        }
    }

    @Test func singleResiduePeptideStillHasDistinctTerminalGroups() {
        #expect(AminoAcidModificationValidator.validate(
            modification(.init(site: "K", position: "Any N-term")), in: .init(
                residue: "K", attachment: .cTerminus,
                isNTerminal: true, isCTerminal: true
            )
        ) != .allowed)
    }
}
