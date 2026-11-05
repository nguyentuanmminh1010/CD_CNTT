// Bước 6: dựng vocabulary.json từ danh sách đã duyệt (vocab_curated.js) + phiên âm Wiktionary + câu ví dụ Tatoeba.
const fs = require('fs');
const path = require('path');
const tt = require('./tatoeba.js');
const ROOT = path.join(__dirname, '..');

const selected = require('../work/vocab_selected.json');
const extract = require('../work/vocab_extract.json');
const curated = require('./vocab_curated.js');
const meta = new Map(selected.flatMap((t) => t.items.map((i) => [i.term, { ...i, topic: t }])));

const specs = [];
for (const [topicName, block] of Object.entries(curated)) {
  const topic = selected.find((t) => t.name === topicName);
  if (!topic) throw new Error('unknown topic ' + topicName);
  for (const line of block.trim().split('\n').filter((l) => l.trim())) {
    const m = line.match(/^(.+?) = (.+?)(?: ~(.+))?$/);
    if (!m) throw new Error('bad line ' + line);
    const [, term, meaning, hint] = m;
    if (!meta.has(term)) throw new Error(`${term}: không có trong vocab_selected (NGSL/TSL)`);
    specs.push({ topicName, term, meaning: meaning.trim(), hint: hint ? new RegExp(hint, 'i') : null });
  }
}
const targets = new Set(specs.map((s) => s.term.toLowerCase()));

const eng = tt.loadEnglish();
const { byEng } = tt.loadPairs(eng);
const cands = new Map([...targets].map((t) => [t, []]));
for (const [id, s] of eng) {
  const words = s.split(/\s+/);
  if (words.length < 4 || words.length > 13) continue;
  const toks = tt.tokens(s);
  const hit = toks.filter((w) => targets.has(w));
  if (!hit.length || !tt.cleanEnglish(s)) continue;
  for (const term of new Set(hit)) {
    if (toks.filter((w) => w === term).length !== 1) continue;
    // Khớp đúng như engine (\bterm\b) nhưng không nhận dạng ghép gạch nối (e-mail, check-in...).
    if (new RegExp(`[-]${term}\\b|\\b${term}[-]`, 'i').test(s)) continue;
    const hard = toks.filter((w) => w !== term && !tt.isBasic(w)).length;
    const names = words.slice(1).filter((w) => /^[A-Z]/.test(w) && !/^(I|I'm|I'll|I've|I'd)\b/.test(w)).length;
    const len = words.length;
    const score = (byEng.has(id) ? 4 : 0) - Math.abs(len - 8) - 3 * hard - 2 * names - (len < 5 || len > 12 ? 3 : 0) - (/\d/.test(s) ? 4 : 0);
    cands.get(term).push({ id, s, score });
  }
}

// Wiktionary không có phiên âm cho 4 mục này — ghi tay theo cùng quy ước General American.
const MANUAL_IPA = { jewelry: '/ˈdʒuəlri/', sightseeing: '/ˈsaɪtˌsiɪŋ/', quarterly: '/ˈkwɔrtɚli/', hotline: '/ˈhɑtˌlaɪn/' };
const used = new Set();
const out = [];
const report = [];
const problems = [];
for (const [name, description, icon] of require('./vocab_topics.js')) {
  const items = [];
  for (const spec of specs.filter((s) => s.topicName === name)) {
    const list = cands.get(spec.term.toLowerCase())
      .filter((c) => !used.has(c.id) && (!spec.hint || spec.hint.test(c.s)))
      .sort((a, b) => b.score - a.score || a.s.length - b.s.length || a.id - b.id);
    const ex = list[0];
    if (!ex) { problems.push(`${spec.term}: không có câu ví dụ khớp ${spec.hint}`); continue; }
    used.add(ex.id);
    const info = extract[spec.term] || {};
    const m = meta.get(spec.term);
    let ipa = info.ipa || MANUAL_IPA[spec.term] || null;
    if (ipa) ipa = (ipa.match(/\/[^/]+\//) || [ipa])[0].replace(/[.()̯̝̃]/g, '');
    if (!ipa) problems.push(`${spec.term}: thiếu IPA`);
    items.push({
      term: spec.term, phonetic: ipa, meaning: spec.meaning, example: ex.s, level: m.level,
      source: { list: m.list, cefr: m.cefr, example: `tatoeba:${ex.id}` },
    });
    report.push(`${spec.term}\t${m.level}\t${ipa}\t${ex.s}`);
  }
  out.push({ name, description, icon, items });
}
fs.writeFileSync(path.join(ROOT, 'work/vocabulary.json'), JSON.stringify(out, null, 1));
fs.writeFileSync(path.join(ROOT, 'work/vocab_final.txt'), report.join('\n'));
console.log(out.map((t) => `${t.items.length}\t${t.name}`).join('\n'));
console.log('total', out.reduce((a, t) => a + t.items.length, 0));
console.log('PROBLEMS:\n' + problems.join('\n'));
