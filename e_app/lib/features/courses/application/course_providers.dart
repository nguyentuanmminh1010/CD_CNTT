import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/graphql_client.dart';
import '../data/course_repository.dart';
import '../domain/course.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.watch(graphQLClientProvider));
});

final coursesProvider = FutureProvider.autoDispose<List<Course>>((ref) {
  return ref.watch(courseRepositoryProvider).fetchCourses();
});

final courseDetailProvider = FutureProvider.autoDispose.family<Course, String>((ref, id) {
  return ref.watch(courseRepositoryProvider).fetchCourse(id);
});

/// Các khoá học đã đăng ký và hoàn thành mọi Unit — mỗi khoá là một giấy chứng nhận.
final certificatesProvider = FutureProvider.autoDispose<List<Course>>((ref) {
  return ref.watch(courseRepositoryProvider).fetchCertificates();
});
