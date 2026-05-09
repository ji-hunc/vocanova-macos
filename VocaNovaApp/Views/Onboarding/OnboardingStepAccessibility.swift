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

            // 버튼을 누른 뒤에만 드래그 가이드를 노출 — 첫 인상을 가볍게 유지.
            if viewModel.didOpenSettings {
                dragGuide
            }

            Spacer(minLength: 0)

            Button {
                viewModel.requestAccessibility()
            } label: {
                Text(viewModel.didOpenSettings ? "시스템 설정 다시 열기" : "권한 부여 시작하기")
                    .frame(maxWidth: 280)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            Text(viewModel.isAXTrusted ? "권한이 부여되었어요!" : "권한을 켜면 자동으로 다음 단계로 넘어가요.")
                .font(.system(size: 11))
                .foregroundStyle(viewModel.isAXTrusted ? .green : .secondary)
                .padding(.bottom, 4)
        }
        .padding(32)
    }

    /// macOS 15+에서 Apple Development 서명 sandbox 앱은 prompt-path 자동 등록이
    /// 막혀 있으므로, 사용자가 직접 + 버튼으로 .app을 손쉬운 사용 목록에 추가해야 한다.
    /// 이 카드가 그 단계를 명확히 안내한다.
    private var dragGuide: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(Theme.accent)
                Text("이렇게 추가해주세요")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
            }
            stepRow("1", "방금 열린 시스템 설정의 ‘손쉬운 사용’ 목록 아래쪽")
            stepRow("2", "+ 버튼을 눌러 VocaNova를 선택해 추가")
            stepRow("3", "추가된 VocaNova의 토글을 켜주세요")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.exampleBg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 24)
    }

    private func stepRow(_ index: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(index)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 14, alignment: .leading)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
