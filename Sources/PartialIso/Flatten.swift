extension PartialIso {
  public static func leftFlatten<C, D, E>() -> PartialIso where A == ((C, D), E), B == (C, D, E) {
    return PartialIso(
      apply: { tuple in
        (tuple.0.0, tuple.0.1, tuple.1)
    }, unapply: { tuple in
      ((tuple.0, tuple.1), tuple.2)
    })
  }

  public static func leftFlatten<C, D, E, F>() -> PartialIso where A == (((C, D), E), F), B == (C, D, E, F) {
    return PartialIso(
      apply: { tuple in
        (tuple.0.0.0, tuple.0.0.1, tuple.0.1, tuple.1)
    }, unapply: { tuple in
      (((tuple.0, tuple.1), tuple.2), tuple.3)
    })
  }
}
