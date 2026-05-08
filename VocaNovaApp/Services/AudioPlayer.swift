import AVFoundation
import Foundation

/// 발음 mp3 재생.
///
/// 단일 `AVPlayer` 인스턴스를 유지해 재생 중 GC로 끊기는 일을 방지.
/// (지역 변수로 만든 AVPlayer는 함수 종료와 함께 deinit되어 무음이 되는 흔한 함정.)
@MainActor
final class AudioPlayer {
    private var player: AVPlayer?

    func play(urlString: String) {
        guard let url = URL(string: urlString), !urlString.isEmpty else { return }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        player.play()
    }

    func stop() {
        player?.pause()
        player = nil
    }
}
