package com.nguyentuanminh.e_app.domain;

/** 4 kỹ năng theo đặc tả — độc lập với {@link LearningCategory}: một mục nội
 * dung bất kỳ (Vocabulary/Grammar/Sentence) có thể được luyện qua bất kỳ kỹ
 * năng nào (vd Trắc nghiệm = Đọc, Dịch câu = Viết), nên kỹ năng được theo dõi
 * ở mức lượt luyện tập ({@link UserSkillStat}) thay vì gắn cố định lên item. */
public enum Skill {
    READING,
    WRITING,
    LISTENING,
    SPEAKING
}
