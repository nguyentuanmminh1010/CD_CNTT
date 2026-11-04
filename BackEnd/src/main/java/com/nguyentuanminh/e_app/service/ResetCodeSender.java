package com.nguyentuanminh.e_app.service;

/** Kênh gửi mã đặt lại mật khẩu tới người dùng. Mặc định chỉ ghi log ({@link LoggingResetCodeSender});
 * muốn gửi email thật thì cài một bean khác (vd dùng {@code JavaMailSender}) — khi đó bean mặc định tự lui. */
public interface ResetCodeSender {

    void send(String email, String code);
}
