import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var auth: AuthViewModel

    var body: some View {
        TabView {
            GeneralSettingsTab(viewModel: viewModel)
                .tabItem { Label("일반", systemImage: "gearshape") }

            HotkeySettingsTab(viewModel: viewModel)
                .tabItem { Label("단축키", systemImage: "keyboard") }

            AccountSettingsTab(viewModel: viewModel, auth: auth)
                .tabItem { Label("계정", systemImage: "person.crop.circle") }
        }
        .padding(20)
        .frame(width: 480, height: 360)
    }
}
