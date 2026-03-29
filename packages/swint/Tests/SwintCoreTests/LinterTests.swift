import XCTest
@testable import SwintCore

final class LinterTests: XCTestCase {
  func testAvoidForceUnwrapReportsBangOptionalUsage() {
    let source = """
    struct UserViewModel {
      let name: String!

      func title(user: User?) -> String {
        user!.name
      }
    }
    """

    let diagnostics = Linter().lint(
      filePath: "UserViewModel.swift",
      content: source
    )

    XCTAssertEqual(diagnostics.count, 2)
    XCTAssertEqual(diagnostics.map(\.ruleID), ["avoid_force_unwrap", "avoid_force_unwrap"])
  }

  func testAvoidForceUnwrapIgnoresCommentsStringsAndPrefixNot() {
    let source = #"""
    func validate(flag: Bool, name: String?) {
      if !flag {
        print("user!.name")
      }

      // name!
      /* name! */
      _ = name != nil
    }
    """#

    let diagnostics = Linter().lint(
      filePath: "Validation.swift",
      content: source
    )

    XCTAssertTrue(diagnostics.isEmpty)
  }
}
