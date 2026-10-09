import Foundation
import Testing

@testable import BioSwift

@Suite struct GlycanTests {
    private let galactose = Monosaccharide.galactose.form(anomer: .beta, ring: .pyranose)
    private let glucose = Monosaccharide.glucose.form(anomer: .unspecified, ring: .pyranose)

    @Test func singleMonosaccharideGlycan() {
        let glycan = Glycan(monosaccharide: glucose)
        #expect(glycan.monosaccharideCount == 1)
        #expect(glycan.nonReducingEnd == glucose)
        #expect(glycan.reducingEnd == glucose)
        #expect(glycan.linkages.isEmpty)
        #expect(glycan.formula == glucose.formula)
        #expect(glycan.description == "Glcp")
    }

    @Test func lactoseUsesConventionalOrientationAndNotation() throws {
        let linkage = try GlycosidicLinkage(donorPosition: 1, acceptorPosition: 4)
        let lactose = try Glycan(
            monosaccharides: [galactose, glucose],
            linkages: [linkage],
            name: "Lactose"
        )
        #expect(lactose.nonReducingEnd == galactose)
        #expect(lactose.reducingEnd == glucose)
        #expect(lactose.description == "Galp(β1→4)Glcp")
        #expect(lactose.connections.first?.donor == galactose)
        #expect(lactose.connections.first?.acceptor == glucose)
        #expect(lactose.formula.formulaString == "C12H22O11")
        #expect(lactose.monoisotopicMass.rounded(scale: 6) == decimal("342.116212"))
        #expect(lactose.nominalMass == 342)
    }

    @Test func constructionAtBothEndsPreservesTheSource() throws {
        let alphaGlucose = Monosaccharide.glucose.form(anomer: .alpha, ring: .pyranose)
        let oneToFour = try GlycosidicLinkage(donorPosition: 1, acceptorPosition: 4)
        let glucoseOnly = Glycan(monosaccharide: glucose)
        let maltose = try glucoseOnly.prependingAtNonReducingEnd(
            alphaGlucose,
            linkage: oneToFour
        )
        let maltotriose = try maltose.prependingAtNonReducingEnd(
            alphaGlucose,
            linkage: oneToFour
        )
        #expect(glucoseOnly.monosaccharideCount == 1)
        #expect(maltose.description == "Glcp(α1→4)Glcp")
        #expect(maltotriose.monosaccharideCount == 3)
        #expect(maltotriose.linkages.count == 2)
        #expect(maltotriose.formula.formulaString == "C18H32O16")
        #expect(maltotriose.monoisotopicMass.rounded(scale: 6) == decimal("504.169035"))
        #expect(maltotriose.nominalMass == 504)
    }

    @Test func trisaccharideUsesLinkagesInNonReducingToReducingOrder() throws {
        let alphaGlucose = Monosaccharide.glucose.form(anomer: .alpha, ring: .pyranose)
        let reducingGlucose = Monosaccharide.glucose.form(
            anomer: .unspecified,
            ring: .pyranose
        )
        let firstLinkage = try GlycosidicLinkage(donorPosition: 1, acceptorPosition: 4)
        let secondLinkage = try GlycosidicLinkage(donorPosition: 1, acceptorPosition: 4)

        let maltotriose = try Glycan(
            monosaccharides: [alphaGlucose, alphaGlucose, reducingGlucose],
            linkages: [firstLinkage, secondLinkage],
            name: "Maltotriose"
        )

        #expect(maltotriose.connections[0].donor == maltotriose.monosaccharides[0])
        #expect(maltotriose.connections[0].acceptor == maltotriose.monosaccharides[1])
        #expect(maltotriose.connections[0].linkage == firstLinkage)
        #expect(maltotriose.connections[1].donor == maltotriose.monosaccharides[1])
        #expect(maltotriose.connections[1].acceptor == maltotriose.monosaccharides[2])
        #expect(maltotriose.connections[1].linkage == secondLinkage)
        #expect(maltotriose.nonReducingEnd == alphaGlucose)
        #expect(maltotriose.reducingEnd == reducingGlucose)
        #expect(maltotriose.description == "Glcp(α1→4)Glcp(α1→4)Glcp")
        #expect(maltotriose.formula.formulaString == "C18H32O16")
        #expect(maltotriose.monoisotopicMass.rounded(scale: 6) == decimal("504.169035"))
        #expect(maltotriose.nominalMass == 504)
    }

    @Test func compositionCountsDistinctMonosaccharides() throws {
        let lactose = try Glycan(
            monosaccharides: [galactose, glucose],
            linkages: [try GlycosidicLinkage(donorPosition: 1, acceptorPosition: 4)]
        )
        #expect(lactose.composition[galactose] == 1)
        #expect(lactose.composition[glucose] == 1)
    }

    @Test func rootedGlycanSupportsBranches() throws {
        let coreMannose = Monosaccharide.mannose.form(
            anomer: .beta,
            ring: .pyranose
        )
        let branchMannose = Monosaccharide.mannose.form(
            anomer: .alpha,
            ring: .pyranose
        )
        var glycan = Glycan(monosaccharide: coreMannose, name: "Branched mannose")

        let alphaOneToThree = try GlycosidicLinkage(
            donorPosition: 1,
            acceptorPosition: 3
        )
        let alphaOneToSix = try GlycosidicLinkage(
            donorPosition: 1,
            acceptorPosition: 6
        )

        let firstBranchID = try glycan.add(
            branchMannose,
            to: glycan.root.id,
            linkage: alphaOneToThree
        )
        let secondBranchID = try glycan.add(
            branchMannose,
            to: glycan.root.id,
            linkage: alphaOneToSix
        )

        #expect(glycan.root.branches.count == 2)
        #expect(glycan.node(id: firstBranchID)?.monosaccharide == branchMannose)
        #expect(glycan.node(id: secondBranchID)?.monosaccharide == branchMannose)
        #expect(glycan.nonReducingEnds.count == 2)
        #expect(glycan.monosaccharideCount == 3)
        #expect(glycan.description == "Manp(α1→3)[Manp(α1→6)]Manp")
        #expect(glycan.formula.formulaString == "C18H32O16")
        #expect(glycan.monoisotopicMass.rounded(scale: 6) == decimal("504.169035"))

        let encoded = try JSONEncoder().encode(glycan)
        let decoded = try JSONDecoder().decode(Glycan.self, from: encoded)
        #expect(decoded == glycan)
    }

