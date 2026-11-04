package com.nguyentuanminh.e_app.domain;

/** Cách chấm một câu trả lời ở backend. */
public enum AnswerMode {
    /** Chọn nghĩa đúng (Trắc nghiệm/Đánh giá/TOEIC/Ôn tập): đáp án = {@code meaning}. */
    MEANING,
    /** Gõ lại thuật ngữ/câu tiếng Anh (Dịch câu): đáp án = {@code term}, bỏ qua hoa-thường/dấu câu cuối. */
    TERM,
    /** Ghép từ thành câu (Sắp xếp câu): đáp án = các từ của {@code example}, đúng thứ tự. */
    SENTENCE,
    /** Câu đã nói (Luyện nói): so khớp từ với {@code term}, đạt từ 70%. */
    SPOKEN
}
