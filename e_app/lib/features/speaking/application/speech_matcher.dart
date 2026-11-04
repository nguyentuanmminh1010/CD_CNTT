// So khớp văn bản đơn giản giữa câu người dùng nói (kết quả `speech_to_text`)
// và câu mẫu — giải pháp giai đoạn 1 theo CLAUDE.md (on-device, không chấm
// phát âm/fluency chi tiết). So theo TỪ, bỏ qua hoa-thường và dấu câu.

/// Tỉ lệ từ khớp tối thiểu để coi là nói đúng.
const speechPassRatio = 0.7;

/// Chuẩn hoá: chữ thường, bỏ dấu câu (giữ nháy đơn trong "don't"), gộp khoảng trắng.
List<String> speechWords(String text) {
  final cleaned = text
      .toLowerCase()
      .replaceAll(RegExp(r"[’‘`]"), "'")
      .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
      .trim();
  if (cleaned.isEmpty) return const [];
  return cleaned.split(RegExp(r'\s+')).map((w) => w.replaceAll(RegExp(r"^'+|'+$"), '')).where((w) => w.isNotEmpty).toList();
}

/// Độ tương đồng 0..1 = (độ dài dãy từ chung dài nhất theo đúng thứ tự) / (số từ
/// của câu mẫu hoặc câu nói, lấy số lớn hơn) — nói thừa hay thiếu từ đều bị trừ điểm.
double speechSimilarity(String spoken, String target) {
  final a = speechWords(spoken);
  final b = speechWords(target);
  if (a.isEmpty || b.isEmpty) return 0;
  final dp = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      dp[i][j] = a[i - 1] == b[j - 1]
          ? dp[i - 1][j - 1] + 1
          : (dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]);
    }
  }
  final longest = a.length > b.length ? a.length : b.length;
  return dp[a.length][b.length] / longest;
}

bool isSpeechCorrect(String spoken, String target) =>
    speechSimilarity(spoken, target) >= speechPassRatio;

/// Một từ của câu mẫu kèm trạng thái đã được nói đúng hay chưa.
class WordMatch {
  const WordMatch(this.word, this.matched);

  final String word;
  final bool matched;
}

/// Đối chiếu từng từ của [target] với câu [spoken] (cùng dãy con chung dài nhất như
/// [speechSimilarity]) để chỉ ra từ nào bị bỏ sót/nói sai — dùng tô màu ở màn Luyện Nói.
List<WordMatch> compareWords(String spoken, String target) {
  final a = speechWords(spoken);
  final b = speechWords(target);
  final dp = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      dp[i][j] = a[i - 1] == b[j - 1]
          ? dp[i - 1][j - 1] + 1
          : (dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]);
    }
  }
  final matched = List.filled(b.length, false);
  var i = a.length, j = b.length;
  while (i > 0 && j > 0) {
    if (a[i - 1] == b[j - 1]) {
      matched[j - 1] = true;
      i--;
      j--;
    } else if (dp[i - 1][j] >= dp[i][j - 1]) {
      i--;
    } else {
      j--;
    }
  }
  return [for (var k = 0; k < b.length; k++) WordMatch(b[k], matched[k])];
}

/// Tốc độ nói (từ/phút) từ số từ đã nhận diện và thời gian nói; null nếu quá ngắn để ước lượng.
int? speakingPace(String spoken, Duration elapsed) {
  final words = speechWords(spoken).length;
  if (words < 3 || elapsed.inMilliseconds < 1200) return null;
  return (words * 60000 / elapsed.inMilliseconds).round();
}

/// Nhãn nhận xét độ trôi chảy theo [speakingPace] (ngưỡng ước lượng, không phải chấm chuẩn).
String paceLabel(int wpm) {
  if (wpm < 70) return 'hơi chậm — thử nói liền mạch hơn';
  if (wpm > 190) return 'hơi nhanh — thử nói rõ từng từ';
  return 'tốc độ tự nhiên';
}
