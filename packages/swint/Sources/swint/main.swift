import Foundation
import SwintCore

@main
struct SwintCommand {
  static func main() {
    let arguments = Array(CommandLine.arguments.dropFirst())

    if arguments.isEmpty || arguments.contains("--help") || arguments.contains("-h") {
      printUsage()
      Foundation.exit(0)
    }

    let command = arguments[0]
    switch command {
    case "lint":
      runLint(paths: Array(arguments.dropFirst()))
    default:
      fputs("Unknown command: \(command)\n", stderr)
      printUsage()
      Foundation.exit(64)
    }
  }

  private static func runLint(paths: [String]) {
    do {
      let linter = Linter()
      let diagnostics = try linter.lint(paths: paths)

      if diagnostics.isEmpty {
        print("No issues found.")
        Foundation.exit(0)
      }

      for diagnostic in diagnostics {
        print(diagnostic.formatted)
      }

      print("\nFound \(diagnostics.count) issue(s).")
      Foundation.exit(1)
    } catch {
      fputs("\(error.localizedDescription)\n", stderr)
      Foundation.exit(1)
    }
  }

  private static func printUsage() {
    print(
      """
      Swint

      Usage:
        swint lint [path ...]

      Examples:
        swint lint Sources
        swint lint Sources Tests
      """
    )
  }
}
