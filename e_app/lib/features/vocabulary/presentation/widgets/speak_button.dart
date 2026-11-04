import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/item_audio.dart';

/// Nút loa tròn: bấm để nghe [text] (file audio của mục nếu có, không thì giọng máy).
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.text, this.audioUrl, this.size = 44, this.color});

  final String text;
  final String? audioUrl;
  final double size;
  final Color? color;

  Future<void> _play(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await ItemAudio.instance.speak(text, audioUrl: audioUrl);
    if (!ok) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Thiết bị này chưa phát được âm thanh.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryDark;
    return ValueListenableBuilder<bool>(
      valueListenable: ItemAudio.instance.speaking,
      builder: (context, speaking, _) => Tooltip(
        message: 'Nghe phát âm',
        child: Material(
          color: c.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            hoverColor: c.withValues(alpha: 0.16),
            onTap: () => speaking ? ItemAudio.instance.stop() : _play(context),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                color: c,
                size: size * 0.55,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
