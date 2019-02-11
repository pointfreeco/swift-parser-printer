import Syntax
import PartialIso
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

typealias Router<A> = Syntax<A, RequestData>

extension Syntax where M == RequestData {
  public static func route<A0>(_ f: PartialIso<A0, A>, to syntax: Syntax<A0, M>) -> Syntax {
    return (syntax <% .end).map(f)
  }
}

extension PartialIso where A == Void {
  public static func const(_ b: B) -> PartialIso {
    return PartialIso(
      apply: { .some(b) },
      unapply: { _ in () }
    )
  }
}

extension Syntax where M == RequestData {
  public typealias ArrayLiteralElement = Syntax

  public init(_ elements: Syntax...) {
    self = elements.reduce(into: .init(.requestData)) { $0 = $0.or($1) }
  }
}

let router = Router<Route>(
  .route(.home, to: .get),
  .route(.episode, to: .get </> "episodes" </> .int),
  .route(.search, to: .get </> "search" <?> ("q", .string)),
  .route(.signUp, to: .post(.json) </> "sign-up")
)

//let route: Syntax =
//  .get </> "hello" </> "world" </> .int <?> ("x", .int) <% .end
//
//route.parse(.init(method: .get, path: ["hello", "world", "1"], query: [("x", "1")], body: nil))

