import SwiftUI

struct VariableInputView: View {
  let labels: [String]
  let onSubmit: ([String: String]) -> Void
  let onCancel: () -> Void

  @State private var values: [String: String] = [:]
  @FocusState private var focusedField: String?

  var body: some View {
    VStack(spacing: 10) {
      Text(String(localized: "variable_input_title"))
        .font(.headline)

      ForEach(labels, id: \.self) { label in
        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: label)
            .font(.caption)
            .foregroundStyle(.secondary)
          TextField(label, text: binding(for: label))
            .textFieldStyle(.roundedBorder)
            .focused($focusedField, equals: label)
            .accessibilityIdentifier("variable_input_view_\(label)")
            .onSubmit {
              if let nextIndex = labels.firstIndex(of: label).map({ $0 + 1 }),
                 nextIndex < labels.count {
                focusedField = labels[nextIndex]
              } else {
                submitValues()
              }
            }
        }
      }

      HStack {
        Button(String(localized: "variable_input_cancel")) {
          onCancel()
        }
        .keyboardShortcut(.cancelAction)
        .accessibilityIdentifier("variable_input_cancel")

        Spacer()

        Button(String(localized: "variable_input_submit")) {
          submitValues()
        }
        .keyboardShortcut(.defaultAction)
        .accessibilityIdentifier("variable_input_submit")
      }
    }
    .padding()
    .task {
      focusedField = labels.first
    }
  }

  private func binding(for label: String) -> Binding<String> {
    Binding(
      get: { values[label] ?? "" },
      set: { values[label] = $0 }
    )
  }

  private func submitValues() {
    onSubmit(values)
  }
}