    @Test func branchedGlycanProvidesIUPACNotations() throws {
        let reducingMannose = Monosaccharide.mannose.form(
            anomer: .unspecified,
            ring: .pyranose
        )
        let alphaMannose = Monosaccharide.mannose.form(
            anomer: .alpha,
            ring: .pyranose
        )
        var glycan = Glycan(monosaccharide: reducingMannose)

        // Add these in reverse display order to verify canonical branch ordering.
        try glycan.add(
            alphaMannose,
            to: glycan.root.id,
            linkage: GlycosidicLinkage(donorPosition: 1, acceptorPosition: 6)
        )
        try glycan.add(
            alphaMannose,
            to: glycan.root.id,
            linkage: GlycosidicLinkage(donorPosition: 1, acceptorPosition: 3)
        )

        #expect(glycan.iupacCondensed == "Man(a1-3)[Man(a1-6)]Man")
        #expect(glycan.iupacExtended == "α-D-Manp-(1→3)-[α-D-Manp-(1→6)]-D-Manp")
    }

    @Test func linearGlycanProvidesIUPACNotations() throws {
        let lactose = try Glycan(
            monosaccharides: [galactose, glucose],
            linkages: [GlycosidicLinkage(donorPosition: 1, acceptorPosition: 4)]
        )

        #expect(lactose.iupacCondensed == "Gal(b1-4)Glc")
        #expect(lactose.iupacExtended == "β-D-Galp-(1→4)-D-Glcp")
    }

    @Test func parsesCondensedIUPACWithBranches() throws {
        let glycan = try GlycanIUPACParser().parse("Man(a1-3)[Man(a1-6)]Man")

        #expect(glycan.monosaccharideCount == 3)
        #expect(glycan.root.branches.count == 2)
        #expect(glycan.iupacCondensed == "Man(a1-3)[Man(a1-6)]Man")
        #expect(glycan.iupacExtended == "α-D-Manp-(1→3)-[α-D-Manp-(1→6)]-D-Manp")
    }

    @Test func parsesExtendedIUPACAndRoundTrips() throws {
        let notation = "β-D-Galp-(1→4)-D-Glcp"
        let glycan = try GlycanIUPACParser().parse(notation, name: "Lactose")

        #expect(glycan.name == "Lactose")
        #expect(glycan.iupacExtended == notation)
        #expect(glycan.iupacCondensed == "Gal(b1-4)Glc")
        #expect(glycan.formula.formulaString == "C12H22O11")
    }

    @Test func parserAcceptsTextAnomersAndASCIIArrows() throws {
        let glycan = try GlycanIUPACParser().parse("beta-D-Galp-(1->4)-D-Glcp")

        #expect(glycan.iupacExtended == "β-D-Galp-(1→4)-D-Glcp")
    }

    @Test func parserReportsUnknownResiduesAndMalformedBranches() {
        #expect(throws: GlycanIUPACParserError.self) {
            try GlycanIUPACParser().parse("Foo(a1-3)Man")
        }
        #expect(throws: GlycanIUPACParserError.self) {
            try GlycanIUPACParser().parse("Man(a1-3)[Man(a1-6)Man")
        }
    }

    @Test func rootedGlycanRejectsConflictingBranchesAndMissingParents() throws {
        let mannose = Monosaccharide.mannose.form(anomer: .alpha, ring: .pyranose)
        let linkage = try GlycosidicLinkage(donorPosition: 1, acceptorPosition: 3)
        var glycan = Glycan(monosaccharide: glucose)
        try glycan.add(mannose, to: glycan.root.id, linkage: linkage)

        #expect(
            throws: GlycanError.acceptorPositionOccupied(
                nodeID: glycan.root.id,
                position: try GlycosidicPosition(3)
            )
        ) {
            try glycan.add(mannose, to: glycan.root.id, linkage: linkage)
        }

        let missingID = UUID()
        #expect(throws: GlycanError.nodeNotFound(missingID)) {
            try glycan.add(mannose, to: missingID, linkage: linkage)
        }
    }

    @Test func constructionValidatesSequenceAndLinkageCounts() {
        #expect(throws: GlycanError.emptyMonosaccharideSequence) {
            try Glycan(monosaccharides: [], linkages: [])
        }
        #expect(throws: GlycanError.invalidLinkageCount(expected: 1, actual: 0)) {
            try Glycan(monosaccharides: [galactose, glucose], linkages: [])
        }
        #expect(throws: GlycanError.invalidGlycosidicPosition(0)) {
            try GlycosidicPosition(0)
        }
    }

    @Test func codableRoundTripAndDecodeValidation() throws {
        let lactose = try Glycan(
            monosaccharides: [galactose, glucose],
            linkages: [try GlycosidicLinkage(donorPosition: 1, acceptorPosition: 4)],
            name: "Lactose"
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Glycan.self, from: encoder.encode(lactose))
        #expect(decoded == lactose)

        let invalidJSON = """
        {"name":"Invalid","monosaccharides":[],"linkages":[]}
        """.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try decoder.decode(Glycan.self, from: invalidJSON)
        }
    }
}
