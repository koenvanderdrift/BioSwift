import XCTest

#if !os(macOS)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(BioSwiftTests.allTests),
        ]
    }
#endif
