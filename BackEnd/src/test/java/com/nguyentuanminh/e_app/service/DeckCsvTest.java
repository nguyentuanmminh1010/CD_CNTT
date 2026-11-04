package com.nguyentuanminh.e_app.service;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import org.junit.jupiter.api.Test;

class DeckCsvTest {

    @Test
    void quotedCsvKeepsCommasAndEscapedQuotes() {
        assertArrayEquals(
                new String[] {"apple", "quả táo, đỏ", "I said \"hi\", ok", "/ˈæp.əl/"},
                DeckService.splitLine("\"apple\",\"quả táo, đỏ\",\"I said \"\"hi\"\", ok\",\"/ˈæp.əl/\""));
    }

    @Test
    void quotedCsvAllowsEmptyOptionalFields() {
        assertArrayEquals(new String[] {"apple", "táo", "", ""}, DeckService.splitLine("\"apple\",\"táo\",\"\",\"\""));
    }

    @Test
    void plainSeparatorsStillWork() {
        // splitLine không cắt khoảng trắng — importItems trim từng cột sau đó.
        assertArrayEquals(new String[] {"a ", " b ", " c"}, DeckService.splitLine("a | b | c"));
        assertArrayEquals(new String[] {"a", "b", "c, d"}, DeckService.splitLine("a,b,c, d"));
        assertArrayEquals(new String[] {"a", "b"}, DeckService.splitLine("a\tb"));
    }
}
