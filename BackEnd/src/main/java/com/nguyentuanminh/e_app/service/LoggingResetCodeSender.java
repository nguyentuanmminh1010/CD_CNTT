package com.nguyentuanminh.e_app.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/** Bản dev: KHÔNG gửi email, chỉ in mã ra log máy chủ. Khi triển khai, thêm một bean
 * {@link ResetCodeSender} gửi email thật và đánh dấu {@code @Primary} để thay bản này. */
@Component
public class LoggingResetCodeSender implements ResetCodeSender {

    private static final Logger log = LoggerFactory.getLogger(LoggingResetCodeSender.class);

    @Override
    public void send(String email, String code) {
        log.warn("[DEV] Mã đặt lại mật khẩu cho {}: {} (hiệu lực 15 phút). Chưa cấu hình gửi email thật.", email, code);
    }
}
