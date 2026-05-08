import SwiftUI

struct AccountSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var auth: AuthViewModel

    var body: some View {
        Form {
            if let session = viewModel.sessionStore.session, let user = session.user {
                Section("로그인됨") {
                    LabeledContent("이름", value: user.displayName)
                    if let email = user.email {
                        LabeledContent("이메일", value: email)
                    }
                    // `lastProvider`(클라이언트 추적값)가 우선. 같은 이메일로 다른 provider로
                    // 로그인하는 경우 Supabase의 `app_metadata.provider`는 *최초 가입 시* provider라
                    // 잘못된 값이 나올 수 있어서다. 둘 다 없으면 표시 생략.
                    if let provider = session.lastProvider ?? user.appMetadata?.provider {
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
