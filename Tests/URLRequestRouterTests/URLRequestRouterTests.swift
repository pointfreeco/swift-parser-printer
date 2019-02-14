import XCTest
@testable import Syntax
import PartialIso
import URLRequestRouter

//infix operator <>

final class URLRequestRouterTests: XCTestCase {

  func test() {
    let route = .get </> "users" </> .int <?> ("ref", .string) <%> .end

    XCTAssertEqual(
      RequestData(method: .get, path: ["users", "42"], query: [("ref", "pointfreeco")], body: nil),
      route.print((42, "pointfreeco"))
    )

    let tuple = route.parse(RequestData(method: .get, path: ["users", "42"], query: [("ref", "pointfreeco")], body: nil))
    XCTAssertEqual(42, tuple?.0)
    XCTAssertEqual("pointfreeco", tuple?.1)
  }

  func testOptionalRouteParam() {
    let route = .get </> "search" <?> ("q", optional(.string))

//    XCTAssertEqual(
//      RequestData(method: .get, path: ["search"], query: [], body: nil),
//      route.print(<#T##a: String?##String?#>)
//    )
  }
}
