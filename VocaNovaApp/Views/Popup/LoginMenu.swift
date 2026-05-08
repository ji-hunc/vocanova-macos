import AuthenticationServices
import SwiftUI

/// 미로그인 상태에서 "단어장에 저장"을 누르면 표시되는 인라인 카드.
struct LoginMenu: View {
    @ObservedObject var auth: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("로그인하고 단어를 저장하세요")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.tertiaryText)
                }
                .buttonStyle(.plain)
            }

            Text("크롬 익스텐션·iOS 앱과 같은 계정으로 단어장이 동기화돼요.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            // Apple Sign-In은 시스템 표준 버튼이 디자인 가이드 — 가로 폭 채워서 노출.
            SignInWithAppleButton(.continue) { _ in
                // Configure는 SupabaseAuthService 안에서 처리하므로 여기 콜백은 사용 안 함.
            } onCompletion: { _ in
                // 동일.
            }
            .frame(height: 32)
            // 다크에선 흰 외곽선 스타일이 Apple HIG 권장 — 검정은 어두운 배경에 묻힘.
            .signInWithAppleButtonStyle(colorScheme == .dark ? .whiteOutline : .black)
            .overlay(
                // 시스템 콜백 대신 우리 인증 플로우 사용.
                Button {
                    Task { await auth.signInWithApple() }
                } label: {
                    Color.clear
                }
                .buttonStyle(.plain)
            )

            Button {
                Task { await auth.signInWithGoogle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 12, weight: .medium))
                    Text("Google로 로그인")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(Theme.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if let err = auth.errorMessage {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
            if auth.isWorking {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.mini)
                    Text("로그인 중…")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}
