import Monoid
import PartialIso

public struct Syntax<A, M> {
  let monoid: Monoid<M>
  let parse: (M) -> (M, A)?
  let print: (A) -> M?

  func map<B>(
    _ f: @escaping (A) -> B?,
    _ g: @escaping (B) -> A?
    ) -> Syntax<B, M> {

    return Syntax<B, M>(
      monoid: self.monoid,
      parse: { m in
        guard let (rest, match) = self.parse(m) else { return nil }
        return f(match).map { (rest, $0) }

    }, print: { b in
      g(b).flatMap(self.print)
    })
  }

  static func zip<B>(_ lhs: Syntax<A, M>, _ rhs: Syntax<B, M>) -> Syntax<(A, B), M> {
    return Syntax<(A, B), M>(
      monoid: lhs.monoid,
      parse: { m in
        _zip(lhs.parse(m), rhs.parse(m))
          .map { ma, mb in
            (lhs.monoid.combine(ma.0, mb.0), (ma.1, mb.1))
        }
    },
      print: { a, b in
        let lhsPrint = lhs.print(a)
        let rhsPrint = rhs.print(b)
        return _zip(lhsPrint, rhsPrint)
          .map(lhs.monoid.combine)
          ?? lhsPrint
          ?? rhsPrint
    })
  }

  static func or(_ lhs: Syntax, _ rhs: Syntax) -> Syntax {
    return Syntax(
      monoid: lhs.monoid,
      parse: { a in lhs.parse(a) ?? rhs.parse(a) },
      print: { m in lhs.print(m) ?? rhs.print(m) }
    )
  }
}

private func _zip<A, B>(_ a: A?, _ b: B?) -> (A, B)? {
  guard let a = a, let b = b else { return nil }
  return (a, b)
}
