import AuthenticationServices
import SwiftUI

struct AccountSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var auth: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    /// SignInWithAppleButton은 macOS에서 외부 frame을 줘도 시스템 intrinsic 사이즈
    /// (대략 30pt) 으로만 그려진다. 그래서 Apple은 자연 크기로 두고, Google을 30pt에
    /// 맞춰 줄여 두 버튼 시각 높이를 일치시킨다.
    private static let buttonHeight: CGFloat = 30

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

                    VStack(spacing: 10) {
                        // Apple HIG: 시스템 표준 SignInWithAppleButton만이 정책 준수.
                        // 다크에선 흰 버튼이 어두운 배경에서 가독성 우수.
                        // height frame을 의도적으로 안 건다 — 시스템이 어차피 무시.
                        SignInWithAppleButton(.signIn) { _ in
                        } onCompletion: { _ in
                        }
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            // 시스템 콜백 대신 우리 인증 플로우 사용.
                            Button {
                                Task { await auth.signInWithApple() }
                            } label: {
                                Color.clear
                            }
                            .buttonStyle(.plain)
                        )

                        GoogleSignInButton(colorScheme: colorScheme) {
                            Task { await auth.signInWithGoogle() }
                        }
                        .frame(height: Self.buttonHeight)
                        .frame(maxWidth: .infinity)
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

/// Google Identity branding guidelines 준수 버튼.
/// 라이트: 흰 배경 + #747775 보더 + #1F1F1F 텍스트.
/// 다크: #131314 배경 + #8E918F 보더 + #E3E3E3 텍스트.
/// G 마크는 항상 4-color 풀 컬러 (가이드라인 필수).
/// 사이즈는 Apple의 macOS intrinsic 높이(약 30pt)에 맞춰 콤팩트하게 — 로고 14, 폰트 12.
private struct GoogleSignInButton: View {
    let colorScheme: ColorScheme
    let action: () -> Void

    private var background: Color {
        colorScheme == .dark
            ? Color(red: 0x13 / 255, green: 0x13 / 255, blue: 0x14 / 255)
            : .white
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color(red: 0x8E / 255, green: 0x91 / 255, blue: 0x8F / 255)
            : Color(red: 0x74 / 255, green: 0x77 / 255, blue: 0x75 / 255)
    }

    private var textColor: Color {
        colorScheme == .dark
            ? Color(red: 0xE3 / 255, green: 0xE3 / 255, blue: 0xE3 / 255)
            : Color(red: 0x1F / 255, green: 0x1F / 255, blue: 0x1F / 255)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(background)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
                HStack(spacing: 8) {
                    Image("GoogleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("Google로 로그인")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor)
                }
                .padding(.horizontal, 10)
            }
        }
        .buttonStyle(.plain)
    }
}
