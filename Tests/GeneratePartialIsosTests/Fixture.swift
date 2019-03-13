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
  case search(Search)
  case pathological(Void)

  enum Search {
    case index
    case query(String, Category.Id)
    case easterEgg(EasterEgg)
  }
}

extension Routes.Search {
  enum EasterEgg {
    case brandon
    case stephen
  }
}
