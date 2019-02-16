import Foundation
import Monoid
import PartialIso
import Syntax

// Inspired by https://github.com/Flight-School/RegularExpressionDecoder
// Let's build a parser for stock prices that are stored in plain text.

// This is the data structure that we want to parse into and print from. For
// example, the string "AAPL 170.69▲0.51" would parse into the value
//
//   Stock{symbol: AAPL, price: 170.69, sign: .gain, .change: 0.51}
//
// and then that value would print back into the string "AAPL 170.69▲0.51".
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

// Some domain specific syntaxes for dealing with stocker symbol and sign.
let symbol = Syntax.string(until: { $0 == " " })
let sign: Syntax<Stock.Sign, String> = (Syntax.string(length: 1)).map(.rawRepresentable)

// A syntax for a single ticker line
let stockSyntax = (
  symbol <%> .optWs <%> .double <%> sign <%> .double
  )
  .flatten(
    Stock.init(symbol:price:sign:change:),
    { ($0.symbol, $0.price, $0.sign, $0.change) }
)

// Try running the syntax on a few sample stock strings.
stockSyntax.run("AAPL 170.69▲0.51")
stockSyntax.run("GOOG 1122.57▲2.41")
stockSyntax.run("AMZN 1621.48▼18.52")
stockSyntax.run("MSFT 106.57=0.00")

// Try printing a strock string from a Stock value.
stockSyntax.print(Stock(symbol: "FB", price: 100, sign: .loss, change: 90))

// A syntax for a full ticker by combining multiple stock syntaxes separated by newlines.
let tickerSyntax = Syntax.many(stockSyntax, separatedBy: .lit("\n"))

// Parse an entire ticker stream.
tickerSyntax.parse("""
AAPL 170.69▲0.51
GOOG 1122.57▲2.41
AMZN 1621.48▼18.52
MSFT 106.57=0.00
""")

// Parse and then print the ticker stream to make sure we get the same thing back.
print(
  tickerSyntax.print(
    tickerSyntax.parse("""
    AAPL 170.69▲0.51
    GOOG 1122.57▲2.41
    AMZN 1621.48▼18.52
    MSFT 106.57=0.00
    """)!
    )!
)

