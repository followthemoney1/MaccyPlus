import AppKit
import Foundation

@MainActor
class VariableExpander {
  static let shared = VariableExpander()

  private let tokenPattern = try? NSRegularExpression(
    pattern: #"%([A-Z]+(?::[^%]*)?)%"#,
    options: []
  )

  /// Expands all variable tokens in a single pass.
  /// Returns nil if expansion was cancelled (e.g. user dismissed %INPUT:% view).
  func expand(_ text: String) async -> String? {
    guard let tokenPattern else { return text }

    let nsString = text as NSString
    let matches = tokenPattern.matches(
      in: text,
      options: [],
      range: NSRange(location: 0, length: nsString.length)
    )

    guard !matches.isEmpty else { return text }

    // Check if we have INPUT tokens that need user interaction
    let inputLabels = extractInputLabels(from: text, matches: matches)
    var inputValues: [String: String] = [:]

    if !inputLabels.isEmpty {
      // For now, use empty strings for INPUT tokens
      // The VariableInputView will handle this interactively
      for label in inputLabels {
        inputValues[label] = ""
      }
    }

    // Single-pass replacement (reverse order to preserve indices)
    var result = text
    for match in matches.reversed() {
      let fullRange = Range(match.range, in: text)!
      let tokenRange = Range(match.range(at: 1), in: text)!
      let token = String(text[tokenRange])

      let replacement = resolveToken(token, inputValues: inputValues)
      result.replaceSubrange(fullRange, with: replacement)
    }

    return result
  }

  /// Expands with provided input values for %INPUT:label% tokens.
  func expand(_ text: String, inputValues: [String: String]) -> String {
    guard let tokenPattern else { return text }

    let nsString = text as NSString
    let matches = tokenPattern.matches(
      in: text,
      options: [],
      range: NSRange(location: 0, length: nsString.length)
    )

    guard !matches.isEmpty else { return text }

    var result = text
    for match in matches.reversed() {
      let fullRange = Range(match.range, in: text)!
      let tokenRange = Range(match.range(at: 1), in: text)!
      let token = String(text[tokenRange])

      let replacement = resolveToken(token, inputValues: inputValues)
      result.replaceSubrange(fullRange, with: replacement)
    }

    return result
  }

  /// Returns labels for all %INPUT:label% tokens in the text.
  func inputLabels(in text: String) -> [String] {
    guard let tokenPattern else { return [] }

    let nsString = text as NSString
    let matches = tokenPattern.matches(
      in: text,
      options: [],
      range: NSRange(location: 0, length: nsString.length)
    )

    return extractInputLabels(from: text, matches: matches)
  }

  /// Returns true if text contains %INPUT:...% tokens.
  func hasInputTokens(in text: String) -> Bool {
    return !inputLabels(in: text).isEmpty
  }

  private func extractInputLabels(from text: String, matches: [NSTextCheckingResult]) -> [String] {
    var labels: [String] = []
    for match in matches {
      let tokenRange = Range(match.range(at: 1), in: text)!
      let token = String(text[tokenRange])
      if token.hasPrefix("INPUT:") {
        let label = String(token.dropFirst(6))
        if !label.isEmpty && !labels.contains(label) {
          labels.append(label)
        }
      }
    }
    return labels
  }

  private func resolveToken(_ token: String, inputValues: [String: String]) -> String {
    switch token {
    case "CLIPBOARD":
      return NSPasteboard.general.string(forType: .string) ?? ""
    case "DATE":
      return DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
    case "TIME":
      return DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
    case "UUID":
      return UUID().uuidString
    default:
      if token.hasPrefix("INPUT:") {
        let label = String(token.dropFirst(6))
        return inputValues[label] ?? ""
      }
      // Unknown token: leave literal
      return "%\(token)%"
    }
  }
}
