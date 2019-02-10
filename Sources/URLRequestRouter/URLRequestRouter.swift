import Foundation
import Monoid
import Syntax
import PartialIso

infix operator </>: SyntaxOperator
infix operator <?>: SyntaxOperator
infix operator <&>: SyntaxOperator

extension Syntax where M == RequestData {

  public static func </> <B>(lhs: Syntax<A, M>, rhs: PartialIso<String, B>) -> Syntax<(A, B), M> {
    return lhs <%> .pathParam(rhs)
  }

  public static func </> (lhs: Syntax<A, M>, rhs: PartialIso<String, ()>) -> Syntax<A, M> {
    return lhs <% .pathParam(rhs)
  }

  public static func pathParam(_ iso: PartialIso<String, A>) -> Syntax<A, M> {
    return Syntax<A, M>.init(
      monoid: .requestData,
      parse: { request in
        let path = request.path.removeFirst()
        return iso.apply(path)
    }, print: { a in
      return RequestData(
        path: iso.unapply(a).map { [$0] } ?? []
      )
    })
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

  public static func queryParam(_ key: String, _ iso: PartialIso<String, A>) -> Syntax<A, M> {
    return Syntax<A, M>.init(
      monoid: .requestData,
      parse: { request in

        let tmp = (request.query.first(where: { k, _ in k == key })?.value).flatMap { value in
          iso.apply(value)
        }
        return tmp

    },
      print: { a in
        return RequestData(
          query: iso.unapply(a).map { [(key, $0)] } ?? []
        )
    }
    )
  }

}

extension Syntax where A == Void, M == RequestData {

  public static func method(_ method: Method) -> Syntax {
    return Syntax<(), M>.init(
      monoid: .requestData,
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

}

extension Syntax where A: Codable, M == RequestData {

  public static func body(_ iso: PartialIso<Data, A>) -> Syntax {
    return Syntax(
      monoid: .requestData,
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
