import XCTest
import PartialIso

final class PartialIsoTests: XCTestCase {
  func testExpressibleByStringLiteral() {
    let partialIso: PartialIso<String, ()> = "foo"

    XCTAssertNotNil(partialIso.apply("foo"))
    XCTAssertNil(partialIso.apply("bar"))
    XCTAssertEqual("foo", partialIso.unapply(()))
  }

  func testOptionalRequired() {
    let pi1 = require(.string)
    XCTAssertEqual(nil, pi1.apply(nil))
    XCTAssertEqual("blob", pi1.apply("blob"))
    XCTAssertEqual(Optional.some(.some("blob")), pi1.unapply("blob"))

    let pi2 = optional(.string)
    XCTAssertEqual(Optional.some(.none), pi2.apply(nil))
    XCTAssertEqual(Optional.some(.some("blob")), pi2.apply("blob"))
    XCTAssertEqual(Optional.some(.none), pi2.unapply(nil))
    XCTAssertEqual(Optional.some(.some("blob")), pi2.unapply("blob"))
  }
}
