import KeyboardShortcuts

/// 사용자가 등록·재바인딩할 수 있는 모든 단축키 이름.
///
/// `Name`을 한 곳에 모아두면 같은 이름을 두 군데서 만들어 silent no-op이 되는 사고를 방지할 수 있다.
extension KeyboardShortcuts.Name {
    /// 선택 텍스트 사전 검색. 기본값 ⌘⇧F.
    static let lookupSelection = Self(
        "lookupSelection",
        default: .init(.f, modifiers: [.command, .shift])
    )
}
