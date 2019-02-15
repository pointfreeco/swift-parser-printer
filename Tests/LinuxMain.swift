import XCTest

import GeneratePartialIsosTests
import PartialIsoTests
import URLRequestRouterTests
import SyntaxTests

var tests = [XCTestCaseEntry]()
tests += GeneratePartialIsosTests.__allTests()
tests += PartialIsoTests.__allTests()
tests += URLRequestRouterTests.__allTests()
tests += SyntaxTests.__allTests()

XCTMain(tests)
