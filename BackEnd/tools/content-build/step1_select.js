// Bước 1: lọc từ ứng viên theo NGSL/TSL, bỏ trùng giữa các chủ đề, tính độ khó theo thứ hạng tần suất.
// Ghi ../work/vocab_selected.json. Đọc dữ liệu tải về từ ../raw (chỉ đọc, không chạy).
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const csv = (f) => fs.readFileSync(path.join(ROOT, 'raw/ngsl', f), 'utf8').trim().split(/\r?\n/).slice(1)
  .map((l) => l.split(','));
const ngsl = new Map(csv('NGSL_12_stats.csv').map(([w, r]) => [w.toLowerCase(), +r]));
const tsl = new Map(csv('TSL_12_stats.csv').map(([w, r]) => [w.toLowerCase(), +r]));

// CEFR-J 1.5 (A1–B2) + Octanove C1/C2: một từ có nhiều từ loại thì lấy cấp thấp nhất.
const cefr = new Map();
for (const f of ['cefrj-vocabulary-profile-1.5.csv', 'octanove-vocabulary-profile-c1c2-1.0.csv']) {
  for (const line of fs.readFileSync(path.join(ROOT, 'raw/cefrj', f), 'utf8').trim().split(/\r?\n/).slice(1)) {
    const [head, , lv] = line.split(',');
    for (const w of head.split('/')) {
      const k = w.trim().toLowerCase();
      if (!cefr.has(k) || lv < cefr.get(k)) cefr.set(k, lv);
    }
  }
}

// Độ khó: theo CEFR (A1/A2 = 1, B1 = 2, B2 trở lên = 3); từ không có trong CEFR-J thì theo thứ hạng tần suất.
function level(lemma, form) {
  const c = cefr.get(form) ?? cefr.get(lemma);
  if (c) return c.startsWith('A') ? 1 : c === 'B1' ? 2 : 3;
  const n = ngsl.get(lemma);
  if (n != null && n <= 1000) return 1;
  if ((n != null && n <= 2000) || (tsl.get(lemma) ?? 9999) <= 300) return 2;
  return 3;
}

const seen = new Set();
const out = [];
const missing = [];
for (const [name, description, icon, words] of require('./vocab_topics.js')) {
  const items = [];
  for (const spec of words.split(/\s+/)) {
    const [form, lemmaRaw] = spec.split('@');
    const lemma = (lemmaRaw || form).toLowerCase();
    if (!ngsl.has(lemma) && !tsl.has(lemma)) { missing.push(`${name}: ${spec}`); continue; }
    if (seen.has(form)) continue;
    seen.add(form);
    items.push({ term: form, lemma, list: ngsl.has(lemma) ? `NGSL#${ngsl.get(lemma)}` : `TSL#${tsl.get(lemma)}`,
      cefr: cefr.get(form) ?? cefr.get(lemma) ?? null, level: level(lemma, form) });
  }
  out.push({ name, description, icon, items });
}
fs.mkdirSync(path.join(ROOT, 'work'), { recursive: true });
fs.writeFileSync(path.join(ROOT, 'work/vocab_selected.json'), JSON.stringify(out, null, 1));
for (const t of out) {
  const lv = [1, 2, 3].map((l) => t.items.filter((i) => i.level === l).length);
  console.log(`${t.items.length}\t[${lv}]\t${t.name}`);
}
console.log('total', out.reduce((a, t) => a + t.items.length, 0));
console.log('NOT IN LISTS:', missing.join(' | '));
