import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Gender { male, female }

/// Giá trị enum tương ứng ở GraphQL schema (`Gender`) — dùng khi gửi khảo sát
/// lên `User` qua mutation `updateProfile`.
extension GenderApi on Gender {
  String get apiValue => this == Gender.male ? 'MALE' : 'FEMALE';
}

enum LearningPurpose {
  none('Không gì cả'),
  study('Học tập'),
  work('Công việc'),
  dailyCommunication('Giao tiếp hàng ngày'),
  makeFriends('Kết bạn bốn phương'),
  other('Khác');

  const LearningPurpose(this.label);
  final String label;
}

/// Giá trị enum tương ứng ở GraphQL schema (`LearningPurpose`).
extension LearningPurposeApi on LearningPurpose {
  String get apiValue => switch (this) {
        LearningPurpose.none => 'NONE',
        LearningPurpose.study => 'STUDY',
        LearningPurpose.work => 'WORK',
        LearningPurpose.dailyCommunication => 'DAILY_COMMUNICATION',
        LearningPurpose.makeFriends => 'MAKE_FRIENDS',
        LearningPurpose.other => 'OTHER',
      };
}

enum StartMode {
  fromScratch(
    title: 'Bắt đầu từ đầu',
    description: 'Bắt đầu trải nghiệm học tập cùng SUMO ngay bây giờ.',
  ),
  placementTest(
    title: 'Học đúng trình độ',
    description:
        'Làm một bài kiểm tra ngắn để bỏ qua các bài học trình độ thấp hơn.',
  );

  const StartMode({required this.title, required this.description});
  final String title;
  final String description;
}

/// Giá trị enum tương ứng ở GraphQL schema (`StartMode`).
extension StartModeApi on StartMode {
  String get apiValue =>
      this == StartMode.fromScratch ? 'FROM_SCRATCH' : 'PLACEMENT_TEST';
}

class SurveyAnswers {
  const SurveyAnswers({
    this.name = '',
    this.dob,
    this.gender,
    this.purpose,
    this.dailyMinutes,
    this.startMode,
  });

  final String name;
  final DateTime? dob;
  final Gender? gender;
  final LearningPurpose? purpose;
  final int? dailyMinutes;
  final StartMode? startMode;

  bool get isBasicInfoValid => name.trim().isNotEmpty && dob != null && gender != null;

  SurveyAnswers copyWith({
    String? name,
    DateTime? dob,
    Gender? gender,
    LearningPurpose? purpose,
    int? dailyMinutes,
    StartMode? startMode,
  }) {
    return SurveyAnswers(
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      purpose: purpose ?? this.purpose,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      startMode: startMode ?? this.startMode,
    );
  }
}

class SurveyController extends Notifier<SurveyAnswers> {
  @override
  SurveyAnswers build() => const SurveyAnswers();

  void setName(String name) => state = state.copyWith(name: name);

  void setDob(DateTime dob) => state = state.copyWith(dob: dob);

  void setGender(Gender gender) => state = state.copyWith(gender: gender);

  void setPurpose(LearningPurpose purpose) =>
      state = state.copyWith(purpose: purpose);

  void setDailyMinutes(int minutes) =>
      state = state.copyWith(dailyMinutes: minutes);

  void setStartMode(StartMode mode) => state = state.copyWith(startMode: mode);
}

final surveyControllerProvider =
    NotifierProvider<SurveyController, SurveyAnswers>(SurveyController.new);
