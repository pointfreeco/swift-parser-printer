import Foundation
import Monoid
import Syntax
import PartialIso

infix operator </>: SyntaxOperator
infix operator <?>: SyntaxOperator
infix operator <&>: SyntaxOperator

extension Syntax where M == RequestData {

  init(parse: @escaping (inout RequestData) -> A?, print: @escaping (A) -> RequestData?) {
    self.init(monoid: .requestData, parse: parse, print: print)
  }

  public static func pathParam(_ iso: PartialIso<String, A>) -> Syntax<A, M> {
    return Syntax(
      parse: { request in
        guard !request.path.isEmpty else { return nil }
        let path = request.path.removeFirst()
        return iso.apply(path)
    }, print: { a in
      RequestData(
        path: iso.unapply(a).map { [$0] } ?? []
      )
    })
  }

  public static func queryParam(_ key: String, _ iso: PartialIso<String, A>) -> Syntax<A, M> {
    return Syntax(
      parse: { request in
        request.query.first(where: { $0.key == key })?.value.flatMap(iso.apply)
    },
      print: { a in
        RequestData(
          query: iso.unapply(a).map { [(key, $0)] } ?? []
        )
    }
    )
  }

  public static func </> <B>(lhs: Syntax<A, M>, rhs: PartialIso<String, B>) -> Syntax<(A, B), M> {
    return lhs <%> .pathParam(rhs)
  }

  public static func </> (lhs: Syntax<A, M>, rhs: PartialIso<String, ()>) -> Syntax<A, M> {
    return lhs <% .pathParam(rhs)
  }

  public static func <?> <B>(
    lhs: Syntax<A, M>,
    rhs: (key: String, iso: PartialIso<String, B>)
    ) -> Syntax<(A, B), M> {

    return lhs <%> .queryParam(rhs.key, rhs.iso)
  }

  public static func <&> <B>(
    lhs: Syntax<A, M>,
    rhs: (key: String, iso: PartialIso<String, B>)
    ) -> Syntax<(A, B), M> {

    return lhs <%> .queryParam(rhs.key, rhs.iso)
  }

}

extension Syntax where A == Void, M == RequestData {

  public static func method(_ method: Method) -> Syntax {
    return Syntax(
      parse: { request in
        guard request.method == .some(method) else { return nil }
        request.method = nil
        return ()
    }, print: { a in
      return RequestData(
        method: .some(method)
      )
    })
  }

  public static let get = method(.get).or(method(.head))
  public static let delete = method(.delete)

  public static func </> <B>(lhs: Syntax, rhs: PartialIso<String, B>) -> Syntax<B, M> {
    return lhs %> .pathParam(rhs)
  }

  public static var end: Syntax {
    return Syntax(
      parse: { request in
        guard request.path.isEmpty else { return nil }
        request = Monoid.requestData.empty
        return ()
    }, print: { a in
      return Monoid.requestData.empty
    })
  }

}

extension Syntax where A: Codable, M == RequestData {

  public static func body(_ iso: PartialIso<Data, A>) -> Syntax {
    return Syntax(
      parse: { request in
        guard let body = request.body else { return nil }
        request.body = nil
        return iso.apply(body)
    }, print: { a in
      return RequestData(body: iso.unapply(a))
    })
  }

  public static func post(_ iso: PartialIso<Data, A>) -> Syntax {
    return .method(.post) %> .body(iso)
  }

  public static func put(_ iso: PartialIso<Data, A>) -> Syntax {
    return .method(.put) %> .body(iso)
  }

  public static func patch(_ iso: PartialIso<Data, A>) -> Syntax {
    return .method(.patch) %> .body(iso)
  }

}
