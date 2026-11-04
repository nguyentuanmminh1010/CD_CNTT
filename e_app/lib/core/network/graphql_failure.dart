import 'package:graphql/client.dart';

/// Lỗi nghiệp vụ đọc được từ GraphQL (message do backend trả về qua
/// GraphQlExceptionResolver), phù hợp để hiển thị thẳng cho người dùng.
class GraphQLFailure implements Exception {
  const GraphQLFailure(this.message);

  final String message;

  factory GraphQLFailure.fromException(OperationException exception) {
    final graphqlErrors = exception.graphqlErrors;
    if (graphqlErrors.isNotEmpty) {
      return GraphQLFailure(graphqlErrors.first.message);
    }
    if (exception.linkException != null) {
      return const GraphQLFailure(
        'Không kết nối được tới máy chủ. Kiểm tra backend đang chạy chưa.',
      );
    }
    return const GraphQLFailure('Đã có lỗi xảy ra. Vui lòng thử lại.');
  }

  @override
  String toString() => message;
}
