import SwiftSyntax

public final class Visitor: SyntaxVisitor {
  private var nest: [String] = []
  public private(set) var out = "import PartialIso\n"

  public override func visit(_ node: ClassDeclSyntax) {
    self.nest.append(node.identifier.text)
    super.visit(node)
    self.nest.removeLast()
  }

  override public func visit(_ node: EnumDeclSyntax) {
    self.nest.append(node.identifier.text)
    super.visit(node)
    self.nest.removeLast()
  }

  public override func visit(_ node: ExtensionDeclSyntax) {
    let extendedType = String(
      decoding: node.extendedType.description.utf8.prefix(node.extendedType.contentLength.utf8Length),
      as: UTF8.self
    )
    self.nest.append(extendedType)
    super.visit(node)
    self.nest.removeLast()
  }

  public override func visit(_ node: StructDeclSyntax) {
    self.nest.append(node.identifier.text)
    super.visit(node)
    self.nest.removeLast()
  }

  override public func visit(_ node: EnumCaseElementSyntax) {
    let enumType = self.nest.joined(separator: ".")
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
extension PartialIso where A == \(type), B == \(enumType) {
  static let \(node.identifier.text) = PartialIso(
    apply: \(enumType).\(node.identifier.text),
    unapply: {
      guard case let .\(node.identifier.text)(value) = $0 else { return nil }
      return value
  }
  )
}

"""
    } else {
      self.out += """
extension PartialIso where A == Void, B == \(enumType) {
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
