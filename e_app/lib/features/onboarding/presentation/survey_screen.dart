import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../application/survey_controller.dart';
import 'widgets/start_mode_card.dart';
import 'widgets/sumo_bubble.dart';
import 'widgets/survey_option_tile.dart';
import 'widgets/survey_scaffold.dart';

const _totalSteps = 4;

class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  int _step = 0;
  bool _submitting = false;

  void _goBack() {
    if (_step == 0) {
      context.go(AppRoutes.signup);
    } else {
      setState(() => _step -= 1);
    }
  }

  Future<void> _goNext() async {
    if (_step == _totalSteps - 1) {
      await _submitSurvey();
    } else {
      setState(() => _step += 1);
    }
  }

  Future<void> _submitSurvey() async {
    final answers = ref.read(surveyControllerProvider);
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            displayName: answers.name.trim(),
            dob: answers.dob,
            gender: answers.gender?.apiValue,
            learningPurpose: answers.purpose?.apiValue,
            dailyMinutes: answers.dailyMinutes,
            startMode: answers.startMode?.apiValue,
          );
      if (mounted) {
        context.go(
          answers.startMode == StartMode.placementTest
              ? AppRoutes.placementTest
              : AppRoutes.home,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Không lưu được thông tin khảo sát: $e'),
            backgroundColor: AppColors.error,
          ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final answers = ref.watch(surveyControllerProvider);
    final controller = ref.read(surveyControllerProvider.notifier);

    late final Widget content;
    late final String buttonLabel;
    late final bool canContinue;

    switch (_step) {
      case 0:
        content = _BasicInfoStep(answers: answers, controller: controller);
        buttonLabel = 'Tiếp tục';
        canContinue = answers.isBasicInfoValid;
        break;
      case 1:
        content = _PurposeStep(answers: answers, controller: controller);
        buttonLabel = 'Tiếp tục';
        canContinue = answers.purpose != null;
        break;
      case 2:
        content = _DailyTimeStep(answers: answers, controller: controller);
        buttonLabel = 'Tiếp tục';
        canContinue = answers.dailyMinutes != null;
        break;
      default:
        content = _StartModeStep(answers: answers, controller: controller);
        buttonLabel = _submitting ? 'Đang lưu...' : 'Bắt đầu';
        canContinue = answers.startMode != null;
    }

    return SurveyScaffold(
      step: _step,
      totalSteps: _totalSteps,
      onBack: _submitting ? null : _goBack,
      buttonLabel: buttonLabel,
      onContinue: canContinue && !_submitting ? _goNext : null,
      child: content,
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  const _BasicInfoStep({required this.answers, required this.controller});

  final SurveyAnswers answers;
  final SurveyController controller;

  Future<void> _pickDob(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) controller.setDob(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SumoBubble(
          message: 'Điền thêm thông tin để chúng tôi hiểu hơn về bạn!',
        ),
        const SizedBox(height: 28),
        Text('Chúng tôi có thể gọi bạn là gì?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          onChanged: controller.setName,
          decoration: const InputDecoration(hintText: 'Tên của bạn'),
        ),
        const SizedBox(height: 24),
        Text('Ngày sinh của bạn:', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pickDob(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  answers.dob == null
                      ? 'DD / MM / YYYY'
                      : '${answers.dob!.day.toString().padLeft(2, '0')} / '
                          '${answers.dob!.month.toString().padLeft(2, '0')} / '
                          '${answers.dob!.year}',
                  style: TextStyle(
                    color: answers.dob == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Giới tính:', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GenderChip(
                label: 'Nam',
                selected: answers.gender == Gender.male,
                onTap: () => controller.setGender(Gender.male),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderChip(
                label: 'Nữ',
                selected: answers.gender == Gender.female,
                onTap: () => controller.setGender(Gender.female),
              ),
            ),
          ],
        ),
        if (answers.isBasicInfoValid) ...[
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng ký thành công!',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trả lời thêm một số câu hỏi cơ bản để hoàn thành cài đặt tài khoản.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PurposeStep extends StatelessWidget {
  const _PurposeStep({required this.answers, required this.controller});

  final SurveyAnswers answers;
  final SurveyController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SumoBubble(
          message: 'Bạn học tiếng Anh để phục vụ cho điều gì?',
        ),
        const SizedBox(height: 28),
        for (final purpose in LearningPurpose.values)
          SurveyOptionTile(
            label: purpose.label,
            selected: answers.purpose == purpose,
            onTap: () => controller.setPurpose(purpose),
          ),
      ],
    );
  }
}

class _DailyTimeStep extends StatelessWidget {
  const _DailyTimeStep({required this.answers, required this.controller});

  final SurveyAnswers answers;
  final SurveyController controller;

  static const _options = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SumoBubble(
          message: 'Thời gian học tập hàng ngày của bạn là:',
        ),
        const SizedBox(height: 28),
        for (final minutes in _options)
          SurveyOptionTile(
            label: '$minutes phút/ngày',
            selected: answers.dailyMinutes == minutes,
            onTap: () => controller.setDailyMinutes(minutes),
          ),
      ],
    );
  }
}

class _StartModeStep extends StatelessWidget {
  const _StartModeStep({required this.answers, required this.controller});

  final SurveyAnswers answers;
  final SurveyController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SumoBubble(
          message: 'Bạn muốn bắt đầu học cùng SUMO thế nào?',
        ),
        const SizedBox(height: 28),
        StartModeCard(
          icon: Icons.rocket_launch_rounded,
          iconBackground: AppColors.accentBlue,
          title: StartMode.fromScratch.title,
          description: StartMode.fromScratch.description,
          selected: answers.startMode == StartMode.fromScratch,
          onTap: () => controller.setStartMode(StartMode.fromScratch),
        ),
        StartModeCard(
          icon: Icons.fact_check_rounded,
          iconBackground: AppColors.primary,
          title: StartMode.placementTest.title,
          description: StartMode.placementTest.description,
          selected: answers.startMode == StartMode.placementTest,
          onTap: () => controller.setStartMode(StartMode.placementTest),
        ),
      ],
    );
  }
}
