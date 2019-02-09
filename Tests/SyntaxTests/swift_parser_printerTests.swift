import XCTest
@testable import Syntax
import PartialIso

final class swift_parser_printerTests: XCTestCase {

  func testExample() {
    let intSyntax = Syntax<Int, String>(
      monoid: .joined(separator: ","),
      _parse: { str in Int(str).map { ("", $0) } },
      _print: { int in String(int) }
    )

    let stringSyntax = Syntax<String, String>(
      monoid: .joined(separator: ","),
      _parse: { str in ("", str) },
      _print: { str in str }
    )

    let boolSyntax = Syntax<Bool, String>(
      monoid: .joined(separator: ","),
      _parse: { str in str == "true" ? ("", true) : str == "false" ? ("", false) : nil },
      _print: { bool in String(describing: bool) }
    )

    let commaSyntax = Syntax<(), String>(
      monoid: .joined(separator: ","),
      _parse: { str in str == "," ? ("", ()) : nil },
      _print: { _ in "," }
    )

    let tmp = intSyntax <%> commaSyntax <%> stringSyntax <%> commaSyntax <%> boolSyntax

    let tmp2 = tmp.map(flatten, rightParanthesize)

    let parsed = tmp2.parse("123,Hello,true")
    let printed = tmp2.print((1, "Hello", true))

    print("!")
  }
}
