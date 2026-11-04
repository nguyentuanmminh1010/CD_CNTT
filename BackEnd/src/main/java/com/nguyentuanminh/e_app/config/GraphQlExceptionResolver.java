package com.nguyentuanminh.e_app.config;

import graphql.GraphQLError;
import graphql.GraphqlErrorBuilder;
import graphql.schema.DataFetchingEnvironment;
import java.util.NoSuchElementException;
import org.springframework.graphql.execution.DataFetcherExceptionResolverAdapter;
import org.springframework.graphql.execution.ErrorType;
import org.springframework.stereotype.Component;

/**
 * Chuyển các exception nghiệp vụ mong đợi (email trùng, sai mật khẩu, chưa
 * đăng nhập, chưa cấu hình OAuth...) thành thông báo lỗi GraphQL có message rõ
 * ràng cho client, thay vì bị Spring GraphQL che thành "INTERNAL_ERROR" chung
 * chung (mặc định chỉ lộ message của lỗi hệ thống thật ra ngoài).
 */
@Component
public class GraphQlExceptionResolver extends DataFetcherExceptionResolverAdapter {

    @Override
    protected GraphQLError resolveToSingleError(Throwable ex, DataFetchingEnvironment env) {
        ErrorType errorType = switch (ex) {
            case IllegalArgumentException ignored -> ErrorType.BAD_REQUEST;
            case NoSuchElementException ignored -> ErrorType.NOT_FOUND;
            case IllegalStateException ignored -> ErrorType.UNAUTHORIZED;
            default -> null;
        };
        if (errorType == null) {
            return null; // để mặc định che thành INTERNAL_ERROR cho lỗi hệ thống thật
        }
        return GraphqlErrorBuilder.newError(env)
                .errorType(errorType)
                .message(ex.getMessage())
                .build();
    }
}
