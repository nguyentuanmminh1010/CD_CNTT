package com.nguyentuanminh.e_app.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class FacebookErrorMessageTest {

    @Test
    void extractsGraphApiErrorMessage() {
        String body = "{\"error\":{\"message\":\"Invalid OAuth access token - Cannot parse access token\","
                + "\"type\":\"OAuthException\",\"code\":190}}";
        assertEquals("Invalid OAuth access token - Cannot parse access token",
                AuthService.facebookErrorMessage(body));
    }

    @Test
    void fallsBackToRawBodyOrPlaceholder() {
        assertEquals("không rõ lý do", AuthService.facebookErrorMessage(""));
        assertEquals("oops", AuthService.facebookErrorMessage("oops"));
    }
}
