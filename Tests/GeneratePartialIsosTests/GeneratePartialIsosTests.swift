import XCTest
import GeneratePartialIsos
import SnapshotTesting
import SwiftSyntax

extension Snapshotting where Value == URL, Format == String {
  public static var visitor: Snapshotting {
    var strategy: Snapshotting = SimplySnapshotting.lines.pullback {
      let visitor = Visitor()
      visitor.visit(try! SyntaxTreeParser.parse($0))
      return visitor.out
    }
    strategy.pathExtension = "swift"
    return strategy
  }
}

final class GeneratePartialIsosTests: XCTestCase {
  func test() throws {
    assertSnapshot(
      matching: URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixture.swift"),
      as: .visitor
    )
  }
}

