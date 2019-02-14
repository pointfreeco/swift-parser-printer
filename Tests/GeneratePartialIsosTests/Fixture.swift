struct Category {
  struct Id {
    let id: Int
  }

  let name: String
}

enum Routes {
  case home
  case episode(id: Int)
  case login(username: String, password: String)
  case search(String, Category.Id)
  case pathological()
}
