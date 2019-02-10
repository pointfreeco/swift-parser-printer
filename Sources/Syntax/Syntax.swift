import Monoid
import PartialIso

precedencegroup SyntaxOperator {
  associativity: left
}
infix operator <%>: SyntaxOperator
infix operator %>: SyntaxOperator
infix operator <%: SyntaxOperator

public struct Syntax<A, M: Equatable> {
  let monoid: Monoid<M>
  let _parse: (inout M) -> A?
  let _print: (A) -> M?

  public init(monoid: Monoid<M>, parse: @escaping (inout M) -> A?, print: @escaping (A) -> M?) {
    self.monoid = monoid
    self._parse = parse
    self._print = print
  }

  func parse(_ m: M) -> A? {
    var m = m
    let possibleMatch = self._parse(&m)
    guard let match = possibleMatch else { return nil }
    guard m == self.monoid.empty else { return nil }
    return match
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
      parse: { m in
        let possibleMatch = self._parse(&m)
        guard let match = possibleMatch else { return nil }
        return f(match)
    },
      print: { b in
      g(b).flatMap(self._print)
    })
  }

  func map<B>(_ iso: PartialIso<A, B>) -> Syntax<B, M> {
    return self.map(iso.apply, iso.unapply)
  }

  func process<B>(and other: Syntax<B, M>) -> Syntax<(A, B), M> {
    return self <%> other
  }
  static func <%><B>(_ lhs: Syntax<A, M>, _ rhs: Syntax<B, M>) -> Syntax<(A, B), M> {
    return Syntax<(A, B), M>(
      monoid: lhs.monoid,
      parse: { m in
        guard let a = lhs._parse(&m) else { return nil }
        guard let b = rhs._parse(&m) else { return nil }
        return (a, b)
    },
      print: { a, b in
        let lhsPrint = lhs._print(a)
        let rhsPrint = rhs._print(b)
        return Optional.zip(lhsPrint, rhsPrint)
          .map(lhs.monoid.combine)
        // TODO: are these needed?
//          ?? lhsPrint
//          ?? rhsPrint
    })
  }

  static func <%>(_ lhs: Syntax<A, M>, _ rhs: Syntax<(), M>) -> Syntax<A, M> {
    return Syntax<A, M>(
      monoid: lhs.monoid,
      parse: { m in
        guard let a = lhs._parse(&m) else { return nil }
        guard let _ = rhs._parse(&m) else { return nil }
        return a
    },
      print: { a in
        let lhsPrint = lhs._print(a)
        let rhsPrint = rhs._print(())
        return Optional.zip(lhsPrint, rhsPrint)
          .map(lhs.monoid.combine)
        // TODO: are these needed?
        //          ?? lhsPrint
        //          ?? rhsPrint
    })
  }

  func process(discarding: Syntax<(), M>) -> Syntax<A, M> {
    return self <% discarding
  }
  static func <%(_ lhs: Syntax<A, M>, _ rhs: Syntax<(), M>) -> Syntax<A, M> {
    return Syntax<A, M>(
      monoid: lhs.monoid,
      parse: { m in
        guard let a = lhs._parse(&m) else { return nil }
        guard let _ = rhs._parse(&m) else { return nil }
        return a
    },
      print: { a in
        let lhsPrint = lhs._print(a)
        let rhsPrint = rhs._print(())
        return Optional.zip(lhsPrint, rhsPrint)
          .map(lhs.monoid.combine)
        // TODO: are these needed?
        //          ?? lhsPrint
        //          ?? rhsPrint
    })
  }

  func or(_ other: @escaping @autoclosure () -> Syntax) -> Syntax {
    return Syntax(
      monoid: self.monoid,
      parse: { m in
        let copy = m
        if let a = self._parse(&m) { return a }
        m = copy
        return other()._parse(&m)
    },
      print: { m in self._print(m) ?? other()._print(m) }
    )
  }
}

extension Syntax where A == () {
  func discard<B>(processing other: Syntax<B, M>) -> Syntax<B, M> {
    return self %> other
  }
  static func %><B>(_ lhs: Syntax<A, M>, _ rhs: Syntax<B, M>) -> Syntax<B, M> {
    return Syntax<B, M>(
      monoid: lhs.monoid,
      parse: { m in
        guard let _ = lhs._parse(&m) else { return nil }
        guard let a = rhs._parse(&m) else { return nil }
        return a
    },
      print: { a in
        let lhsPrint = lhs._print(())
        let rhsPrint = rhs._print(a)
        return Optional.zip(lhsPrint, rhsPrint)
          .map(lhs.monoid.combine)
        // TODO: are these needed?
        //          ?? lhsPrint
        //          ?? rhsPrint
    })
  }
    static func <%><B>(_ lhs: Syntax<A, M>, _ rhs: Syntax<B, M>) -> Syntax<B, M> {
      return Syntax<B, M>(
        monoid: lhs.monoid,
        parse: { m in
          guard let _ = lhs._parse(&m) else { return nil }
          guard let a = rhs._parse(&m) else { return nil }
          return a
      },
        print: { a in
          let lhsPrint = lhs._print(())
          let rhsPrint = rhs._print(a)
          return Optional.zip(lhsPrint, rhsPrint)
            .map(lhs.monoid.combine)
          // TODO: are these needed?
          //          ?? lhsPrint
          //          ?? rhsPrint
      })
    }
}

extension Optional {
  fileprivate static func zip<B>(_ a: Wrapped?, _ b: B?) -> (Wrapped, B)? {
    guard let a = a, let b = b else { return nil }
    return (a, b)
  }
}

extension Syntax {
  init(_ monoid: Monoid<M>) {
    self = Syntax.init(
      monoid: monoid,
      parse: { _ in nil },
      print: { _ in nil }
    )
  }
}
