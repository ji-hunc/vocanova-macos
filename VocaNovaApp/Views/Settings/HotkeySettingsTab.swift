import KeyboardShortcuts
import SwiftUI

struct HotkeySettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("단축키 사용") {
                Toggle("단축키 사용", isOn: $viewModel.hotkeyEnabled)
                Text("끄면 ⌘⇧F를 눌러도 팝업이 뜨지 않아요. 단축키 조합은 보존돼요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section("선택 단어 검색") {
                HStack {
                    Text("단축키")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .lookupSelection)
                }
                .disabled(!viewModel.hotkeyEnabled)
                .opacity(viewModel.hotkeyEnabled ? 1.0 : 0.5)

                if !viewModel.hotkeyEnabled {
                    Text("단축키가 꺼져 있어요.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    Text("기본값: ⌘ ⇧ F. 다른 앱이 같은 조합을 쓰면 충돌이 일어날 수 있어요.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("도움말") {
                Text("어떤 앱에서든 단어를 드래그한 뒤 단축키를 누르면 사전 팝업이 떠요. ESC 또는 팝업 바깥을 클릭하면 닫혀요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
