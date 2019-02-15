import XCTest

extension swift_parser_printerTests {
    static let __allTests = [
        ("testAdventDay1", testAdventDay1),
        ("testExample", testExample),
        ("testUser_NoOperators", testUser_NoOperators),
        ("testUser_Operators", testUser_Operators),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(swift_parser_printerTests.__allTests),
    ]
}
#endif
