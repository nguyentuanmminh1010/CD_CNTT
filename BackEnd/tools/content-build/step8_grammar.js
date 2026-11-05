// Bước 8: dựng grammar.json. Độ khó lấy từ CEFR-J Grammar Profile theo mã từng mục: cột "CEFR-J Level",
// thiếu thì cột FREQ*DISP, Core Inventory rồi EGP; A1/A2 = 1, B1 = 2, B2 trở lên = 3. Mục có `lv` ghi tay được ưu tiên (cấu trúc mà hồ sơ chỉ có
// mã tổng quát, vd hiện tại tiếp diễn mang nghĩa tương lai dùng chung mã với hiện tại tiếp diễn).
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');

const parse = (l) => { const o = []; let c = '', q = false; for (const ch of l) { if (ch === '"') q = !q; else if (ch === ',' && !q) { o.push(c); c = ''; } else c += ch; } o.push(c); return o; };
const profile = new Map();
for (const line of fs.readFileSync(path.join(ROOT, 'raw/cefrj/cefrj-grammar-profile-20180315.csv'), 'utf8').split(/\r?\n/).slice(1)) {
  if (!line) continue;
  const f = parse(line);
  const cefrj = (f[4] || f[5] || f[6] || '').match(/[ABC][12]/)?.[0];
  const egp = (f[7] || '').match(/[ABC][12]/)?.[0];
  if (!profile.has(f[1])) profile.set(f[1], { cefrj, egp });
}
const toLevel = (c) => (c.startsWith('A') ? 1 : c === 'B1' ? 2 : 3);

const out = [];
const problems = [];
for (const [name, description, icon, items] of require('./grammar_topics.js')) {
  out.push({
    name, description, icon,
    items: items.map(([term, code, meaning, explanation, example, lv]) => {
      const p = profile.get(code);
      if (!p) problems.push(`${term}: mã ${code} không có trong CEFR-J Grammar Profile`);
      const c = p?.cefrj || p?.egp;
      const level = lv ?? (c ? toLevel(c) : 2);
      return { term, meaning, explanation, example, level, source: { cefrj: code, cefr: c || null } };
    }),
  });
}
fs.writeFileSync(path.join(ROOT, 'work/grammar.json'), JSON.stringify(out, null, 1));
for (const t of out) console.log(`${t.items.length}\t[${[1, 2, 3].map((l) => t.items.filter((i) => i.level === l).length)}]\t${t.name}`);
console.log('total', out.reduce((a, t) => a + t.items.length, 0));
console.log('PROBLEMS:', problems.join('\n') || 'none');
