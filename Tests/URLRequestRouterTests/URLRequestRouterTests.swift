import XCTest
import Syntax
import PartialIso
import URLRequestRouter

final class URLRequestRouterTests: XCTestCase {

  func test() {
    let route = .get </> "users" </> .int <?> ("ref", require(.string)) <%> .end

    XCTAssertEqual(
      RequestData(method: .get, path: ["users", "42"], query: [("ref", "pointfreeco")], body: nil),
      route.print((42, "pointfreeco"))
    )
    XCTAssertEqual(
      "users/42?ref=pointfreeco",
      route.urlString(for: ((42, "pointfreeco")))
    )

    let tuple = route.parse(RequestData(method: .get, path: ["users", "42"], query: [("ref", "pointfreeco")], body: nil))
    XCTAssertEqual(42, tuple?.0)
    XCTAssertEqual("pointfreeco", tuple?.1)
  }

  func testOptionalRouteParam() {
    let route = .get </> "search" <?> ("q", .optional(.string))

    XCTAssertEqual(
      "search",
      route.urlString(for: nil)
    )
    XCTAssertEqual(
      "search?q=blob",
      route.urlString(for: "blob")
    )

    XCTAssertEqual(
      .some(.none),
      route.match(urlString: "/search?q")
    )
    XCTAssertEqual(
      .some(.none),
      route.match(urlString: "/search?")
    )
    XCTAssertEqual(
      .some(.none),
      route.match(urlString: "/search")
    )
    XCTAssertEqual(
      .some("blob"),
      route.match(urlString: "/search?q=blob")
    )
    XCTAssertEqual(
      .none,
      route.match(urlString: "/searchxyz")
    )
  }

  func testRequiredRouteParam() {
    let route = .get </> "search" <?> ("q", require(.string))

    XCTAssertEqual(
      "search?q=blob",
      route.urlString(for: "blob")
    )

    XCTAssertEqual(
      .none,
      route.match(urlString: "/search?q")
    )
    XCTAssertEqual(
      .none,
      route.match(urlString: "/search?")
    )
    XCTAssertEqual(
      .none,
      route.match(urlString: "/search")
    )
    XCTAssertEqual(
      .some("blob"),
      route.match(urlString: "/search?q=blob")
    )
    XCTAssertEqual(
      .none,
      route.match(urlString: "/searchxyz")
    )
  }
}
