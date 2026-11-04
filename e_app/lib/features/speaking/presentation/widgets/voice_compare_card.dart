import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../vocabulary/application/item_audio.dart';
import '../../application/voice_recorder.dart';

/// "Tự nghe lại": nghe giọng mẫu → ghi âm giọng mình → phát lại để so sánh bằng tai.
/// Ghi âm tách riêng khỏi bước nhận diện giọng nói (tránh tranh chấp micro).
class VoiceCompareCard extends StatefulWidget {
  const VoiceCompareCard({super.key, required this.sample, this.audioUrl});

  /// Câu mẫu cần đọc (TTS hoặc [audioUrl] nếu có).
  final String sample;
  final String? audioUrl;

  @override
  State<VoiceCompareCard> createState() => _VoiceCompareCardState();
}

class _VoiceCompareCardState extends State<VoiceCompareCard> {
  final VoiceRecorder _voice = VoiceRecorder();
  StreamSubscription<PlayerState>? _sub;
  bool _recording = false;
  bool _playing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = _voice.playerState.listen((s) {
      final playing = s.playing && s.processingState != ProcessingState.completed;
      if (mounted && playing != _playing) setState(() => _playing = playing);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    ItemAudio.instance.stop();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _voice.stop();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _error = path == null ? 'Không ghi được âm thanh — hãy thử lại.' : null;
      });
      return;
    }
    await ItemAudio.instance.stop();
    final ok = await _voice.start();
    if (!mounted) return;
    setState(() {
      _recording = ok;
      _error = ok ? null : 'Chưa dùng được micro (hãy cấp quyền micro rồi thử lại).';
    });
  }

  Future<void> _playMine() async {
    if (_playing) {
      await _voice.stopPlayback();
      return;
    }
    final ok = await _voice.play();
    if (!mounted) return;
    if (!ok) setState(() => _error = 'Không phát lại được bản ghi.');
  }

  @override
  Widget build(BuildContext context) {
    final hasRec = _voice.hasRecording && !_recording;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tự nghe lại giọng của bạn',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniButton(
                  icon: Icons.volume_up_rounded,
                  label: 'Nghe mẫu',
                  onTap: _recording
                      ? null
                      : () => ItemAudio.instance.speak(widget.sample, audioUrl: widget.audioUrl),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniButton(
                  icon: _recording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded,
                  label: _recording ? 'Dừng ghi' : 'Ghi âm',
                  color: _recording ? AppColors.error : null,
                  onTap: _toggleRecord,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniButton(
                  icon: _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  label: _playing ? 'Dừng' : 'Phát lại',
                  onTap: hasRec ? _playMine : null,
                ),
              ),
            ],
          ),
          if (_recording) ...[
            const SizedBox(height: 8),
            const Text('Đang ghi âm... đọc câu mẫu rồi bấm "Dừng ghi"',
                style: TextStyle(color: AppColors.error, fontSize: 12.5)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          foregroundColor: c,
          side: BorderSide(color: onTap == null ? AppColors.border : c),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
