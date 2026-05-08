import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("권한") {
                HStack {
                    Image(systemName: viewModel.isAXTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(viewModel.isAXTrusted ? .green : .orange)
                    Text(viewModel.isAXTrusted
                         ? "Accessibility 권한이 부여되었어요."
                         : "선택 텍스트를 읽으려면 Accessibility 권한이 필요해요.")
                    Spacer()
                    Button("시스템 설정 열기") {
                        viewModel.openAccessibilitySettings()
                    }
                    .controlSize(.small)
                }
            }

            Section("정보") {
                LabeledContent("버전",
                               value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                LabeledContent("빌드",
                               value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
            }
        }
        .formStyle(.grouped)
    }
}
