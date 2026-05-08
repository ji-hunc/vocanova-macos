import KeyboardShortcuts
import SwiftUI

struct HotkeySettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("선택 단어 검색") {
                HStack {
                    Text("단축키")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .lookupSelection)
                }
                Text("기본값: ⌘ ⇧ F. 다른 앱이 같은 조합을 쓰면 충돌이 일어날 수 있어요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
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
