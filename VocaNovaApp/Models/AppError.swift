import Foundation

/// 앱 전역 통합 에러.
///
/// 한국어 사용자 메시지를 직접 들고 있어 SwiftUI에서 별도 매핑 없이 표시 가능.
enum AppError: LocalizedError, Equatable {
    case noSelection
    case accessibilityDenied
    case naverHTTP(Int)
    case naverEmpty(String)            // 검색어
    case supabaseHTTP(Int, String)     // status, body 일부
    case authCanceled
    case networkOffline
    case decoding(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .noSelection:
            return "선택된 텍스트가 없어요. 단어를 드래그한 뒤 단축키를 눌러주세요."
        case .accessibilityDenied:
            return "Accessibility 권한이 필요해요. 시스템 설정 → 개인정보 보호 → 손쉬운 사용에서 VocaNova를 켜주세요."
        case .naverHTTP(let code):
            return "사전 서버에서 오류를 반환했어요 (\(code))."
        case .naverEmpty(let q):
            return "‘\(q)’에 대한 검색 결과를 찾지 못했어요."
        case .supabaseHTTP(let code, let body):
            if code == 401 { return "로그인이 만료되었어요. 다시 로그인해주세요." }
            return "단어 저장에 실패했어요 (\(code)). \(body)"
        case .authCanceled:
            return "로그인이 취소되었어요."
        case .networkOffline:
            return "인터넷에 연결되어 있지 않아요."
        case .decoding(let detail):
            return "응답을 해석하지 못했어요. \(detail)"
        case .unknown(let detail):
            return "알 수 없는 오류가 발생했어요. \(detail)"
        }
    }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
