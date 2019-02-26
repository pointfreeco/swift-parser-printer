import Foundation
import Monoid
import Syntax
import PartialIso

infix operator </>: SyntaxOperator
infix operator <?>: SyntaxOperator
infix operator <&>: SyntaxOperator

public typealias Router<A> = Syntax<A, RequestData>

extension Syntax where M == RequestData {

  public func match(request: URLRequest) -> A? {
    return self.route(requestData: RequestData(request: request))
  }

  public func match(url: URL) -> A? {
    return self.match(request: URLRequest(url: url))
  }

  public func match(urlString: String) -> A? {
    return URL(string: urlString).flatMap(self.match(url:))
  }

  public func request(for a: A) -> URLRequest? {
    return self._print(a).flatMap { $0.urlRequest }
  }

  public func url(for a: A) -> URL? {
    return self._print(a).flatMap { $0.urlRequest?.url }
  }

  public func urlString(for a: A) -> String? {
    return self._print(a).flatMap { $0.urlRequest?.url?.absoluteString }
  }

  /* todo: public? */ func route(requestData: RequestData) -> A? {
    var requestData = requestData
    guard let match = (self <% .end)._parse(&requestData) else { return nil }
    guard requestData == self.monoid.empty else { return nil }
    return match
  }

  public init(parse: @escaping (inout RequestData) -> A?, print: @escaping (A) -> RequestData?) {
    self.init(monoid: .requestData, parse: parse, print: print)
  }

  public init(_ routes: Syntax...) {
    self = routes.reduce(into: .init(.requestData)) { $0 = $0.or($1) }
  }

  public static func match<A0>(_ f: PartialIso<A0, A>, to syntax: Syntax<A0, M>) -> Syntax {
    return (syntax <% .end).map(f)
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

  public static func queryParam(_ key: String, _ iso: PartialIso<String?, A>) -> Syntax<A, M> {
    return Syntax(
      parse: { request in
        iso.apply(request.query.first(where: { $0.key == key })?.value)
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
    rhs: (key: String, iso: PartialIso<String?, B>)
    ) -> Syntax<(A, B), M> {

    return lhs <%> .queryParam(rhs.key, rhs.iso)
  }

  public static func <&> <B>(
    lhs: Syntax<A, M>,
    rhs: (key: String, iso: PartialIso<String?, B>)
    ) -> Syntax<(A, B), M> {

    return lhs <%> .queryParam(rhs.key, rhs.iso)
  }
}

extension Syntax where A == Void, M == RequestData {

  public static func method(_ method: Method) -> Syntax {
    return Syntax(
      parse: { request in
        guard
          let requestMethod = request.method,
          requestMethod.rawValue.caseInsensitiveCompare(method.rawValue) == .orderedSame
          else { return nil }
        
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

  public static func <?> <B>(
    lhs: Syntax,
    rhs: (key: String, iso: PartialIso<String?, B>)
    ) -> Syntax<B, M> {

    return lhs %> .queryParam(rhs.key, rhs.iso)
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
