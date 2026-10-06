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
}
