import Foundation

public struct SourceFile: Sendable {
  public let path: String
  public let content: String

  public init(path: String, content: String) {
    self.path = path
    self.content = content
  }
}

public protocol Rule: Sendable {
  var id: String { get }
  var summary: String { get }
  func diagnose(in file: SourceFile) -> [Diagnostic]
}
