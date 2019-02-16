import XCTest

extension URLRequestRouterTests {
    static let __allTests = [
        ("test", test),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(URLRequestRouterTests.__allTests),
    ]
}
#endif
