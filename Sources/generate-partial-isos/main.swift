import Darwin
import Foundation
import GeneratePartialIsos
import SwiftSyntax

let arguments = CommandLine.arguments.dropFirst()

guard !arguments.isEmpty else {
  fputs("Usage: swift run generate-partial-isos [file.swift ...]\n", stderr)
  exit(EXIT_FAILURE)
}

var visitor = Visitor()
try arguments.forEach { file in
  visitor.visit(try SyntaxTreeParser.parse(URL(fileURLWithPath: file)))
}
print(visitor.out)
