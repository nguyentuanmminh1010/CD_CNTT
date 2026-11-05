// Bước 2: tải mục từ Wiktionary (bản trích xuất kaikki.org) cho từng từ đã chọn, lưu cache ở ../raw/kaikki.
// Tuần tự, nghỉ giữa các lần gọi để không dồn tải lên máy chủ.
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const dir = path.join(ROOT, 'raw/kaikki');
fs.mkdirSync(dir, { recursive: true });
const words = require('../work/vocab_selected.json').flatMap((t) => t.items.map((i) => i.term));
const extra = process.argv.slice(2);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  let ok = 0, miss = [];
  for (const w of [...new Set([...words, ...extra])]) {
    const file = path.join(dir, `${w}.jsonl`);
    if (fs.existsSync(file)) { ok++; continue; }
    const url = `https://kaikki.org/dictionary/English/meaning/${w[0]}/${w.slice(0, 2)}/${encodeURIComponent(w)}.jsonl`;
    try {
      const res = await fetch(url, { headers: { 'User-Agent': 'learn-e-content-build/1.0' } });
      if (res.ok) { fs.writeFileSync(file, await res.text()); ok++; } else miss.push(`${w}(${res.status})`);
    } catch (e) { miss.push(`${w}(${e.message})`); }
    await sleep(120);
  }
  console.log('ok', ok, 'missing', miss.length, miss.join(' '));
})();
