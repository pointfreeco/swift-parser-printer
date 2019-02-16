import Foundation

public struct PartialIso<A, B> {
  public let apply: (A) -> B?
  public let unapply: (B) -> A?

  public init(apply: @escaping (A) -> B?, unapply: @escaping (B) -> A?) {
    self.apply = apply
    self.unapply = unapply
  }
}

extension PartialIso {
  /// Inverts the partial isomorphism.
  public var inverted: PartialIso<B, A> {
    return .init(apply: self.unapply, unapply: self.apply)
  }

  /// A partial isomorphism between `(A, B)` and `(B, A)`.
  public static var commute: PartialIso<(A, B), (B, A)> {
    return .init(
      apply: { ($1, $0) },
      unapply: { ($1, $0) }
    )
  }

  public static func pipe<AB>(_ lhs: PartialIso<A, AB>, _ rhs: PartialIso<AB, B>) -> PartialIso {
    return PartialIso(
      apply: { a in
        lhs.apply(a).flatMap(rhs.apply)
    },
      unapply: { c in
        rhs.unapply(c).flatMap(lhs.unapply)
    })
  }

  public static func compose<AB>(_ lhs: PartialIso<AB, B>, _ rhs: PartialIso<A, AB>) -> PartialIso {
    return PartialIso(
      apply: { a in
        rhs.apply(a).flatMap(lhs.apply)
    },
      unapply: { c in
        lhs.unapply(c).flatMap(rhs.unapply)
    })
  }

  public static func ?? (lhs: PartialIso, rhs: PartialIso) -> PartialIso {
    return PartialIso(
      apply: { return lhs.apply($0) ?? rhs.apply($0) },
      unapply: { return rhs.unapply($0) ?? lhs.unapply($0) }
    )
  }
}

extension PartialIso where B == A? {
  public static var some: PartialIso {
    return PartialIso(
      apply: Optional.some,
      unapply: { $0 }
    )
  }
}

extension PartialIso {
  public static func optional<A0, B0>(_ iso: PartialIso<A0, B0>) -> PartialIso where A == A0?, B == B0? {
    return PartialIso(
      apply: { .some($0.flatMap(iso.apply)) },
      unapply: { .some($0.flatMap(iso.unapply)) }
    )
  }

  public static func require<A0>(_ iso: PartialIso<A0, B>) -> PartialIso where A == A0? {
    return PartialIso(
      apply: { $0.flatMap(iso.apply) },
      unapply: iso.unapply
    )
  }
}

extension PartialIso where A == B {
  /// The identity partial isomorphism.
  public static var id: PartialIso {
    return .init(apply: { $0 }, unapply: { $0 })
  }
}

extension PartialIso {
  public static func const(_ b: B) -> PartialIso {
    return PartialIso(
      apply: { _ in b },
      unapply: { _ in nil }
    )
  }
}

extension PartialIso where B == (A, ()) {
  /// An isomorphism between `A` and `(A, Unit)`.
  public static var unit: PartialIso {
    return .init(
      apply: { ($0, ()) },
      unapply: { $0.0 }
    )
  }
}

public func leftFlatten<A, B, C>(_ tuple: ((A, B), C)) -> (A, B, C) {
  return (tuple.0.0, tuple.0.1, tuple.1)
}

public func leftParenthesize<A, B, C>(_ tuple: (A, B, C)) -> ((A, B), C) {
  return ((tuple.0, tuple.1), tuple.2)
}

extension PartialIso where A == String, B == String {
  public static let string = id
}

extension PartialIso where A == String, B: LosslessStringConvertible {
  public static var losslessStringConvertible: PartialIso {
    return PartialIso(
      apply: B.init,
      unapply: String.init
    )
  }
}

extension PartialIso where B: RawRepresentable, B.RawValue == A {
  public static var rawRepresentable: PartialIso {
    return PartialIso(
      apply: B.init(rawValue:),
      unapply: { $0.rawValue }
    )
  }
}

extension PartialIso where A == String, B == Bool {
  public static let bool = losslessStringConvertible
}

extension PartialIso where A == String, B == Int {
  public static let int = losslessStringConvertible
}

extension PartialIso where A == String, B == Int64 {
  public static let int64 = losslessStringConvertible
}

extension PartialIso where A == String, B == Int32 {
  public static let int32 = losslessStringConvertible
}

extension PartialIso where A == String, B == Int16 {
  public static let int16 = losslessStringConvertible
}

extension PartialIso where A == String, B == Int8 {
  public static let int32 = losslessStringConvertible
}

extension PartialIso where A == String, B == UInt64 {
  public static let uint64 = losslessStringConvertible
}

extension PartialIso where A == String, B == UInt32 {
  public static let uint32 = losslessStringConvertible
}

extension PartialIso where A == String, B == UInt16 {
  public static let uint16 = losslessStringConvertible
}

extension PartialIso where A == String, B == UInt8 {
  public static let uint32 = losslessStringConvertible
}

extension PartialIso where A == String, B == Double {
  public static let double = losslessStringConvertible
}

extension PartialIso where A == String, B == Float {
  public static let float = losslessStringConvertible
}

extension PartialIso where A == String, B == Float80 {
  public static let float80 = losslessStringConvertible
}

extension PartialIso where A == String, B == UUID {
  public static var uuid: PartialIso<String, UUID> {
    return PartialIso(
      apply: UUID.init(uuidString:),
      unapply: { $0.uuidString }
    )
  }
}

extension PartialIso where A == Data, B: Codable {
  public static func json(_ type: B.Type, decoder: JSONDecoder = .init(), encoder: JSONEncoder = .init()) -> PartialIso {
    return PartialIso(
      apply: { try? decoder.decode(B.self, from: $0) },
      unapply: { try? encoder.encode($0) }
    )
  }

  public static var json: PartialIso {
    return self.json(B.self)
  }
}

extension PartialIso {
  public static func filter<A>(_ isIncluded: @escaping (A) -> Bool) -> PartialIso<[A], [A]> {
    return PartialIso<[A], [A]>(
      apply: { $0.filter(isIncluded) },
      unapply: { $0 }
    )
  }

  public static func first<A>(where predicate: @escaping (A) -> Bool) -> PartialIso<[A], A> {
    return PartialIso<[A], A>(
      apply: { $0.first(where: predicate) },
      unapply: { [$0] }
    )
  }

  public static func key<K, V>(_ key: K) -> PartialIso<[K: V], V> {
    return PartialIso<[K: V], V>(
      apply: { $0[key] },
      unapply: { [key: $0] }
    )
  }
}

extension PartialIso where A == String, B == Data {
  public static func data(_ encoding: String.Encoding) -> PartialIso {
    return PartialIso(
      apply: { $0.data(using: encoding) },
      unapply: { String(data: $0, encoding: encoding) }
    )
  }
}

extension PartialIso where A == String, B == String {
  public static func percentEncoding(withAllowedCharacters characters: CharacterSet) -> PartialIso {
    return PartialIso(
      apply: { $0.addingPercentEncoding(withAllowedCharacters: characters) },
      unapply: { $0.removingPercentEncoding }
    )
  }
}
