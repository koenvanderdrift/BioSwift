import Foundation
import Synchronization
import Testing

@testable import BioSwift

@Suite(.serialized)
struct BioSwiftDiagnosticsTests {
    private enum TestError: Error {
        case example
    }

    @Test func debugMessagesAreLazyWhenDisabled() throws {
        let previousValue = BioSwiftDiagnostics.isDebugLoggingEnabled
        defer { BioSwiftDiagnostics.isDebugLoggingEnabled = previousValue }

        BioSwiftDiagnostics.isDebugLoggingEnabled = false
        var wasEvaluated = false

        func message() -> String {
            wasEvaluated = true
            return "message"
        }

        BioSwiftDiagnostics.log(message())

        #expect(wasEvaluated == false)
    }

    @Test func concreteAndExistentialErrorsUseErrorLevel() throws {
        let previousValue = BioSwiftDiagnostics.isDebugLoggingEnabled
        let levels = Mutex<[BioSwiftDiagnostics.Level]>([])
        BioSwiftDiagnostics.setObserver { level, message in
            if message == "example" {
                levels.withLock { $0.append(level) }
            }
        }
        defer {
            BioSwiftDiagnostics.setObserver(nil)
            BioSwiftDiagnostics.isDebugLoggingEnabled = previousValue
        }

        let concrete = TestError.example
        let existential: any Error = TestError.example

        BioSwiftDiagnostics.log(concrete)
        BioSwiftDiagnostics.log(existential)

        #expect(levels.withLock { $0 } == [.error, .error])
    }

    @Test func valueErasedToAnyUsesDebugLevel() throws {
        let previousValue = BioSwiftDiagnostics.isDebugLoggingEnabled
        let levels = Mutex<[BioSwiftDiagnostics.Level]>([])
        BioSwiftDiagnostics.setObserver { level, message in
            if message == "example" {
                levels.withLock { $0.append(level) }
            }
        }
        defer {
            BioSwiftDiagnostics.setObserver(nil)
            BioSwiftDiagnostics.isDebugLoggingEnabled = previousValue
        }

        BioSwiftDiagnostics.isDebugLoggingEnabled = true
        let erased: Any = TestError.example

        BioSwiftDiagnostics.log(erased)

        #expect(levels.withLock { $0 } == [.debug])
    }

    @Test func ionValidationErrorsUseErrorLevel() throws {
        let diagnostics = Mutex<[(BioSwiftDiagnostics.Level, String)]>([])
        BioSwiftDiagnostics.setObserver { level, message in
            diagnostics.withLock { $0.append((level, message)) }
        }
        defer { BioSwiftDiagnostics.setObserver(nil) }

        #expect(throws: IonError.noAdducts) {
            try water.ionized(with: [])
        }
        #expect(throws: IonError.zeroCharge) {
            try water.ionized(with: [protonAdduct, negativeProtonAdduct])
        }

        let recorded = diagnostics.withLock { $0 }
        #expect(recorded.map(\.0) == [.error, .error])
        #expect(recorded.map(\.1) == ["noAdducts", "zeroCharge"])
    }

    @Test func glycanErrorsUseErrorLevel() throws {
        let diagnostics = Mutex<[(BioSwiftDiagnostics.Level, String)]>([])
        BioSwiftDiagnostics.setObserver { level, message in
            diagnostics.withLock { $0.append((level, message)) }
        }
        defer { BioSwiftDiagnostics.setObserver(nil) }

        #expect(throws: GlycanError.emptyMonosaccharideSequence) {
            try Glycan(monosaccharides: [], linkages: [])
        }
        #expect(throws: GlycanError.invalidGlycosidicPosition(0)) {
            try GlycosidicPosition(0)
        }

        let recorded = diagnostics.withLock { $0 }
        #expect(recorded.map(\.0) == [.error, .error])
        #expect(recorded.map(\.1) == [
            "emptyMonosaccharideSequence",
            "invalidGlycosidicPosition(0)",
        ])
    }

    @Test func customDecoderFailuresUseErrorLevel() throws {
        let diagnostics = Mutex<[(BioSwiftDiagnostics.Level, String)]>([])
        BioSwiftDiagnostics.setObserver { level, message in
            diagnostics.withLock { $0.append((level, message)) }
        }
        defer { BioSwiftDiagnostics.setObserver(nil) }

        let data = Data("{}".utf8)
        let decoder = JSONDecoder()
        let decodeFailures: [() throws -> Void] = [
            { _ = try decoder.decode(Adduct.self, from: data) },
            { _ = try decoder.decode(CleaveRestriction.self, from: data) },
            { _ = try decoder.decode(ChemicalElement.self, from: data) },
            { _ = try decoder.decode(DNA.self, from: data) },
            { _ = try decoder.decode(Formula.self, from: data) },
        ]

        for decode in decodeFailures {
            do {
                try decode()
                Issue.record("Expected decoding to fail")
            } catch {
                #expect(error is DecodingError)
            }
        }

        let recorded = diagnostics.withLock { $0 }
        #expect(recorded.count == decodeFailures.count)
        #expect(recorded.allSatisfy { $0.0 == .error })
    }

    @Test func nestedDecoderFailureIsLoggedOnce() throws {
        let diagnostics = Mutex<[(BioSwiftDiagnostics.Level, String)]>([])
        BioSwiftDiagnostics.setObserver { level, message in
            diagnostics.withLock { $0.append((level, message)) }
        }
        defer { BioSwiftDiagnostics.setObserver(nil) }

        var payload = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(Monosaccharide.galactose))
                as? [String: Any]
        )
        var formula = try #require(payload["formula"] as? [String: Any])
        formula["inputString"] = "not a formula"
        payload["formula"] = formula

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                Monosaccharide.self,
                from: JSONSerialization.data(withJSONObject: payload)
            )
        }

        let recorded = diagnostics.withLock { $0 }
        #expect(recorded.count == 1)
        #expect(recorded.first?.0 == .error)
    }
}
