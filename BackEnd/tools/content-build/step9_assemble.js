// Bước 9: kiểm tra 3 bộ dữ liệu theo ràng buộc của engine sinh đề rồi ghi vào BackEnd/src/main/resources/content/.
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const DEST = process.argv[2];
if (!DEST) throw new Error('usage: node step9_assemble.js <BackEnd/src/main/resources/content>');

const VERSION = '2026-11-05-open-v1';
const sets = {
  vocabulary: require('../work/vocabulary.json'),
  grammar: require('../work/grammar.json'),
  sentences: require('../work/sentences.json'),
};
const errors = [];
const warn = [];
const wc = (s) => s.trim().split(/\s+/).length;
const allVocabTerms = new Set();

for (const [kind, topics] of Object.entries(sets)) {
  const topicNames = new Set();
  for (const t of topics) {
    if (topicNames.has(t.name)) errors.push(`${kind}: chủ đề trùng ${t.name}`);
    topicNames.add(t.name);
    if (t.items.length < 6) errors.push(`${kind}/${t.name}: chỉ có ${t.items.length} mục`);
    const terms = new Set();
    const meanings = new Set();
    for (const i of t.items) {
      const where = `${kind}/${t.name}/${i.term}`;
      if (!terms.add(i.term.trim().toLowerCase())) errors.push(`${where}: term trùng trong chủ đề`);
      if (!meanings.add(i.meaning.trim().toLowerCase())) errors.push(`${where}: nghĩa trùng trong chủ đề`);
      if (![1, 2, 3].includes(i.level)) errors.push(`${where}: level ${i.level}`);
      if (!i.meaning.trim()) errors.push(`${where}: thiếu nghĩa`);
      const sentence = i.example || i.term;
      const n = wc(sentence);
      if (kind !== 'vocabulary' || i.example) {
        if (n < 3 || n > 14) errors.push(`${where}: câu ${n} từ (Sắp xếp câu cần 3–14): ${sentence}`);
      }
      if (kind === 'vocabulary') {
        if (allVocabTerms.has(i.term.toLowerCase())) errors.push(`${where}: trùng với chủ đề khác`);
        allVocabTerms.add(i.term.toLowerCase());
        const esc = i.term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        if (!new RegExp(`\\b${esc}\\b`, 'i').test(i.example)) errors.push(`${where}: ví dụ không chứa đúng từ`);
        if (!/^[A-Za-z' -]+$/.test(i.term)) errors.push(`${where}: term có ký tự lạ (hỏng bài Đánh vần)`);
        if (!i.phonetic) errors.push(`${where}: thiếu phiên âm`);
      }
      if (kind === 'sentences' && /\d/.test(i.term)) errors.push(`${where}: có chữ số (hỏng bài Nghe chép)`);
      if (kind === 'grammar' && !i.explanation) warn.push(`${where}: thiếu explanation`);
    }
  }
}
if (errors.length) {
  console.error('LỖI:\n' + errors.join('\n'));
  process.exit(1);
}

const SOURCES = {
  vocabulary: [
    'Danh sách từ: New General Service List 1.2 và TOEIC Service List 1.2 — Browne, C., Culligan, B. & Phillips, J., newgeneralservicelist.com, CC BY-SA 4.0',
    'Độ khó: CEFR-J Wordlist 1.5 (Tono Laboratory, TUFS) + Octanove Vocabulary Profile C1/C2 (CC BY-SA 4.0), github.com/openlanguageprofiles/olp-en-cefrj',
    'Phiên âm (General American) và nghĩa tiếng Việt tham chiếu: English Wiktionary qua kaikki.org, CC BY-SA 4.0 — nghĩa đã được chọn theo chủ đề và viết gọn lại',
    'Câu ví dụ: Tatoeba (tatoeba.org), CC BY 2.0 FR — mã câu ghi ở trường source.example',
  ],
  grammar: [
    'Giải thích tiếng Việt và câu ví dụ: biên soạn cho Learn E',
    'Độ khó: CEFR-J Grammar Profile 20180315 (Tono Laboratory, TUFS), github.com/openlanguageprofiles/olp-en-cefrj — mã mục ghi ở trường source.cefrj',
  ],
  sentences: [
    'Cặp câu Anh–Việt: Tatoeba (tatoeba.org), CC BY 2.0 FR — mã câu ghi ở trường source',
    'Độ khó: tính theo độ dài câu và cấp CEFR-J của các từ trong câu',
  ],
};
const CATEGORY = { vocabulary: 'VOCABULARY', grammar: 'GRAMMAR', sentences: 'SENTENCE' };
fs.mkdirSync(DEST, { recursive: true });
for (const [kind, topics] of Object.entries(sets)) {
  const doc = {
    version: VERSION,
    category: CATEGORY[kind],
    sources: SOURCES[kind],
    topics: topics.map((t) => ({
      name: t.name, description: t.description, icon: t.icon,
      items: t.items.map((i) => ({
        term: i.term, phonetic: i.phonetic ?? null, meaning: i.meaning, example: i.example ?? null,
        explanation: i.explanation ?? null, level: i.level, source: i.source,
      })),
    })),
  };
  fs.writeFileSync(path.join(DEST, `${kind}.json`), JSON.stringify(doc, null, 2) + '\n');
}
const count = (k) => sets[k].reduce((a, t) => a + t.items.length, 0);
console.log(`OK version ${VERSION}: vocabulary ${count('vocabulary')} mục/${sets.vocabulary.length} chủ đề, ` +
  `grammar ${count('grammar')}/${sets.grammar.length}, sentences ${count('sentences')}/${sets.sentences.length}`);
if (warn.length) console.log('Cảnh báo:\n' + warn.join('\n'));
