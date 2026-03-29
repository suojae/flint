import Foundation

public struct Linter: Sendable {
  public let rules: [any Rule]

  public init(rules: [any Rule] = DefaultRuleSet.rules) {
    self.rules = rules
  }

  public func lint(paths: [String]) throws -> [Diagnostic] {
    let fileManager = FileManager.default
    let swiftFiles = try collectSwiftFiles(from: paths, fileManager: fileManager)

    let diagnostics = try swiftFiles.flatMap { path in
      let content = try String(contentsOfFile: path, encoding: .utf8)
      return lint(filePath: path, content: content)
    }

    return diagnostics.sorted {
      if $0.filePath != $1.filePath { return $0.filePath < $1.filePath }
      if $0.line != $1.line { return $0.line < $1.line }
      if $0.column != $1.column { return $0.column < $1.column }
      return $0.ruleID < $1.ruleID
    }
  }

  public func lint(filePath: String, content: String) -> [Diagnostic] {
    let sourceFile = SourceFile(path: filePath, content: content)
    return rules.flatMap { $0.diagnose(in: sourceFile) }
  }

  private func collectSwiftFiles(
    from paths: [String],
    fileManager: FileManager
  ) throws -> [String] {
    let inputPaths = paths.isEmpty ? ["."] : paths
    var files = Set<String>()

    for path in inputPaths {
      var isDirectory: ObjCBool = false
      guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
        throw LinterError.pathNotFound(path)
      }

      if isDirectory.boolValue {
        let enumerator = fileManager.enumerator(
          at: URL(fileURLWithPath: path),
          includingPropertiesForKeys: [.isRegularFileKey],
          options: [.skipsHiddenFiles]
        )

        while let url = enumerator?.nextObject() as? URL {
          guard url.pathExtension == "swift" else { continue }

          let values = try url.resourceValues(forKeys: [.isRegularFileKey])
          if values.isRegularFile == true {
            files.insert(url.path)
          }
        }
      } else if path.hasSuffix(".swift") {
        files.insert(URL(fileURLWithPath: path).path)
      }
    }

    return files.sorted()
  }
}

public enum LinterError: LocalizedError {
  case pathNotFound(String)

  public var errorDescription: String? {
    switch self {
    case .pathNotFound(let path):
      "Path not found: \(path)"
    }
  }
}
