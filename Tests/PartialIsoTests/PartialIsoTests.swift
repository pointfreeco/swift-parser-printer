import XCTest
import PartialIso

final class PartialIsoTests: XCTestCase {
  func testExpressibleByStringLiteral() {
    let partialIso: PartialIso<String, ()> = "foo"

    XCTAssertNotNil(partialIso.apply("foo"))
    XCTAssertNil(partialIso.apply("bar"))
    XCTAssertEqual("foo", partialIso.unapply(()))
  }
}
