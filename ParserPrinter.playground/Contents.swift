import Syntax
import PartialIso
import URLRequestRouter

struct User: Codable {
  let email: String
  let password: String
}

let route: Syntax =
  .post(.json(User.self)) </> "hello" </> "world" </> .int <?> ("x", .int) <&> ("y", .float)
