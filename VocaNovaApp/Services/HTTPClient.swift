import Foundation

/// 가벼운 URLSession 래퍼.
///
/// Supabase / Naver 두 endpoint 모두 같은 클라이언트를 쓰지만 디코더 전략은 다르다:
/// - Supabase: `convertFromSnakeCase`
/// - Naver:    기본 키 (이미 camelCase)
///
/// JSONEncoder/Decoder는 Swift 동시성 안전이 아니므로 actor 안에 가두지 않고 함수 내부에서
/// 매번 인스턴스를 만든다 (싸다).
actor HTTPClient {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    // MARK: - 기본

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AppError.unknown("응답이 HTTP가 아님")
            }
            return (data, http)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw AppError.networkOffline
        } catch let error as URLError where error.code == .timedOut {
            throw AppError.unknown("요청이 시간 초과되었어요.")
        }
    }

    // MARK: - 헬퍼

    /// 응답 바디를 디코드. snake_case 변환 여부는 호출자가 지정.
    func decode<T: Decodable>(_ type: T.Type,
                              from data: Data,
                              snakeCase: Bool) throws -> T {
        let decoder = JSONDecoder()
        if snakeCase {
            decoder.keyDecodingStrategy = .convertFromSnakeCase
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let preview = String(data: data.prefix(200), encoding: .utf8) ?? "<binary>"
            Log.network.error("decode failed for \(String(describing: T.self)): \(error.localizedDescription, privacy: .public) — body: \(preview, privacy: .public)")
            throw AppError.decoding(error.localizedDescription)
        }
    }

    func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        // Naver / Supabase 모두 camelCase 그대로 보내면 됨 (RPC 인자명은 p_xxx 형태로 직접 명명).
        return try encoder.encode(value)
    }
}
