import Foundation

extension Syntax where A == (), M == String {
  /// Parses a single string literal from the front of the string, and prints that string literal.
  public static func lit(_ s: String) -> Syntax<(), String> {
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

  /// Parses all whitespace from the front of the string, and prints the preferred number of spaces.
  public static func ws(preferred: Int) -> Syntax<(), String> {
    return Syntax<(), String>.init(
      monoid: .joined,
      parse: { str in
        let trimIndex = str
          .firstIndex(where: { !$0.unicodeScalars.allSatisfy(CharacterSet.whitespaces.contains) })
          ?? str.endIndex
        str.removeSubrange(..<trimIndex)
        return ()
    },
      print: { _ in String(repeating: " ", count: preferred) }
    )
  }

  /// Parses all whitespace from the front of the string, and prints no whitespace.
  public static let skipWs = ws(preferred: 0)

  /// Parses all whitespace from the front of the string, and prints a single space.
  public static let optWs = ws(preferred: 1)
}

extension Syntax where A == String, M == String {
  /// Parses a string of a specified length off the front of the string, and prints that string.
  public static func string(length: Int) -> Syntax {
    return Syntax(
      monoid: .joined,
      parse: { str in
        guard length <= str.count else { return nil }
        let result = String(str[..<str.index(str.startIndex, offsetBy: length)])
        str.removeFirst(length)
        return result
    }, print: { .some($0) })
  }

  /// Parses a string from the front of the provided string until a predicate is satisfied.
  public static func string(until p: @escaping (Character) -> Bool) -> Syntax {
    return Syntax(
      monoid: .joined,
      parse: { str in
        let endIndex = str.firstIndex(where: p) ?? str.endIndex
        let result = String(str[..<endIndex])
        str.removeSubrange(..<endIndex)
        return result
    }, print: { .some($0) })
  }
}
