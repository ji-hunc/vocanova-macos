import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel

    /// 메뉴바 끄기 첫 시도 시 표시할 확인 알림 상태.
    @State private var showHideMenuBarAlert = false

    var body: some View {
        Form {
            Section("동작") {
                Toggle("시작시 실행", isOn: $viewModel.launchAtLoginEnabled)

                Text("Mac 시작 시 VocaNova가 자동으로 실행돼요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if let err = viewModel.launchAtLoginError {
                    HStack(spacing: 6) {
                        Text(err)
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        if viewModel.launchAtLogin.requiresApproval {
                            Button("시스템 설정 열기") {
                                viewModel.openLoginItemsSettings()
                            }
                            .controlSize(.small)
                        }
                    }
                }

                Divider().padding(.vertical, 2)

                Toggle("메뉴바 아이콘 표시", isOn: menuBarBinding)
                Text("끄면 Dock 아이콘으로 설정에 접근해요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section("외관") {
                Picker("테마", selection: $viewModel.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("‘자동’은 시스템 설정의 라이트/다크 모드를 따라가요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

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
        .alert("메뉴바 아이콘을 숨길까요?",
               isPresented: $showHideMenuBarAlert) {
            Button("취소", role: .cancel) { /* binding은 자동으로 true 유지 */ }
            Button("숨기기", role: .destructive) {
                viewModel.didConfirmMenuBarHide = true
                viewModel.showMenuBarIcon = false
            }
        } message: {
            Text("메뉴바 아이콘을 숨기면 Dock 아이콘으로 설정에 접근할 수 있어요. 다시 표시하려면 설정에서 켜주세요.")
        }
    }

    /// 메뉴바 토글의 커스텀 binding.
    /// `false`로 가는 첫 번째 시도는 alert를 띄우고, 알림에서 확인할 때만 실제로 적용한다.
    /// 취소 시 `set`을 호출하지 않으므로 토글이 자동으로 `true`로 되돌아간다.
    private var menuBarBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showMenuBarIcon },
            set: { newValue in
                if newValue == false && !viewModel.didConfirmMenuBarHide {
                    showHideMenuBarAlert = true
                    return  // alert 확인 후에 viewModel.showMenuBarIcon이 갱신된다.
                }
                viewModel.showMenuBarIcon = newValue
            }
        )
    }
}
