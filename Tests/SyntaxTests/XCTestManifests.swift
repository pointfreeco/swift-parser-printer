import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(swift_parser_printerTests.allTests),
    ]
}
#endif