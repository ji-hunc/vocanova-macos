import SwiftUI

struct OnboardingStepDone: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("준비 완료!")
                .font(.system(size: 22, weight: .bold))

            VStack(alignment: .leading, spacing: 8) {
                Label("어떤 앱에서든 영어 단어를 드래그", systemImage: "1.circle.fill")
                Label("단축키를 누르면 사전 팝업이 떠요", systemImage: "2.circle.fill")
                Label("Google/Apple 로그인 후 단어장에 저장", systemImage: "3.circle.fill")
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                onFinish()
            } label: {
                Text("시작하기")
                    .frame(maxWidth: 200)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
}
