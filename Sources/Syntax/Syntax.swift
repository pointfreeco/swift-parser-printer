import Monoid
import PartialIso

precedencegroup SyntaxOperator { associativity: left }
infix operator <%>: SyntaxOperator
infix operator %>: SyntaxOperator
infix operator <%: SyntaxOperator

public struct Syntax<A, M: Equatable> {
  public let monoid: Monoid<M>
  public let _parse: (inout M) -> A?
  public let _print: (A) -> M?

  public init(monoid: Monoid<M>, parse: @escaping (inout M) -> A?, print: @escaping (A) -> M?) {
    self.monoid = monoid
    self._parse = parse
    self._print = print
  }

  public func parse(_ m: M) -> A? {
    var m = m
    guard let match = self._parse(&m) else { return nil }
    guard m == self.monoid.empty else { return nil }
    return match
  }

  public func run(_ m: M) -> (M, A?) {
    var m = m
    let match = self._parse(&m)
    return (m, match)
  }

  public func print(_ a: A) -> M? {
    return self._print(a)
  }

  public func map<B>(
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

  public func map<B>(_ iso: PartialIso<A, B>) -> Syntax<B, M> {
    return self.map(iso.apply, iso.unapply)
  }

  public func keep<B>(and other: Syntax<B, M>) -> Syntax<(A, B), M> {
    return self <%> other
  }
  public static func <%><B>(_ lhs: Syntax<A, M>, _ rhs: Syntax<B, M>) -> Syntax<(A, B), M> {
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
        return Optional.zip(with: lhs.monoid.combine, lhsPrint, rhsPrint)
        // TODO: are these needed?
        //          ?? lhsPrint
        //          ?? rhsPrint
    })
  }

  public static func <%>(_ lhs: Syntax<A, M>, _ rhs: Syntax<(), M>) -> Syntax<A, M> {
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
        return Optional.zip(with: lhs.monoid.combine, lhsPrint, rhsPrint)
        // TODO: are these needed?
        //          ?? lhsPrint
        //          ?? rhsPrint
    })
  }

  public func keep(discarding: Syntax<(), M>) -> Syntax<A, M> {
    return self <% discarding
  }
  public static func <%(_ lhs: Syntax<A, M>, _ rhs: Syntax<(), M>) -> Syntax<A, M> {
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
        return Optional.zip(with: lhs.monoid.combine, lhsPrint, rhsPrint)
        // TODO: are these needed?
        //          ?? lhsPrint
        //          ?? rhsPrint
    })
  }

  public func or(_ other: @escaping @autoclosure () -> Syntax) -> Syntax {
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
  public func discard<B>(keeping other: Syntax<B, M>) -> Syntax<B, M> {
    return self %> other
  }
  public static func %><B>(_ lhs: Syntax<A, M>, _ rhs: Syntax<B, M>) -> Syntax<B, M> {
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
        return Optional.zip(with: lhs.monoid.combine, lhsPrint, rhsPrint)
        // TODO: are these needed?
        //          ?? lhsPrint
        //          ?? rhsPrint
    })
  }
  public static func <%><B>(_ lhs: Syntax<A, M>, _ rhs: Syntax<B, M>) -> Syntax<B, M> {
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
        return Optional.zip(with: lhs.monoid.combine, lhsPrint, rhsPrint)
        // TODO: are these needed?
        //          ?? lhsPrint
        //          ?? rhsPrint
    })
  }
}

extension Optional {
  fileprivate static func zip<B, C>(
    with f: @escaping (Wrapped, B) -> C,
    _ a: Wrapped?,
    _ b: B?) -> C? {
    guard let a = a, let b = b else { return nil }
    return f(a, b)
  }
}

extension Syntax {
  public init(_ monoid: Monoid<M>) {
    self = Syntax.init(
      monoid: monoid,
      parse: { _ in nil },
      print: { _ in nil }
    )
  }
}

extension Syntax {
  public static func many<Element>(_ syntax: Syntax<Element, M>) -> Syntax where A == [Element] {
    return Syntax(
      monoid: syntax.monoid,
      parse: { m in
        var result: [Element] = []
        while (true) {
          let copy = m
          if let a = syntax._parse(&m) { result.append(a); continue }
          m = copy
          break
        }
        return result

    }, print: { xs in
      return xs.reduce(syntax.monoid.empty) { accum, x in
        syntax.monoid.combine(accum, syntax._print(x) ?? syntax.monoid.empty)
      }
    })
  }

  public static func many<Element>(
    _ syntax: Syntax<Element, M>,
    separatedBy: Syntax<(), M>
    ) -> Syntax where A == [Element] {

    return Syntax(
      monoid: syntax.monoid,
      parse: { m in
        var result: [Element] = []
        while (true) {
          let copy = m
          if let a = syntax._parse(&m), let _ = separatedBy._parse(&m) { result.append(a); continue }
          m = copy
          if let a = syntax._parse(&m) { result.append(a); break }
          m = copy
          break
        }
        return result

    }, print: { xs in
      var idx = 0
      return xs.reduce(into: syntax.monoid.empty) { accum, x in
        if idx > 0 {
          syntax.monoid.mcombine(&accum, separatedBy._print(()) ?? syntax.monoid.empty)
        }
        syntax.monoid.mcombine(&accum, syntax._print(x) ?? syntax.monoid.empty)
        idx += 1
      }
    })
  }
}

extension Syntax {
  public func flatten<B, C, D>() -> Syntax<(B, C, D), M> where A == ((B, C), D) {
    return self.map(.leftFlatten())
  }

  public func flatten<B, C, D, E>() -> Syntax<(B, C, D, E), M> where A == (((B, C), D), E) {
    return self.map(.leftFlatten())
  }
}

extension Syntax {
  public func flatten<B, C, D, Z>(
    _ apply: @escaping (B, C, D) -> Z,
    _ unapply: @escaping (Z) -> (B, C, D)
    ) -> Syntax<Z, M> where A == ((B, C), D) {

    return self.flatten().map(apply, unapply)
  }

  public func flatten<B, C, D, E, Z>(
    _ apply: @escaping (B, C, D, E) -> Z,
    _ unapply: @escaping (Z) -> (B, C, D, E)
    ) -> Syntax<Z, M> where A == (((B, C), D), E) {
    
    return self.flatten().map(apply, unapply)
  }
}
