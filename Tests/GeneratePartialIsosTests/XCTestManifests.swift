import XCTest

extension GeneratePartialIsosTests {
  static let __allTests = [
    ("test", test),
  ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
  return [
    testCase(GeneratePartialIsosTests.__allTests),
  ]
}
#endif
