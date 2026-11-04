import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Ghi âm giọng người dùng (`record`) rồi phát lại (`just_audio`) để so với giọng mẫu.
/// Không chạy cùng lúc với nhận diện giọng nói (`speech_to_text`) để tránh tranh chấp micro
/// trên Android — người dùng ghi âm trong một bước riêng.
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  /// Đường dẫn/URL bản ghi gần nhất (blob URL trên web, file tạm trên di động).
  String? lastPath;

  bool get hasRecording => lastPath != null;

  Stream<PlayerState> get playerState => _player.playerStateStream;

  /// Bắt đầu ghi. Trả về false nếu chưa được cấp quyền micro hoặc thiết bị không ghi được.
  Future<bool> start() async {
    try {
      await _player.stop();
      if (!await _recorder.hasPermission()) return false;
      // Web ghi ra blob (đường dẫn rỗng); di động ghi file tạm trong thư mục tạm của ứng dụng.
      if (kIsWeb) {
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.opus), path: '');
      } else {
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: await _tempPath());
      }
      return true;
    } catch (e) {
      debugPrint('Ghi âm thất bại: $e');
      return false;
    }
  }

  /// Dừng ghi và lưu đường dẫn bản ghi; trả về null nếu không có dữ liệu.
  Future<String?> stop() async {
    try {
      final path = await _recorder.stop();
      lastPath = (path == null || path.isEmpty) ? null : path;
      return lastPath;
    } catch (e) {
      debugPrint('Dừng ghi âm thất bại: $e');
      return null;
    }
  }

  Future<bool> isRecording() => _recorder.isRecording();

  /// Phát lại bản ghi gần nhất; hoàn tất khi phát xong. Trả về false nếu không phát được.
  Future<bool> play() async {
    final path = lastPath;
    if (path == null) return false;
    try {
      if (kIsWeb || path.startsWith('blob:') || path.startsWith('http')) {
        await _player.setUrl(path);
      } else {
        await _player.setFilePath(path);
      }
      await _player.seek(Duration.zero);
      await _player.play();
      return true;
    } catch (e) {
      debugPrint('Phát lại bản ghi thất bại: $e');
      return false;
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Dừng phát lại thất bại: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _recorder.dispose();
      await _player.dispose();
    } catch (_) {}
  }

  Future<String> _tempPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/learn_e_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }
}
