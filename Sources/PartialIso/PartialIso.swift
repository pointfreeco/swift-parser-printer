import Foundation

public struct PartialIso<A, B> {
  public let apply: (A) -> B?
  public let unapply: (B) -> A?

  public init(apply: @escaping (A) -> B?, unapply: @escaping (B) -> A?) {
    self.apply = apply
    self.unapply = unapply
  }

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

  public static func pipe<C>(_ lhs: PartialIso<A, B>, _ rhs: PartialIso<B, C>) -> PartialIso<A, C> {
    return PartialIso<A, C>(
      apply: { a in
        lhs.apply(a).flatMap(rhs.apply)
    },
      unapply: { c in
        rhs.unapply(c).flatMap(lhs.unapply)
    })
  }

  public static func compose<C>(_ lhs: PartialIso<B, C>, _ rhs: PartialIso<A, B>) -> PartialIso<A, C> {
    return PartialIso<A, C>(
      apply: { a in
        rhs.apply(a).flatMap(lhs.apply)
    },
      unapply: { c in
        lhs.unapply(c).flatMap(rhs.unapply)
    })
  }
}

extension PartialIso where B == A {
  /// The identity partial isomorphism.
  public static var id: PartialIso {
    return .init(apply: { $0 }, unapply: { $0 })
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

public func leftParanthesize<A, B, C>(_ tuple: (A, B, C)) -> ((A, B), C) {
  return ((tuple.0, tuple.1), tuple.2)
}

extension PartialIso where A == Void, B: Equatable {
  public static func const(_ b: B) -> PartialIso {
    return PartialIso(
      apply: { .some(b) },
      unapply: { b == $0 ? () : nil }
    )
  }
}

extension PartialIso where A == String, B == String {

  public static let string = id

}

extension PartialIso where A == String, B == Int {

  public static let int = PartialIso(apply: Int.init, unapply: String.init)

}

extension PartialIso where A == String, B == Double {

  public static let float = PartialIso(apply: Double.init, unapply: String.init)

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
