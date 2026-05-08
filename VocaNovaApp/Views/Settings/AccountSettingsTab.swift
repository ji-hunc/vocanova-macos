import SwiftUI

struct AccountSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var auth: AuthViewModel

    var body: some View {
        Form {
            if let user = viewModel.sessionStore.session?.user {
                Section("로그인됨") {
                    LabeledContent("이름", value: user.displayName)
                    if let email = user.email {
                        LabeledContent("이메일", value: email)
                    }
                    if let provider = user.appMetadata?.provider {
                        LabeledContent("로그인 방식", value: provider.capitalized)
                    }
                }

                Section {
                    Button("로그아웃", role: .destructive) {
                        Task { await auth.signOut() }
                    }
                    .controlSize(.regular)
                }
            } else {
                Section("로그인이 필요해요") {
                    Text("크롬 익스텐션·iOS 앱과 같은 계정으로 단어를 동기화하려면 로그인하세요.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button("Google로 로그인") {
                            Task { await auth.signInWithGoogle() }
                        }
                        Button("Apple로 로그인") {
                            Task { await auth.signInWithApple() }
                        }
                        Spacer()
                    }
                    .disabled(auth.isWorking)

                    if let err = auth.errorMessage {
                        Text(err)
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
