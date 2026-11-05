package com.nguyentuanminh.e_app.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Cặp khoá–giá trị cấp hệ thống (vd phiên bản bộ nội dung kho chung đã nạp — xem {@code OpenContentSeeder}). */
@Entity
@Table(name = "app_setting")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AppSetting {

    @Id
    @Column(name = "setting_key", length = 100)
    private String key;

    @Column(name = "setting_value", length = 500)
    private String value;
}
