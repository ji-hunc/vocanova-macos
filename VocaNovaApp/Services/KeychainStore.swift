import Foundation
import Security

/// Generic Password 키체인 항목 래퍼.
///
/// 이유: Supabase access_token / refresh_token은 만료 시간이 있어도 디스크에 평문 저장하면 안 됨.
/// UserDefaults는 평문이며 백업에 노출되므로 Keychain 사용.
final class KeychainStore {
    let service: String

    init(service: String) {
        self.service = service
    }

    /// 데이터 저장. 같은 account가 있으면 덮어쓰기.
    func setData(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        // 우선 update 시도, 없으면 add.
        let updateStatus = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            for (k, v) in attrs { addQuery[k] = v }
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw AppError.unknown("키체인 저장 실패 (\(addStatus))")
            }
        } else if updateStatus != errSecSuccess {
            throw AppError.unknown("키체인 갱신 실패 (\(updateStatus))")
        }
    }

    /// 데이터 조회. 없으면 nil.
    func getData(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        if status != errSecSuccess {
            throw AppError.unknown("키체인 조회 실패 (\(status))")
        }
        return result as? Data
    }

    /// 항목 삭제.
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AppError.unknown("키체인 삭제 실패 (\(status))")
        }
    }
}

/// Codable 편의 확장.
extension KeychainStore {
    func setCodable<T: Encodable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        try setData(data, forKey: key)
    }

    func getCodable<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try getData(forKey: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
}
