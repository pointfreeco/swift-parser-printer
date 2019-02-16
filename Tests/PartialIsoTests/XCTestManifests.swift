import XCTest

extension PartialIsoTests {
    static let __allTests = [
        ("testExpressibleByStringLiteral", testExpressibleByStringLiteral),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PartialIsoTests.__allTests),
    ]
}
#endif
