package com.nguyentuanminh.e_app.service;

import java.util.Arrays;
import java.util.List;

/** So khớp văn bản giữa câu người dùng nói và câu mẫu — bản Java của {@code speech_matcher.dart}
 * (cùng thuật toán LCS theo từ, đạt từ 70%) để backend tự chấm bài Luyện nói/Dịch câu. */
public final class SpeechMatcher {

    public static final double PASS_RATIO = 0.7;

    private SpeechMatcher() {
    }

    /** Chữ thường, bỏ dấu câu (giữ nháy đơn trong "don't"), gộp khoảng trắng. */
    public static List<String> words(String text) {
        if (text == null) return List.of();
        String cleaned = text.toLowerCase()
                .replaceAll("[’‘`]", "'")
                .replaceAll("[^a-z0-9'\\s]", " ")
                .trim();
        if (cleaned.isEmpty()) return List.of();
        return Arrays.stream(cleaned.split("\\s+"))
                .map(w -> w.replaceAll("^'+|'+$", ""))
                .filter(w -> !w.isEmpty())
                .toList();
    }

    /** 0..1 = độ dài dãy từ chung dài nhất theo thứ tự / số từ của câu dài hơn. */
    public static double similarity(String spoken, String target) {
        List<String> a = words(spoken);
        List<String> b = words(target);
        if (a.isEmpty() || b.isEmpty()) return 0;
        int[][] dp = new int[a.size() + 1][b.size() + 1];
        for (int i = 1; i <= a.size(); i++) {
            for (int j = 1; j <= b.size(); j++) {
                dp[i][j] = a.get(i - 1).equals(b.get(j - 1))
                        ? dp[i - 1][j - 1] + 1
                        : Math.max(dp[i - 1][j], dp[i][j - 1]);
            }
        }
        return (double) dp[a.size()][b.size()] / Math.max(a.size(), b.size());
    }

    /** Chuẩn hoá cho bài gõ lại: trim, chữ thường, gộp khoảng trắng, bỏ dấu câu cuối câu. */
    public static String normalizeTyped(String s) {
        if (s == null) return "";
        return s.trim().toLowerCase()
                .replaceAll("\\s+", " ")
                .replaceAll("[.,!?;:'“”]+$", "");
    }
}
