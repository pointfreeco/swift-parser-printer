import Foundation
import Monoid
import Syntax
import PartialIso

infix operator </>: SyntaxOperator
infix operator <?>: SyntaxOperator

extension Syntax where M == RequestData {

  public static func </><B>(_ lhs: Syntax<A, M>, _ rhs: PartialIso<String, B>) -> Syntax<(A, B), M> {
    return lhs <%> .pathParam(rhs)
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

  public static func <?><B>(
    _ lhs: Syntax<A, M>,
    _ rhs: (key: String, iso: PartialIso<String, B>)
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
