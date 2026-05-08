import SwiftUI

struct OnboardingStepAccessibility: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text("Accessibility 권한이 필요해요")
                .font(.system(size: 22, weight: .bold))

            Text("VocaNova는 다른 앱에서 선택한 영어 단어를 읽기 위해 macOS의 손쉬운 사용 권한을 사용해요. 권한을 부여해도 키 입력은 저장하지 않아요.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button {
                viewModel.requestAccessibility()
            } label: {
                Text("시스템 설정에서 권한 부여")
                    .frame(maxWidth: 240)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            Text(viewModel.isAXTrusted ? "권한이 부여되었어요!" : "권한을 켠 뒤 자동으로 다음 단계로 넘어가요.")
                .font(.system(size: 11))
                .foregroundStyle(viewModel.isAXTrusted ? .green : .secondary)
                .padding(.bottom, 8)
        }
        .padding(32)
    }
}
