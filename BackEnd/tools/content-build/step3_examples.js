// Bước 3: chọn câu ví dụ Tatoeba cho từng từ vựng. Ràng buộc của engine sinh đề (practice_builder.dart):
// câu phải chứa đúng `term` (khớp \b...\b, không phân biệt hoa thường) để làm bài Điền chỗ trống, và 3–14 từ
// để làm bài Sắp xếp câu. Ghi ../work/vocab_examples.json (3 ứng viên tốt nhất mỗi từ).
const fs = require('fs');
const path = require('path');
const tt = require('./tatoeba.js');
const ROOT = path.join(__dirname, '..');

const topics = require('../work/vocab_selected.json');
const targets = new Set(topics.flatMap((t) => t.items.map((i) => i.term.toLowerCase())));
const eng = tt.loadEnglish();
const { byEng } = tt.loadPairs(eng);
console.log('eng', eng.size, 'pairs', byEng.size);

const cands = new Map([...targets].map((t) => [t, []]));
for (const [id, s] of eng) {
  const words = s.split(/\s+/);
  if (words.length < 5 || words.length > 12) continue;
  const toks = tt.tokens(s);
  const hit = toks.filter((w) => targets.has(w));
  if (!hit.length) continue;
  if (!tt.cleanEnglish(s)) continue;
  for (const term of new Set(hit)) {
    if (toks.filter((w) => w === term).length !== 1) continue;
    const hard = toks.filter((w) => w !== term && !tt.isBasic(w)).length;
    const names = words.slice(1).filter((w) => /^[A-Z]/.test(w) && !/^(I|I'm|I'll|I've|I'd|Tom|Tom's|Mary|Mary's)\b/.test(w)).length;
    const score = (byEng.has(id) ? 4 : 0) - Math.abs(words.length - 8) - 3 * hard - 2 * names;
    cands.get(term).push({ id, s, score, vi: byEng.get(id)?.[0]?.vi });
  }
}
const out = {};
let none = [];
for (const [term, list] of cands) {
  list.sort((a, b) => b.score - a.score || a.s.length - b.s.length || a.id - b.id);
  out[term] = list.slice(0, 3);
  if (!list.length) none.push(term);
}
fs.writeFileSync(path.join(ROOT, 'work/vocab_examples.json'), JSON.stringify(out, null, 1));
console.log('no example:', none.length, none.join(' '));
