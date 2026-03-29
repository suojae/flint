import Foundation

public enum DiagnosticSeverity: String, Sendable {
  case warning
  case error
}

public struct Diagnostic: Sendable, Equatable {
  public let filePath: String
  public let line: Int
  public let column: Int
  public let severity: DiagnosticSeverity
  public let ruleID: String
  public let message: String

  public init(
    filePath: String,
    line: Int,
    column: Int,
    severity: DiagnosticSeverity = .warning,
    ruleID: String,
    message: String
  ) {
    self.filePath = filePath
    self.line = line
    self.column = column
    self.severity = severity
    self.ruleID = ruleID
    self.message = message
  }

  public var formatted: String {
    "\(filePath):\(line):\(column) \(severity.rawValue): [\(ruleID)] \(message)"
  }
}
