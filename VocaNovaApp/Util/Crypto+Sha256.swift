import CryptoKit
import Foundation

extension String {
    /// 문자열의 UTF-8 SHA256 해시를 16진 소문자 문자열로 반환.
    /// Apple Sign-In의 nonce 해싱에 사용된다.
    func sha256Hex() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

/// 암호학적으로 안전한 nonce 생성.
enum NonceGenerator {
    /// 길이 `length`의 URL-safe random 문자열.
    /// `Apple` 인증에서는 raw nonce를 그대로 보존하고, request에는 SHA256 해시를 보낸다.
    static func makeRandom(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes failed")
        for byte in bytes {
            result.append(charset[Int(byte) % charset.count])
        }
        return result
    }
}
