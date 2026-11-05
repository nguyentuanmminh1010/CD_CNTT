// Bước 5: rút phiên âm (General American) và bản dịch tiếng Việt theo nghĩa từ Wiktionary (kaikki), kèm câu ví dụ
// Tatoeba đã chọn → ../work/vocab_review.txt để duyệt tay + ../work/vocab_extract.json.
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const topics = require('../work/vocab_selected.json');
const examples = require('../work/vocab_examples.json');

const POS = { noun: 'n', verb: 'v', adj: 'adj', adv: 'adv', intj: 'intj', prep: 'prep', name: 'name', phrase: 'phr' };

function load(term) {
  const f = path.join(ROOT, 'raw/kaikki', `${term}.jsonl`);
  if (!fs.existsSync(f)) return [];
  return fs.readFileSync(f, 'utf8').trim().split('\n').filter(Boolean).map((l) => JSON.parse(l))
    .filter((e) => e.lang_code === 'en' && e.word.toLowerCase() === term.toLowerCase());
}

const normIpa = (s) => s.replace(/ɹ/g, 'r').replace(/ɾ/g, 't').replace(/\s+/g, ' ');

function ipaOf(entries) {
  const sounds = entries.flatMap((e) => e.sounds || []).filter((s) => s.ipa && s.ipa.startsWith('/'));
  const tagged = (re) => sounds.find((s) => (s.tags || []).some((t) => re.test(t)));
  const s = tagged(/General-American|^US$/) || tagged(/Canada/) || sounds.find((x) => !x.tags) || tagged(/Received/) || sounds[0];
  return s ? normIpa(s.ipa) : null;
}

const out = {};
const lines = [];
for (const t of topics) {
  lines.push(`### ${t.name}`);
  for (const it of t.items) {
    const entries = load(it.term);
    const ipa = ipaOf(entries);
    const senses = [];
    for (const e of entries) {
      const trs = [...(e.translations || []), ...(e.senses || []).flatMap((s) => s.translations || [])]
        .filter((x) => x.lang_code === 'vi' || x.code === 'vi');
      const bySense = new Map();
      for (const x of trs) {
        const k = (x.sense || '').slice(0, 40);
        if (!bySense.has(k)) bySense.set(k, new Set());
        bySense.get(k).add(x.word);
      }
      for (const [k, ws] of bySense) senses.push({ pos: POS[e.pos] || e.pos, sense: k, vi: [...ws] });
    }
    const ex = examples[it.term.toLowerCase()]?.[0];
    out[it.term] = { ipa, senses, example: ex || null, poss: [...new Set(entries.map((e) => POS[e.pos] || e.pos))] };
    const vi = senses.slice(0, 4).map((s) => `${s.pos}:${s.sense}=${s.vi.slice(0, 3).join('/')}`).join(' ; ');
    lines.push(`${it.term}|${it.level}|${ipa}|${vi || '-'}|${ex ? ex.s : '-'}`);
  }
}
fs.writeFileSync(path.join(ROOT, 'work/vocab_extract.json'), JSON.stringify(out, null, 1));
fs.writeFileSync(path.join(ROOT, 'work/vocab_review.txt'), lines.join('\n'));
const all = Object.values(out);
console.log('words', all.length, 'with IPA', all.filter((x) => x.ipa).length, 'with vi', all.filter((x) => x.senses.length).length,
  'with example', all.filter((x) => x.example).length);
