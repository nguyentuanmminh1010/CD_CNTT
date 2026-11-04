import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../domain/skill_mastery.dart';

class SkillRepository {
  SkillRepository(this._client);

  final GraphQLClient _client;

  static const _skillMasteryQuery = r'''
    query SkillMastery {
      skillMastery { skill totalAttempts correctAttempts }
    }
  ''';

  Future<List<SkillMastery>> fetchSkillMastery() async {
    final result = await _client.query(
      QueryOptions(document: gql(_skillMasteryQuery), fetchPolicy: FetchPolicy.networkOnly),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final list = result.data!['skillMastery'] as List<dynamic>;
    return list.map((e) => SkillMastery.fromJson(e as Map<String, dynamic>)).toList();
  }

}
