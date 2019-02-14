import XCTest
import GeneratePartialIsos
import SwiftSyntax

final class GeneratePartialIsosTests: XCTestCase {
  func test() throws {
    let visitor = Visitor()

    let parsed = try SyntaxTreeParser.parse(
      URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixture.swift")
    )

    visitor.visit(parsed)
    XCTAssertEqual(
"""
extension PartialIso where A == Void, B == Routes {
  static let home = PartialIso(
    apply: { .home },
    unapply: {
      guard case .home = $0 else { return nil }
      return ()
  }
  )
}
extension PartialIso where A == Int, B == Routes {
  static let episode = PartialIso(
    apply: Routes.episode,
    unapply: {
      guard case let .episode(value) = $0 else { return nil }
      return value
  }
  )
}
extension PartialIso where A == (username: String, password: String), B == Routes {
  static let login = PartialIso(
    apply: Routes.login,
    unapply: {
      guard case let .login(value) = $0 else { return nil }
      return value
  }
  )
}

""",
      visitor.out
    )
  }
}

