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

/// Converts a partial isomorphism of a flat 1-tuple to one of a right-weighted nested tuple.
public func parenthesize<A, B>(_ f: PartialIso<A, B>) -> PartialIso<A, B> {
  return f
}

/// Converts a partial isomorphism of a flat 2-tuple to one of a right-weighted nested tuple.
public func parenthesize<A, B, C>(_ f: PartialIso<(A, B), C>) -> PartialIso<(A, B), C> {
  return f
}

///// Converts a partial isomorphism of a flat 3-tuple to one of a right-weighted nested tuple.
//public func parenthesize<A, B, C, D>(_ f: PartialIso<(A, B, C), D>) -> PartialIso<(A, (B, C)), D> {
//  return flatten() >>> f
//}
//
///// Converts a partial isomorphism of a flat 4-tuple to one of a right-weighted nested tuple.
//public func parenthesize<A, B, C, D, E>(_ f: PartialIso<(A, B, C ,D), E>) -> PartialIso<(A, (B, (C, D))), E> {
//  return flatten() >>> f
//}
//
//// TODO: should we just bite the bullet and create our own `TupleN` types and stop using Swift tuples
//// altogether?
//
///// Flattens a right-weighted nested 3-tuple.
//private func flatten<A, B, C>() -> PartialIso<(A, (B, C)), (A, B, C)> {
//  return .init(
//    apply: { ($0.0, $0.1.0, $0.1.1) },
//    unapply: { ($0, ($1, $2)) }
//  )
//}
//
///// Flattens a left-weighted nested 4-tuple.
//private func flatten<A, B, C, D>() -> PartialIso<(A, (B, (C, D))), (A, B, C, D)> {
//  return .init(
//    apply: { ($0.0, $0.1.0, $0.1.1.0, $0.1.1.1) },
//    unapply: { ($0, ($1, ($2, $3))) }
//  )
//}
