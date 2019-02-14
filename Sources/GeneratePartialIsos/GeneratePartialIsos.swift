import SwiftSyntax

public final class Visitor: SyntaxVisitor {
  private var `enum` = ""
  public private(set) var out = ""

  override public func visit(_ node: EnumDeclSyntax) {
    self.enum = node.identifier.text
    super.visit(node)
  }

  override public func visit(_ node: EnumCaseElementSyntax) {
    if let associatedValue = node.associatedValue {
      let type: String
      if associatedValue.parameterList.count == 1 {
        type = associatedValue.parameterList[0].type?.description ?? ""
      } else {
        type = "("
          + associatedValue.parameterList
            .map { param -> String in
              let name = param.firstName.map { $0.text + ": " } ?? ""
              let type = param.type?.description ?? ""
              return name + type
            }
            .joined(separator: ", ")
          + ")"
      }

      self.out += """
extension PartialIso where A == \(type), B == \(self.enum) {
  static let \(node.identifier.text) = PartialIso(
    apply: \(self.enum).\(node.identifier.text),
    unapply: {
      guard case let .\(node.identifier.text)(value) = $0 else { return nil }
      return value
  }
  )
}

"""
    } else {
      self.out += """
extension PartialIso where A == Void, B == \(self.enum) {
  static let \(node.identifier.text) = PartialIso(
    apply: { .\(node.identifier.text) },
    unapply: {
      guard case .\(node.identifier.text) = $0 else { return nil }
      return ()
  }
  )
}

"""
    }
    super.visit(node)
  }
}
