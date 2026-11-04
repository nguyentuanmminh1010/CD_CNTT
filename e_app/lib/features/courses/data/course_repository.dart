import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../domain/course.dart';

class CourseRepository {
  CourseRepository(this._client);

  final GraphQLClient _client;

  static const _listFields = '''
    id title description icon enrolled unitCount completedUnits
    totalItems masteredItems completed certified certifiedAt
  ''';

  static const _detailFields = '''
    $_listFields
    units {
      id level position totalItems masteredItems completed locked
      topic { id name description icon category wordCount guide }
    }
    levelResults { level bestPercent attempted passed }
  ''';

  Future<Map<String, dynamic>> _query(String doc, [Map<String, dynamic>? vars]) async {
    final result = await _client.query(QueryOptions(
      document: gql(doc),
      variables: vars ?? const {},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return result.data!;
  }

  Future<List<Course>> fetchCourses() async {
    final data = await _query('query Courses { courses { $_listFields } }');
    return (data['courses'] as List<dynamic>)
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Course> fetchCourse(String id) async {
    final data = await _query(
      'query CourseDetail(\$id: ID!) { course(id: \$id) { $_detailFields } }',
      {'id': id},
    );
    return Course.fromJson(data['course'] as Map<String, dynamic>);
  }

  Future<List<Course>> fetchCertificates() async {
    final data = await _query('query Certificates { certificates { $_listFields } }');
    return (data['certificates'] as List<dynamic>)
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Quản trị (chỉ admin; backend từ chối nếu không có quyền) ----

  Future<Course> _mutate(String doc, Map<String, dynamic> vars, String field) async {
    final result = await _client.mutate(MutationOptions(document: gql(doc), variables: vars));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return Course.fromJson(result.data![field] as Map<String, dynamic>);
  }

  Future<Course> createCourse(String title, String? description) => _mutate(
        'mutation C(\$t: String!, \$d: String) { createCourse(title: \$t, description: \$d) { $_detailFields } }',
        {'t': title, 'd': description},
        'createCourse',
      );

  Future<void> deleteCourse(String id) async {
    final result = await _client.mutate(MutationOptions(
      document: gql('mutation D(\$id: ID!) { deleteCourse(id: \$id) }'),
      variables: {'id': id},
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
  }

  Future<Course> addUnit(String courseId, int level, String topicId) => _mutate(
        'mutation A(\$c: ID!, \$l: Int!, \$t: ID!) { addCourseUnit(courseId: \$c, level: \$l, topicId: \$t) { $_detailFields } }',
        {'c': courseId, 'l': level, 't': topicId},
        'addCourseUnit',
      );

  Future<Course> removeUnit(String unitId) => _mutate(
        'mutation R(\$u: ID!) { removeCourseUnit(unitId: \$u) { $_detailFields } }',
        {'u': unitId},
        'removeCourseUnit',
      );

  Future<Course> enroll(String courseId) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(
        'mutation Enroll(\$courseId: ID!) { enrollCourse(courseId: \$courseId) { $_detailFields } }',
      ),
      variables: {'courseId': courseId},
    ));
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    return Course.fromJson(result.data!['enrollCourse'] as Map<String, dynamic>);
  }
}
