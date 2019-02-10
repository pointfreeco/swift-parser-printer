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
  public static let post = Method(rawValue: "POST")
  public static let put = Method(rawValue: "PUT")
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
