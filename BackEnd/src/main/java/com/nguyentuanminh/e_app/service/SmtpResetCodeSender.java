package com.nguyentuanminh.e_app.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

/**
 * Gửi mã đặt lại mật khẩu qua email thật (SMTP). Chỉ được tạo khi có {@code spring.mail.host}
 * (đặt trong {@code application-local.properties} hoặc biến môi trường {@code SPRING_MAIL_HOST},
 * {@code SPRING_MAIL_PORT}, {@code SPRING_MAIL_USERNAME}, {@code SPRING_MAIL_PASSWORD}); khi đó nó thay
 * {@link LoggingResetCodeSender}. Người gửi lấy từ {@code app.mail.from} (mặc định = username SMTP).
 *
 * <p>Nếu gửi lỗi, không ném ra ngoài (tránh lộ email có tồn tại hay không qua việc báo lỗi) — chỉ ghi log.
 */
@Component
@Primary
@ConditionalOnProperty(name = "spring.mail.host")
public class SmtpResetCodeSender implements ResetCodeSender {

    private static final Logger log = LoggerFactory.getLogger(SmtpResetCodeSender.class);

    private final JavaMailSender mailSender;
    private final String from;

    public SmtpResetCodeSender(
            JavaMailSender mailSender,
            @Value("${app.mail.from:${spring.mail.username:no-reply@learn-e.local}}") String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    @Override
    public void send(String email, String code) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email);
        message.setSubject("Learn E — Mã đặt lại mật khẩu");
        message.setText("Mã đặt lại mật khẩu của bạn là: " + code + "\n\n"
                + "Mã có hiệu lực trong 15 phút và chỉ dùng được một lần.\n"
                + "Nếu bạn không yêu cầu, hãy bỏ qua email này — mật khẩu của bạn không bị thay đổi.");
        try {
            mailSender.send(message);
            log.info("Đã gửi email mã đặt lại mật khẩu tới {}", email);
        } catch (Exception e) {
            log.error("Không gửi được email đặt lại mật khẩu tới {}: {}", email, e.getMessage());
        }
    }
}
