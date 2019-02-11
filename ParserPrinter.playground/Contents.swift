import Foundation
import PartialIso
import Syntax
import URLRequestRouter

struct User: Codable {
  let email: String
  let password: String
}

enum Route {
  case home
  case episode(Int)
  case search(String)
  case signUp(User)
}

extension PartialIso where A == Void, B == Route {
  static let home = PartialIso(
    apply: { Route.home },
    unapply: {
      guard case .home = $0 else { return nil }
      return ()
  }
  )
}

extension PartialIso where A == Int, B == Route {
  static let episode = PartialIso(
    apply: Route.episode,
    unapply: {
      guard case let .episode(value) = $0 else { return nil }
      return value
  }
  )
}

extension PartialIso where A == String, B == Route {
  static let search = PartialIso(
    apply: Route.search,
    unapply: {
      guard case let .search(value) = $0 else { return nil }
      return value
  }
  )
}

extension PartialIso where A == User, B == Route {
  static let signUp = PartialIso(
    apply: Route.signUp,
    unapply: {
      guard case let .signUp(value) = $0 else { return nil }
      return value
  }
  )
}

let router = Router<Route>(
  .match(.home, to: .get),
  .match(.episode, to: .get </> "episodes" </> .int),
  .match(.search, to: .get </> "search" <?> ("q", .string)),
  .match(.signUp, to: .post(.json) </> "sign-up")
)

router.parse(.init(method: .get, path: [], query: [("ga", "1")], body: nil))
router.parse(.init(method: .get, path: ["episodes", "1"], query: [("ga", "1")], body: nil))
router.parse(.init(method: .get, path: ["search"], query: [("ga", "1"), ("q", "point-free")], body: nil))
router.parse(.init(method: .post, path: ["sign-up"], query: [], body: Data("""
{"email":"support@pointfree.co","password":"blob8108"}
""".utf8)))
