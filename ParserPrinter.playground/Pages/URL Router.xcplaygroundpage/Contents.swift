import Foundation
import PartialIso
import Syntax
import URLRequestRouter

struct User: Codable {
  let email: String
  let password: String
}

enum Route {
  case home
  case episodes(limit: Int?, offset: Int?)
  case episode(Int)
  case search(String?)
  case signUp(User)
}

let router = Router(
  .match(.home, to: .get),
  .match(
    Route.episodes(limit:offset:),
    to: .get </> "episodes" <?> ("limit", .optional(.int)) <&> ("offset", .optional(.int))
  ),
  .match(Route.episode, to: .get </> "episodes" </> .int),
  .match(Route.search, to: .get </> "search" <?> ("q", .optional(.string))),
  .match(Route.signUp, to: .post(.json) </> "sign-up")
)

router.match(urlString: "/?ga=1")
router.match(urlString: "/episodes/1?ga=1")
router.match(urlString: "/episodes?limit=10")
router.match(urlString: "/search?ga=1")
router.match(urlString: "/search?q=point-free&ga=1")
router.match(urlString: "/search")
router.match(urlString: "/search?q=")

var req = URLRequest(url: URL(string: "/sign-up")!)
req.httpMethod = "post"
req.httpBody = Data("""
{"email":"support@pointfree.co","password":"blob8108"}
""".utf8)

router.match(request: req)

router.request(for: Route.search("blob"))
router.request(for: Route.search(""))
router.request(for: Route.search(nil))
router.request(for: Route.episode(42))
router.request(for: Route.episodes(limit: 10, offset: 10))
