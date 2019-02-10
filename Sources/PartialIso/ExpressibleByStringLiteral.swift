extension PartialIso: ExpressibleByUnicodeScalarLiteral where A == String, B == () {
  public init(unicodeScalarLiteral value: String) {
    self = PartialIso<String, ()>.init(
      apply: { str in str == value ? () : nil },
      unapply: { _ in value }
    )
  }

  public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType
}


extension PartialIso: ExpressibleByExtendedGraphemeClusterLiteral where A == String, B == () {
  public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType

  public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
    let value = String(value)
    self = PartialIso<String, ()>.init(
      apply: { str in str == value ? () : nil },
      unapply: { _ in value }
    )
  }
}

extension PartialIso: ExpressibleByStringLiteral where A == String, B == () {
  public typealias StringLiteralType = String

  public init(stringLiteral value: String) {
    self = PartialIso<String, ()>.init(
      apply: { str in str == value ? () : nil },
      unapply: { _ in value }
    )
  }
}
