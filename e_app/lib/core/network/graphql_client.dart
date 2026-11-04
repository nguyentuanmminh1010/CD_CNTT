import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql/client.dart';

import 'token_storage.dart';

/// URL backend GraphQL. Mặc định trỏ vào máy dev local (Web/desktop).
/// Android emulator: --dart-define=API_URL=http://10.0.2.2:8080/graphql
/// Điện thoại thật: --dart-define=API_URL=http://`<IP LAN của máy>`:8080/graphql
const String graphqlEndpoint = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080/graphql',
);

final graphQLClientProvider = Provider<GraphQLClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final authLink = AuthLink(
    getToken: () async {
      final token = await tokenStorage.readToken();
      return token == null ? null : 'Bearer $token';
    },
  );
  final httpLink = HttpLink(graphqlEndpoint);

  return GraphQLClient(
    link: authLink.concat(httpLink),
    cache: GraphQLCache(),
  );
});
