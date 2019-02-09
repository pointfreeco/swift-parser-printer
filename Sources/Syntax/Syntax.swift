import Monoid
import PartialIso

precedencegroup SyntaxOperator {
  associativity: right
}
infix operator <%>: SyntaxOperator
infix operator %>: SyntaxOperator
infix operator <%: SyntaxOperator

public struct Syntax<A, M: Equatable> {
  let monoid: Monoid<M>
  let _parse: (M) -> (M, A)?
  let _print: (A) -> M?

  func parse(_ m: M) -> A? {
    guard case let .some((m, a)) = self._parse(m) else { return nil }
    guard m == self.monoid.empty else { return nil }
    return a
  }

  func print(_ a: A) -> M? {
    return self._print(a)
  }

  func map<B>(
    _ f: @escaping (A) -> B?,
    _ g: @escaping (B) -> A?
    ) -> Syntax<B, M> {

    return Syntax<B, M>(
      monoid: self.monoid,
      _parse: { m in
        guard let (rest, match) = self._parse(m) else { return nil }
        return f(match).map { (rest, $0) }
    },
      _print: { b in
      g(b).flatMap(self._print)
    })
  }

  func map<B>(_ iso: PartialIso<A, B>) -> Syntax<B, M> {
    return self.map(iso.apply, iso.unapply)
  }

  static func <%><B>(_ lhs: Syntax<A, M>, _ rhs: Syntax<B, M>) -> Syntax<(A, B), M> {
    return Syntax<(A, B), M>(
      monoid: lhs.monoid,
      _parse: { m in
        guard let (more, a) = lhs._parse(m) else { return nil }
        guard let (rest, b) = rhs._parse(more) else { return nil }
        return (rest, (a, b))
    },
      _print: { a, b in
        let lhsPrint = lhs._print(a)
        let rhsPrint = rhs._print(b)
        return _zip(lhsPrint, rhsPrint)
          .map(lhs.monoid.combine)
          ?? lhsPrint
          ?? rhsPrint
    })
  }

  static func <%>(_ lhs: Syntax<(), M>, _ rhs: Syntax<A, M>) -> Syntax<A, M> {
    return Syntax<A, M>(
      monoid: lhs.monoid,
      _parse: { m in
        guard let (more, a) = lhs._parse(m) else { return nil }
        guard let (rest, b) = rhs._parse(more) else { return nil }
        return (rest, b)
    },
      _print: { a in
        let lhsPrint = lhs._print(())
        let rhsPrint = rhs._print(a)
        return _zip(lhsPrint, rhsPrint)
          .map(lhs.monoid.combine)
          ?? lhsPrint
          ?? rhsPrint
    })
  }

  static func or(_ lhs: Syntax, _ rhs: Syntax) -> Syntax {
    return Syntax(
      monoid: lhs.monoid,
      _parse: { a in lhs._parse(a) ?? rhs._parse(a) },
      _print: { m in lhs._print(m) ?? rhs._print(m) }
    )
  }
}

private func _zip<A, B>(_ a: A?, _ b: B?) -> (A, B)? {
  guard let a = a, let b = b else { return nil }
  return (a, b)
}

extension Syntax {
  init(_ monoid: Monoid<M>) {
    self = Syntax.init(
      monoid: monoid,
      _parse: { _ in nil },
      _print: { _ in nil }
    )
  }
}
