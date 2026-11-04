package com.nguyentuanminh.e_app.service;

import com.nguyentuanminh.e_app.domain.User;

public record AuthPayload(String token, User user) {
}
