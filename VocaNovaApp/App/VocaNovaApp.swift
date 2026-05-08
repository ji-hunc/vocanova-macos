import SwiftUI

/// SwiftUI 앱 엔트리 포인트.
///
/// LSUIElement=true 메뉴바 전용 앱이므로 일반 WindowGroup을 만들지 않는다.
/// 모든 윈도우 라이프사이클은 AppDelegate가 관리한다.
@main
struct VocaNovaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // SwiftUI가 최소 한 개 Scene을 요구하지만 보이는 것은 없어야 한다.
        // Settings scene은 LSUIElement 환경에서 자동으로 표시되지 않는다.
        Settings {
            EmptyView()
        }
    }
}
