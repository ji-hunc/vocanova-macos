import SwiftUI

/// 팝업의 최상위 SwiftUI 컨테이너.
///
/// `PopupWindowController`가 NSHostingView로 마운트하는 루트.
/// 상태에 따라 로딩/카드/에러 화면 분기.
struct PopupContainer: View {
    @ObservedObject var popup: PopupViewModel
    @ObservedObject var auth: AuthViewModel
    @ObservedObject var session: SessionStore
    let audio: AudioPlayer
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Theme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                content
            }
            .padding(Theme.cardPadding)
            .frame(width: Config.popupWidth, alignment: .topLeading)
            .frame(maxHeight: Config.popupMaxHeight, alignment: .top)
        }
        .frame(width: Config.popupWidth)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 6)
    }

    @ViewBuilder
    private var content: some View {
        switch popup.loadState {
        case .idle, .loading:
            PopupLoadingView()
                .frame(minHeight: 100)
        case .loaded(let snapshot):
            ScrollView {
                PopupView(
                    snapshot: snapshot,
                    popup: popup,
                    auth: auth,
                    session: session,
                    audio: audio
                )
            }
            .scrollIndicators(.hidden)
        case .notFound(let q):
            PopupErrorView(title: "결과를 찾지 못했어요",
                           message: "‘\(q)’에 대한 사전 결과가 없어요. 철자를 확인해보세요.",
                           onRetry: nil,
                           onClose: onClose)
        case .error(let msg):
            PopupErrorView(title: "오류",
                           message: msg,
                           onRetry: { popup.retry() },
                           onClose: onClose)
        }
    }
}
