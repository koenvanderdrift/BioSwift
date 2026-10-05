//
//  BioSwiftDiagnostics.swift
//  BioSwift
//

import OSLog
import Synchronization

/// Package-wide diagnostic logging for BioSwift.
public enum BioSwiftDiagnostics {
    private static let logger = Logger(subsystem: "com.koenvanderdrift.BioSwift", category: "Diagnostics")
    private static let state = Mutex(State())

    private struct State: Sendable {
        var isDebugLoggingEnabled = false
        var observer: (@Sendable (Level, String) -> Void)?
    }

    enum Level: Equatable, Sendable {
        case debug
        case error
    }

    /// Controls verbose diagnostic messages. Error logging is always enabled.
    public static var isDebugLoggingEnabled: Bool {
        get { state.withLock { $0.isDebugLoggingEnabled } }
        set { state.withLock { $0.isDebugLoggingEnabled = newValue } }
    }

    /// Logs a lazily evaluated diagnostic message when debug logging is enabled.
    public static func log(_ message: @autoclosure () -> Any) {
        let (isEnabled, observer) = state.withLock { state in
            (state.isDebugLoggingEnabled, state.observer)
        }

        guard isEnabled else { return }

        let description = String(describing: message())
        logger.debug("\(description, privacy: .public)")
        observer?(.debug, description)
    }

    /// Logs an error at the error level. The error remains available to its caller.
    public static func log(_ error: any Error) {
        let description = String(describing: error)
        logger.error("\(description, privacy: .public)")
        let observer = state.withLock { $0.observer }
        observer?(.error, description)
    }

    static func logged<E: Error>(_ error: E) -> E {
        log(error)
        return error
    }

    static func setObserver(_ observer: (@Sendable (Level, String) -> Void)?) {
        state.withLock { $0.observer = observer }
    }
}
