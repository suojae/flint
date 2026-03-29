import Foundation

public struct AvoidForceUnwrapRule: Rule {
  public init() {}

  public let id = "avoid_force_unwrap"
  public let summary =
    "Avoid force unwrapping and implicitly unwrapped optionals."

  public func diagnose(in file: SourceFile) -> [Diagnostic] {
    var scanner = BangScanner(file: file, ruleID: id)
    return scanner.run()
  }
}

private struct BangScanner {
  private enum State {
    case code
    case lineComment
    case blockComment(depth: Int)
    case stringLiteral
    case multilineStringLiteral
  }

  private let file: SourceFile
  private let ruleID: String
  private let characters: [Character]

  private var diagnostics: [Diagnostic] = []
  private var index = 0
  private var line = 1
  private var column = 1
  private var state: State = .code
  private var escaped = false

  init(file: SourceFile, ruleID: String) {
    self.file = file
    self.ruleID = ruleID
    self.characters = Array(file.content)
  }

  mutating func run() -> [Diagnostic] {
    while index < characters.count {
      switch state {
      case .code:
        scanCode()
      case .lineComment:
        scanLineComment()
      case .blockComment(let depth):
        scanBlockComment(depth: depth)
      case .stringLiteral:
        scanStringLiteral()
      case .multilineStringLiteral:
        scanMultilineStringLiteral()
      }
    }

    return diagnostics
  }

  private mutating func scanCode() {
    if matches("//") {
      state = .lineComment
      advance(2)
      return
    }

    if matches("/*") {
      state = .blockComment(depth: 1)
      advance(2)
      return
    }

    if matches("\"\"\"") {
      state = .multilineStringLiteral
      advance(3)
      return
    }

    if currentCharacter == "\"" {
      state = .stringLiteral
      escaped = false
      advance()
      return
    }

    if currentCharacter == "!" && shouldReportBang() {
      diagnostics.append(
        Diagnostic(
          filePath: file.path,
          line: line,
          column: column,
          ruleID: ruleID,
          message:
            "Avoid force unwrapping and implicitly unwrapped optionals. Use guard/if let or a non-optional type instead."
        )
      )
    }

    advance()
  }

  private mutating func scanLineComment() {
    if currentCharacter == "\n" {
      state = .code
    }
    advance()
  }

  private mutating func scanBlockComment(depth: Int) {
    if matches("/*") {
      state = .blockComment(depth: depth + 1)
      advance(2)
      return
    }

    if matches("*/") {
      let nextDepth = depth - 1
      state = nextDepth == 0 ? .code : .blockComment(depth: nextDepth)
      advance(2)
      return
    }

    advance()
  }

  private mutating func scanStringLiteral() {
    if escaped {
      escaped = false
      advance()
      return
    }

    if currentCharacter == "\\" {
      escaped = true
      advance()
      return
    }

    if currentCharacter == "\"" {
      state = .code
      advance()
      return
    }

    advance()
  }

  private mutating func scanMultilineStringLiteral() {
    if matches("\"\"\"") {
      state = .code
      advance(3)
      return
    }

    advance()
  }

  private func shouldReportBang() -> Bool {
    if index == 0 || characters[index - 1].isWhitespace {
      return false
    }

    if peekCharacter(after: index) == "=" {
      return false
    }

    let previous = previousNonWhitespaceCharacter(before: index)
    guard let previous else {
      return false
    }

    guard previous.isIdentifierLike || [")", "]", "}", "?", "\""].contains(previous) else {
      return false
    }

    let keyword = previousKeyword(before: index)
    if keyword == "as" || keyword == "try" {
      return false
    }

    return true
  }

  private func previousNonWhitespaceCharacter(before index: Int) -> Character? {
    var cursor = index - 1
    while cursor >= 0 {
      let character = characters[cursor]
      if !character.isWhitespace {
        return character
      }
      cursor -= 1
    }
    return nil
  }

  private func previousKeyword(before index: Int) -> String? {
    var cursor = index - 1
    while cursor >= 0 && characters[cursor].isWhitespace {
      cursor -= 1
    }

    guard cursor >= 0 else { return nil }

    var charactersBuffer: [Character] = []
    while cursor >= 0 && characters[cursor].isLetter {
      charactersBuffer.append(characters[cursor])
      cursor -= 1
    }

    guard !charactersBuffer.isEmpty else { return nil }
    return String(charactersBuffer.reversed())
  }

  private func peekCharacter(after index: Int) -> Character? {
    let nextIndex = index + 1
    guard nextIndex < characters.count else { return nil }
    return characters[nextIndex]
  }

  private func matches(_ text: String) -> Bool {
    let candidates = Array(text)
    guard index + candidates.count <= characters.count else {
      return false
    }

    for offset in 0..<candidates.count where characters[index + offset] != candidates[offset] {
      return false
    }

    return true
  }

  private var currentCharacter: Character {
    characters[index]
  }

  private mutating func advance(_ count: Int = 1) {
    guard count > 0 else { return }

    for _ in 0..<count {
      guard index < characters.count else { return }

      if characters[index] == "\n" {
        line += 1
        column = 1
      } else {
        column += 1
      }

      index += 1
    }
  }
}

private extension Character {
  var isWhitespace: Bool {
    unicodeScalars.allSatisfy(CharacterSet.whitespacesAndNewlines.contains)
  }

  var isLetter: Bool {
    unicodeScalars.allSatisfy(CharacterSet.letters.contains)
  }

  var isIdentifierLike: Bool {
    isLetter || isNumber || self == "_"
  }

  var isNumber: Bool {
    unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains)
  }
}
