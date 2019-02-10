import XCTest
@testable import Syntax
import PartialIso

final class swift_parser_printerTests: XCTestCase {

  func testExample() {
    let int = Syntax<Int, [String]>(
      monoid: .joined,
      parse: { tokens in
        tokens.count == 0 ? nil : Int(tokens.removeFirst())
    },
      print: { int in [String(int)] }
    )

    let string = Syntax<String, [String]>(
      monoid: .joined,
      parse: { tokens in
        tokens.count == 0 ? nil : tokens.removeFirst()
    },
      print: { str in [str] }
    )

    let bool = Syntax<Bool, [String]>(
      monoid: .joined,
      parse: { tokens in
        tokens.count == 0 ? nil : Bool(tokens.removeFirst())
    },
      print: { bool in [String(describing: bool)] }
    )

    let comma = Syntax<(), [String]>(
      monoid: .joined,
      parse: { tokens in
        tokens.count == 0 ? nil :
          tokens.removeFirst() == "," ? () : nil
    },
      print: { _ in [","] }
    )

    struct User {
      let id: Int
      let name: String
      let admin: Bool
    }

    let syntax = (int <%> comma <%> string <%> comma <%> bool)
      .flatten()
      .map(User.init, { ($0.id, $0.name, $0.admin) })

    let parsed = syntax.parseCsv("123,Hello,true")
    let printed = syntax.printCsv(User(id: 1, name: "Hello", admin: true))
    print(parsed as Any)
    print(printed as Any)
    print("!")
  }

  func testUser_Operators() {
    let idSyntax = lit("id:") <%> ws1 <%> int <%> lit(",") <%> ws1
    let nameSyntax = lit("name:") <%> ws1 <%> quotedString <%> lit(",") <%> ws1
    let isAdminSyntax = lit("isAdmin:") <%> ws1 <%> bool
    let _userSyntax = lit("User(")
      <%> idSyntax
      <%> nameSyntax
      <%> isAdminSyntax
      <%> lit(")")
    let userSyntax = _userSyntax.flatten()

    print(userSyntax.print((123, "Blob", true))!)
    print(userSyntax.parse("User(id:123,name:\"Blob\",isAdmin:true)")!)
  }

  func testUser_NoOperators() {
    let idSyntax = field(name: "id", syntax: int)
      .process(discarding: lit(","))
      .process(discarding: ws1)
    let nameSyntax = field(name: "name", syntax: quotedString)
      .process(discarding: lit(","))
      .process(discarding: ws1)
    let isAdminSyntax = field(name: "isAdmin", syntax: bool)
    let userModelSyntax = lit("User(")
      .discard(processing: idSyntax)
      .process(and: nameSyntax)
      .process(and: isAdminSyntax)
      .process(discarding: lit(")"))
      .flatten()

    XCTAssertEqual(
      "User(id: 123, name: \"Blob\", isAdmin: true)",
      userModelSyntax.print((123, "Blob", true))!
    )

    XCTAssertEqual3(
      (123, "Blob", true),
      userModelSyntax.parse("User(id:123,name:\"Blob\",isAdmin:true)")!
    )
  }
}

extension Syntax {
  func flatten<B, C, D>() -> Syntax<(B, C, D), M> where A == ((B, C), D) {
    return self.map(leftFlatten, leftParanthesize)
  }
}

func XCTAssertEqual3<A: Equatable, B: Equatable, C: Equatable>(
  _ value: (A, B, C),
  _ expected: (A, B, C),
  file: StaticString = #file,
  line: UInt = #line
  ) {

  XCTAssertTrue(
    value == expected,
    "\(value) is not equal to the expected \(expected)",
    file: file,
    line: line
  )
}

extension Syntax where M == [String] {
  func parseCsv(_ a: String) -> A? {
    return self.parse(
      Array(a
        .split(separator: ",")
        .map { [String($0)] }
        .joined(separator: [","]))
    )
  }

  func printCsv(_ a: A) -> String? {
    return self.print(a)?.joined()
  }
}

func field<A>(name: String, syntax: Syntax<A, String>) -> Syntax<A, String> {
  return lit("\(name):")
    .discard(processing: ws1)
    .discard(processing: syntax)
}

func lit(_ s: String) -> Syntax<(), String> {
  return Syntax<(), String>.init(
    monoid: .joined,
    parse: { str in
      let hasPrefix = str.hasPrefix(s)
      str.removeFirst(s.count)
      return hasPrefix ? () : nil
  },
    print: { _ in s }
  )
}

let ws0 = ws(preferred: 0)
let ws1 = ws(preferred: 1)
func ws(preferred: Int) -> Syntax<(), String> {
  return Syntax<(), String>.init(
    monoid: .joined,
    parse: { str in
      str = str.trimmingCharacters(in: .whitespaces)
      return ()
  },
    print: { _ in String.init(repeating: " ", count: preferred) }
  )
}

let int = Syntax<Int, String>.init(
  monoid: .joined,
  parse: { str in
    let prefix = str.prefix(while: { (48...57).contains($0.unicodeScalars.first!.value) })
    str.removeFirst(prefix.count)
    return Int(String(prefix))
},
  print: { "\($0)" }
)
let quotedString = Syntax<String, String>.init(
  monoid: .joined,
  parse: { str in
    let parts = str.split(separator: "\"", maxSplits: 2)
    let (parsed, rest) = (parts.first, parts.last)
    str = rest.map(String.init) ?? ""
    return parsed.map(String.init)
},
  print: { str in "\"\(str)\"" }
)
let bool = Syntax<Bool, String>.init(
  monoid: .joined,
  parse: { str in

    if str.hasPrefix("true") {
      str.removeFirst(4)
      return true
    } else if str.hasPrefix("false") {
      str.removeFirst(5)
      return false
    }

    return nil
},
  print: { "\($0)" }
)
