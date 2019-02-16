import Foundation
import PartialIso
import Syntax
import Monoid

// Inspired by https://github.com/Flight-School/RegularExpressionDecoder
// Let's build a parser for stock prices that are stored in plain text.

struct Stock {
  let symbol: String
  let price: Double
  let sign: Sign
  let change: Double

  enum Sign: String, CaseIterable {
    case gain = "▲"
    case unchanged = "="
    case loss = "▼"
  }
}

extension Syntax where A == String, M == String {
  static let symbol = Syntax<String, String>(
    monoid: .joined,
    parse: { str in
      guard let spaceIndex = str.firstIndex(where: { $0 == " " }) else { return nil }
      let result = String(str[..<spaceIndex])
      str.removeFirst(spaceIndex.encodedOffset)
      return result
  }, print: { .some($0) })
}
extension Syntax where A == (), M == String {
  static func lit(_ s: String) -> Syntax<(), String> {
    return Syntax<(), String>.init(
      monoid: .joined,
      parse: { str in
        let hasPrefix = str.hasPrefix(s)
        if str.count >= s.count { str.removeFirst(s.count) }
        return hasPrefix ? () : nil
    },
      print: { _ in s }
    )
  }
}
extension Syntax where A == Int, M == String {
  static let int = Syntax<Int, String>.init(
    monoid: .joined,
    parse: { str in
      let prefix = str.prefix(while: { ("0"..."9").contains($0) })
      str.removeFirst(prefix.count)
      return Int(String(prefix))
  },
    print: { "\($0)" }
  )
}

extension Syntax where A == Double, M == String {
  static let double = Syntax<Double, String>.init(
    monoid: .joined,
    parse: { str in
      let prefix = str.prefix(while: { ("0"..."9").contains($0) || $0 == "." })
      str.removeFirst(prefix.count)
      return Double(String(prefix))
  },
    print: { "\($0)" }
  )
}

extension Syntax where A == (), M == String {

  static let skipWs = ws(preferred: 0)
  static let optWs = ws(preferred: 1)

  static func ws(preferred: Int) -> Syntax<(), String> {
    return Syntax<(), String>.init(
      monoid: .joined,
      parse: { str in
        str = str.trimmingCharacters(in: .whitespaces)
        return ()
    },
      print: { _ in String.init(repeating: " ", count: preferred) }
    )
  }
}

extension Syntax where A == String, M == String {
  static func string(length: Int) -> Syntax {
    return Syntax(
      monoid: .joined,
      parse: { str in
        let result = String(str[..<str.index(str.startIndex, offsetBy: length)])
        str.removeFirst(length)
        return result
    }, print: { .some($0) })
  }
}

let sign: Syntax<Stock.Sign, String> = (Syntax.string(length: 1)).map(.rawRepresentable)

let stockSyntax = (
  .symbol <%> .optWs <%> .double <%> sign <%> .double
  )
  .flatten()
  .map(Stock.init, { ($0.symbol, $0.price, $0.sign, $0.change) })

let tickerSyntax = many(stockSyntax, .lit("\n"))

stockSyntax.run("AAPL 170.69▲0.51")
stockSyntax.run("GOOG 1122.57▲2.41")
stockSyntax.run("AMZN 1621.48▼18.52")
stockSyntax.run("MSFT 106.57=0.00")

stockSyntax.print(Stock(symbol: "FB", price: 100, sign: .loss, change: 90))

tickerSyntax.parse("""
AAPL 170.69▲0.51
GOOG 1122.57▲2.41
AMZN 1621.48▼18.52
MSFT 106.57=0.00
""")

