import Foundation
import Monoid
import Syntax
import PartialIso

public struct Method: RawRepresentable, Equatable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public static let get = Method(rawValue: "GET")
  public static let head = Method(rawValue: "HEAD")
  public static let post = Method(rawValue: "POST")
  public static let put = Method(rawValue: "PUT")
  public static let patch = Method(rawValue: "PATCH")
  public static let delete = Method(rawValue: "DELETE")
}

public struct RequestData: Equatable {
  public var method: Method?
  public var path: [String]
  public var query: [(key: String, value: String?)]
  public var body: Data?

  public init(
    method: Method? = nil,
    path: [String] = [],
    query: [(key: String, value: String?)] = [],
    body: Data? = nil) {

    self.method = method
    self.path = path
    self.query = query
    self.body = body
  }

  public static func == (lhs: RequestData, rhs: RequestData) -> Bool {
    return lhs.method == rhs.method
      && lhs.path == rhs.path
      && lhs.query.count == rhs.query.count
      && zip(lhs.query, rhs.query).reduce(true) { $0 && $1.0 == $1.1 }
      && lhs.body == rhs.body
  }

//  public func urlRequest(baseUrl: URL?) -> URLRequest {
//
//    guard self.path.isEmpty && self.query.isEmpty

//    // Due to this bug https://bugs.swift.org/browse/SR-6527, if `URLComponents` doesn't contain any path or
//    // query information, it will fail to create a `URL`. We have to guard against that case and just return
//    // the base url.
//    return
//      (
//        data.path.isEmpty && data.query.isEmpty
//          ? (base ?? URL(string: "/"))
//          : urlComponents(from: data).url(relativeTo: base)
//        )
//        .map {
//          URLRequest(url: $0)
//            |> \.httpMethod .~ data.method?.rawValue
//            |> \.httpBody .~ data.body
//    }
//  }

  private var urlComponents: URLComponents {
    var components = URLComponents()
    components.path = self.path.joined(separator: "/")

    let query = self.query.filter { $0.value != nil }
    if !query.isEmpty {
      components.queryItems = query.map(URLQueryItem.init(name:value:))
    }

    return components
  }
}

extension RequestData {
  public init(request: URLRequest) {
    self.method = request.httpMethod.map(Method.init(rawValue:)) ?? .get

    guard let url = request.url else {
      self = .init()
      return
    }

    self.path = url.path
      .split(separator: "/", omittingEmptySubsequences: true)
      .map(String.init)

    // TODO: figure out base URL
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      self = .init()
      return
    }

    self.query = (components.queryItems ?? [])
      .map { item in (key: item.name, value: item.value) }
  }
}

extension Monoid where A == RequestData {
  public static let requestData = Monoid(
    empty: RequestData(),
    combine: { lhs, rhs in
      return .init(
        method: lhs.method ?? rhs.method,
        path: lhs.path + rhs.path,
        query: lhs.query + rhs.query,
        // TODO: is coalescing enough or should we be appending?
        body: lhs.body ?? rhs.body
      )
  })
}
