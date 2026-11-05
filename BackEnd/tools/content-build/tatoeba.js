// Đọc dữ liệu Tatoeba (CC BY 2.0 FR) và các tiện ích chấm điểm câu dùng chung cho các bước sau.
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const T = (f) => path.join(ROOT, 'raw/tatoeba', f);

function readTsv(file, fn) {
  const text = fs.readFileSync(file, 'utf8');
  let start = 0;
  while (start < text.length) {
    let end = text.indexOf('\n', start);
    if (end < 0) end = text.length;
    const line = text.slice(start, end).replace(/\r$/, '');
    if (line) fn(line.split('\t'));
    start = end + 1;
  }
}

// Từ cơ bản (CEFR-J A1/A2) để đo độ "dễ" của câu.
const basic = new Set();
const cefrOf = new Map();
for (const f of ['cefrj-vocabulary-profile-1.5.csv', 'octanove-vocabulary-profile-c1c2-1.0.csv']) {
  readTsv(path.join(ROOT, 'raw/cefrj', f), ([line]) => {
    const [head, , lv] = line.split(',');
    for (const w of head.split('/')) {
      const k = w.trim().toLowerCase();
      if (!cefrOf.has(k) || lv < cefrOf.get(k)) cefrOf.set(k, lv);
      if (lv && lv.startsWith('A')) basic.add(k);
    }
  });
}
const FUNCTION_WORDS = 'i you he she it we they me him her us them my your his its our their this that these those a an the is am are was were be been being do does did have has had will would can could shall should may might must not no yes and or but if so to of in on at for with from by as up down out about than then there here what who whom whose which when where why how all some any each every many much more most very too also just only'.split(' ');
for (const w of FUNCTION_WORDS) basic.add(w);

/** Lemma gần đúng cho dạng biến tố (bỏ -s/-es/-ed/-ing/-'s). */
function lemmaCandidates(w) {
  const out = [w];
  const add = (x) => x.length > 1 && out.push(x);
  if (w.endsWith("'s")) add(w.slice(0, -2));
  if (w.endsWith("n't")) add(w.slice(0, -3));
  if (w.endsWith('ies')) add(w.slice(0, -3) + 'y');
  if (w.endsWith('es')) add(w.slice(0, -2));
  if (w.endsWith('s')) add(w.slice(0, -1));
  if (w.endsWith('ied')) add(w.slice(0, -3) + 'y');
  if (w.endsWith('ed')) { add(w.slice(0, -2)); add(w.slice(0, -1)); if (/(.)\1ed$/.test(w)) add(w.slice(0, -3)); }
  if (w.endsWith('ing')) { add(w.slice(0, -3)); add(w.slice(0, -3) + 'e'); if (/(.)\1ing$/.test(w)) add(w.slice(0, -4)); }
  if (w.endsWith('er')) add(w.slice(0, -2));
  if (w.endsWith('est')) add(w.slice(0, -3));
  if (w.endsWith('ly')) add(w.slice(0, -2));
  return out;
}

const tokens = (s) => s.toLowerCase().match(/[a-z]+(?:'[a-z]+)?/g) || [];
const isBasic = (w) => lemmaCandidates(w).some((x) => basic.has(x));
const levelOfWord = (w) => {
  for (const x of lemmaCandidates(w)) if (cefrOf.has(x)) return cefrOf.get(x);
  return null;
};

// Câu không phù hợp ngữ cảnh học (bạo lực, tình dục, chất kích thích, chính trị/tôn giáo nhạy cảm...).
const BLOCK = new RegExp('\\b(' + [
  'kill\\w*', 'murder\\w*', 'dead', 'death', 'die[sd]?', 'dying', 'suicide', 'gun\\w*', 'shoot\\w*', 'shot', 'bomb\\w*',
  'weapon\\w*', 'war', 'wars', 'blood\\w*', 'sex\\w*', 'naked', 'nude', 'kiss\\w*', 'drunk\\w*', 'beer', 'wine',
  'whisk(e)?y', 'vodka', 'alcohol\\w*', 'drug\\w*', 'cigarette\\w*', 'smok\\w+', 'hell', 'damn\\w*', 'god', 'jesus',
  'church', 'bible', 'stupid', 'idiot\\w*', 'hate\\w*', 'ugly', 'fat', 'prison\\w*', 'jail', 'police', 'steal\\w*',
  'stole\\w*', 'rob\\w*', 'crime\\w*', 'criminal\\w*', 'divorc\\w*', 'pregnan\\w*', 'girlfriend', 'boyfriend',
  'terror\\w*', 'hitler', 'nazi\\w*', 'slave\\w*', 'race', 'racis\\w*', 'trump', 'obama', 'president', 'army',
  'soldier\\w*', 'enemy', 'enemies', 'beat', 'hit', 'hurt', 'cry', 'cried', 'crying', 'fight\\w*', 'fought',
  'liar', 'lie[sd]?', 'cheat\\w*', 'fool\\w*', 'crazy', 'mad', 'shit', 'fuck\\w*', 'ass', 'bitch', 'poor',
].join('|') + ')\\b', 'i');

/** Câu sạch: chỉ chữ Latin không dấu + dấu câu cơ bản, kết thúc bằng . ? !, không chứa từ bị chặn. */
function cleanEnglish(s) {
  if (!/^[A-Z][A-Za-z0-9 ,.'?!-]*[.?!]$/.test(s)) return false;
  if (/\b[A-Z]{2,}\b/.test(s.slice(1)) && !/\bOK\b/.test(s)) return false;
  if (/  |\.\.|--|''/.test(s)) return false;
  return !BLOCK.test(s);
}

function loadEnglish() {
  const eng = new Map();
  readTsv(T('eng_sentences.tsv'), ([id, lang, text]) => { if (lang === 'eng' && text) eng.set(+id, text.trim()); });
  return eng;
}

/** Cặp Việt–Anh: Map<engId, [{vieId, vie}]> và danh sách cặp. */
function loadPairs(eng) {
  const vie = new Map();
  readTsv(T('vie_sentences.tsv'), ([id, lang, text]) => { if (text) vie.set(+id, text.trim()); });
  const byEng = new Map();
  const pairs = [];
  readTsv(T('vie-eng_links.tsv'), ([v, e]) => {
    const vieId = +v, engId = +e;
    if (!vie.has(vieId) || !eng.has(engId)) return;
    const p = { engId, vieId, en: eng.get(engId), vi: vie.get(vieId) };
    pairs.push(p);
    if (!byEng.has(engId)) byEng.set(engId, []);
    byEng.get(engId).push(p);
  });
  return { vie, byEng, pairs };
}

module.exports = { readTsv, tokens, isBasic, levelOfWord, cleanEnglish, loadEnglish, loadPairs, basic, cefrOf, BLOCK };
