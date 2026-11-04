import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/practice/application/practice_launchers.dart';
import '../../features/practice/domain/practice_models.dart';
import '../../features/practice/presentation/practice_session_screen.dart';
import '../../features/onboarding/presentation/survey_screen.dart';
import '../../features/assessments/domain/assessment_test.dart';
import '../../features/assessments/presentation/assessment_intro_screen.dart';
import '../../features/assessments/presentation/assessment_quiz_screen.dart';
import '../../features/attempts/domain/attempt.dart';
import '../../features/attempts/presentation/attempt_detail_screen.dart';
import '../../features/attempts/presentation/attempt_history_screen.dart';
import '../../features/admin/presentation/admin_course_edit_screen.dart';
import '../../features/admin/presentation/admin_courses_screen.dart';
import '../../features/courses/domain/course.dart';
import '../../features/listening/presentation/dictation_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/social/friends_screen.dart';
import '../../features/decks/presentation/admin_topics_screen.dart';
import '../../features/decks/presentation/deck_edit_screen.dart';
import '../../features/decks/presentation/my_decks_screen.dart';
import '../../features/vocabulary/domain/vocabulary_models.dart';
import '../../features/courses/domain/level_test_args.dart';
import '../../features/courses/presentation/lesson_detail_screen.dart';
import '../../features/speaking/presentation/speaking_practice_screen.dart';
import '../../features/courses/presentation/course_detail_screen.dart';
import '../../features/courses/presentation/courses_screen.dart';
import '../../features/collection/presentation/all_topics_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/skills/domain/skill_type.dart';
import '../../features/skills/presentation/translate_quiz_screen.dart';
import '../../features/review/domain/wrong_item.dart';
import '../../features/review/presentation/review_mistakes_screen.dart';
import '../../features/review/presentation/review_quiz_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/toeic/presentation/toeic_practice_screen.dart';
import '../../features/vocabulary/presentation/flashcard_study_screen.dart';
import '../../features/vocabulary/presentation/vocabulary_topics_screen.dart';
import '../../features/grammar/presentation/grammar_flashcard_screen.dart';
import '../../features/grammar/presentation/grammar_topics_screen.dart';
import '../../features/sentences/presentation/sentence_flashcard_screen.dart';
import '../../features/sentences/presentation/sentence_topics_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const survey = '/survey';
  static const home = '/home';
  static const reviewMistakes = '/review-mistakes';
  static const reviewQuiz = '/review-quiz';
  static const allTopics = '/all-topics';
  static const search = '/search';
  static const toeicPractice = '/toeic-practice';
  static const assessmentQuiz = '/assessment-quiz';
  static const placementTest = '/placement-test';
  static const assessmentIntro = '/assessment-intro';
  static const levelTest = '/level-test';
  static const lesson = '/lesson';
  static const myDecks = '/my-decks';
  static const deck = '/deck';
  static const adminTopics = '/admin/topics';
  static const forgotPassword = '/forgot-password';
  static const notifications = '/notifications';
  static const friends = '/friends';
  static const speakingPractice = '/speaking-practice';
  static const listeningPractice = '/listening-practice';
  static const adminCourses = '/admin/courses';
  static const attemptHistory = '/attempt-history';
  static const courses = '/courses';
  static const readingPractice = '/reading-practice';
  static const writingPractice = '/writing-practice';
  static const vocabulary = '/vocabulary';
  static const grammar = '/grammar';
  static const sentences = '/sentences';
}

const _publicPaths = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.forgotPassword,
};

