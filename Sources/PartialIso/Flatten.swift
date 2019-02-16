public func leftFlatten<A, B, C>(_ tuple: ((A, B), C)) -> (A, B, C) {
  return (tuple.0.0, tuple.0.1, tuple.1)
}

public func leftParenthesize<A, B, C>(_ tuple: (A, B, C)) -> ((A, B), C) {
  return ((tuple.0, tuple.1), tuple.2)
}

public func leftFlatten<A, B, C, D>(_ tuple: (((A, B), C), D)) -> (A, B, C, D) {
  return (tuple.0.0.0, tuple.0.0.1, tuple.0.1, tuple.1)
}

public func leftParenthesize<A, B, C, D>(_ tuple: (A, B, C, D)) -> (((A, B), C), D) {
  return (((tuple.0, tuple.1), tuple.2), tuple.3)
}
