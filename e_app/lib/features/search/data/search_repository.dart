import 'package:graphql/client.dart';

import '../../../core/network/graphql_failure.dart';
import '../domain/search_result.dart';

class SearchRepository {
  SearchRepository(this._client);

  final GraphQLClient _client;

  static const _searchQuery = r'''
    query SearchItems($query: String!) {
      searchItems(query: $query) {
        id
        term
        phonetic
        meaning
        example
        difficultyLevel
        topic { id name icon category }
      }
    }
  ''';

  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final result = await _client.query(
      QueryOptions(
        document: gql(_searchQuery),
        variables: {'query': query.trim()},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw GraphQLFailure.fromException(result.exception!);
    final list = result.data!['searchItems'] as List<dynamic>;
    return list.map((e) => SearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }
}