/// Router phụ thuộc vào trạng thái đăng nhập: mọi route ngoài danh sách công
/// khai ở trên đều yêu cầu đã đăng nhập, nếu không sẽ bị đưa về `/login`.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final isLoggedIn = auth.valueOrNull != null;
      final isPublic = _publicPaths.contains(state.matchedLocation);
      // Reload thẳng ở một route sâu: token đã lưu chưa kịp đọc nên auth còn
      // đang loading — về splash (nơi chờ xác thực xong rồi tự vào /home hoặc
      // /onboarding) thay vì đá nhầm về /login dù token vẫn hợp lệ.
      if (!isPublic && auth.isLoading) {
        return AppRoutes.splash;
      }
      if (!isPublic && !isLoggedIn) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.survey,
        builder: (context, state) => const SurveyScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: AppRoutes.reviewMistakes,
        builder: (context, state) => const ReviewMistakesScreen(),
      ),
      GoRoute(
        path: AppRoutes.reviewQuiz,
        builder: (context, state) {
          final items = state.extra! as List<WrongItem>;
          return ReviewQuizScreen(items: items);
        },
      ),
      GoRoute(
        path: AppRoutes.allTopics,
        builder: (context, state) => const AllTopicsScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.toeicPractice,
        builder: (context, state) => const ToeicPracticeScreen(),
      ),
      GoRoute(
        path: AppRoutes.assessmentQuiz,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is AssessmentTest) {
            return AssessmentQuizScreen(category: extra.category, test: extra);
          }
          return AssessmentQuizScreen(category: extra as ReviewCategory?);
        },
      ),
      GoRoute(
        path: AppRoutes.lesson,
        builder: (context, state) => LessonDetailScreen(unit: state.extra! as CourseUnit),
      ),
      GoRoute(
        path: AppRoutes.speakingPractice,
        builder: (context, state) => const SpeakingPracticeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCourses,
        builder: (context, state) => const AdminCoursesScreen(),
        routes: [
          GoRoute(
            path: ':courseId',
            builder: (context, state) =>
                AdminCourseEditScreen(courseId: state.pathParameters['courseId']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.listeningPractice,
        builder: (context, state) => const DictationScreen(),
      ),
      GoRoute(
        path: AppRoutes.friends,
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: AppRoutes.myDecks,
        builder: (context, state) => const MyDecksScreen(),
      ),
      GoRoute(
        path: AppRoutes.deck,
        builder: (context, state) => DeckEditScreen(topic: state.extra! as VocabularyTopic),
      ),
      GoRoute(
        path: AppRoutes.adminTopics,
        builder: (context, state) => const AdminTopicsScreen(),
      ),
      GoRoute(
        path: AppRoutes.levelTest,
        builder: (context, state) => AssessmentQuizScreen(
          category: null,
          screenTitle: 'Level Test',
          levelTest: state.extra! as LevelTestArgs,
        ),
      ),
      GoRoute(
        path: AppRoutes.assessmentIntro,
        builder: (context, state) =>
            AssessmentIntroScreen(test: state.extra! as AssessmentTest),
      ),
      GoRoute(
        path: '/attempt/:id',
        builder: (context, state) => AttemptDetailScreen(
          attemptId: state.pathParameters['id']!,
          attempt: state.extra as Attempt?,
        ),
      ),
      GoRoute(
        path: AppRoutes.attemptHistory,
        builder: (context, state) => const AttemptHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.courses,
        builder: (context, state) => const CoursesScreen(),
        routes: [
          GoRoute(
            path: ':courseId',
            builder: (context, state) =>
                CourseDetailScreen(courseId: state.pathParameters['courseId']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.placementTest,
        builder: (context, state) => AssessmentQuizScreen(
          category: null,
          screenTitle: 'Kiểm tra xếp lớp',
          onExit: () => context.go(AppRoutes.home),
        ),
      ),
      GoRoute(
        path: AppRoutes.readingPractice,
        builder: (context, state) => const AssessmentQuizScreen(
          category: null,
          screenTitle: 'Luyện Đọc',
          skill: SkillType.reading,
        ),
      ),
      GoRoute(
        path: AppRoutes.writingPractice,
        builder: (context, state) => const TranslateQuizScreen(),
      ),
      GoRoute(
        path: AppRoutes.vocabulary,
        builder: (context, state) => const VocabularyTopicsScreen(),
        routes: [
          GoRoute(
            path: ':topicId',
            builder: (context, state) => FlashcardStudyScreen(
              topicId: state.pathParameters['topicId']!,
              topicName: (state.extra as String?) ?? 'Vocabulary',
            ),
          ),
          GoRoute(
            path: ':topicId/practice/:kind',
            builder: (context, state) => PracticeSessionScreen(
              config: topicPracticeConfig(
                category: ReviewCategory.vocabulary,
                topicId: state.pathParameters['topicId']!,
                topicName: (state.extra as String?) ?? 'Vocabulary',
                kind: practiceKindFromSlug(state.pathParameters['kind']),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.grammar,
        builder: (context, state) => const GrammarTopicsScreen(),
        routes: [
          GoRoute(
            path: ':topicId',
            builder: (context, state) => GrammarFlashcardScreen(
              topicId: state.pathParameters['topicId']!,
              topicName: (state.extra as String?) ?? 'Grammar',
            ),
          ),
          GoRoute(
            path: ':topicId/practice/:kind',
            builder: (context, state) => PracticeSessionScreen(
              config: topicPracticeConfig(
                category: ReviewCategory.grammar,
                topicId: state.pathParameters['topicId']!,
                topicName: (state.extra as String?) ?? 'Grammar',
                kind: practiceKindFromSlug(state.pathParameters['kind']),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.sentences,
        builder: (context, state) => const SentenceTopicsScreen(),
        routes: [
          GoRoute(
            path: ':topicId',
            builder: (context, state) => SentenceFlashcardScreen(
              topicId: state.pathParameters['topicId']!,
              topicName: (state.extra as String?) ?? 'Sentences',
            ),
          ),
          GoRoute(
            path: ':topicId/practice/:kind',
            builder: (context, state) => PracticeSessionScreen(
              config: topicPracticeConfig(
                category: ReviewCategory.sentence,
                topicId: state.pathParameters['topicId']!,
                topicName: (state.extra as String?) ?? 'Sentences',
                kind: practiceKindFromSlug(state.pathParameters['kind']),
              ),
            ),
          ),
        ],
      ),
    ],
  );
});
