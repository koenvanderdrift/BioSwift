import Foundation
import Testing
@testable import BioSwiftNetworking

@Suite("NCBI BLAST support")
struct NCBIBLASTSupportTests {
    @Test("The default policy follows NCBI's minimum polling interval")
    func defaultPolicy() {
        let policy = NCBIBLASTPollingPolicy.ncbiDefault

        #expect(policy.interval == .seconds(60))
        #expect(policy.maximumAttempts == 30)
    }

    @Test("Polling policies accept longer intervals and positive attempt limits")
    func customPolicy() throws {
        let policy = try NCBIBLASTPollingPolicy(
            interval: .seconds(90),
            maximumAttempts: 12
        )

        #expect(policy.interval == .seconds(90))
        #expect(policy.maximumAttempts == 12)
    }

    @Test("Polling policies reject intervals shorter than one minute")
    func shortInterval() {
        #expect(throws: NCBIBLASTError.pollingIntervalTooShort(.seconds(59))) {
            try NCBIBLASTPollingPolicy(interval: .seconds(59))
        }
    }

    @Test("Polling policies require at least one attempt")
    func invalidAttemptLimit() {
        #expect(throws: NCBIBLASTError.invalidMaximumPollingAttempts(0)) {
            try NCBIBLASTPollingPolicy(maximumAttempts: 0)
        }
    }

    @Test("Polling support values are Sendable")
    func sendable() {
        requireSendable(NCBIBLASTPollingPolicy.ncbiDefault)
        requireSendable(ContinuousBLASTPollingSleeper())
        requireSendable(NCBIBLASTError.pollingTimedOut)
        requireSendable(NCBIBLASTStatus.waiting)
        requireSendable(NCBIBLASTEvent.submitted(
            requestIdentifier: "RID",
            estimatedCompletionTime: .seconds(10)
        ))
    }

    private func requireSendable<Value: Sendable>(_: Value) {}
}
