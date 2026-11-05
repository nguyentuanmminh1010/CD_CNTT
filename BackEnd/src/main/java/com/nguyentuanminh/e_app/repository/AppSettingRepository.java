package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.AppSetting;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppSettingRepository extends JpaRepository<AppSetting, String> {
}
