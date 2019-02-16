extension Syntax where A == Int, M == String {
  public static let int = Syntax<Int, String>.init(
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
  public static let double = Syntax<Double, String>.init(
    monoid: .joined,
    parse: { str in
      let prefix = str.prefix(while: { ("0"..."9").contains($0) || $0 == "." })
      str.removeFirst(prefix.count)
      return Double(String(prefix))
  },
    print: { "\($0)" }
  )
}
