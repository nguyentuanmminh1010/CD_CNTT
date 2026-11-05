// Tìm cặp câu Anh–Việt Tatoeba theo các regex (mỗi đối số một regex), in tối đa N kết quả ngắn nhất mỗi mẫu.
// Lưu cache cặp câu ở ../work/pairs.json để lần sau không phải đọc 2 triệu câu tiếng Anh.
const fs = require('fs');
const path = require('path');
const tt = require('./tatoeba.js');
const cache = path.join(__dirname, '../work/pairs.json');
let pairs;
if (fs.existsSync(cache)) pairs = JSON.parse(fs.readFileSync(cache, 'utf8'));
else {
  pairs = tt.loadPairs(tt.loadEnglish()).pairs;
  fs.writeFileSync(cache, JSON.stringify(pairs));
}
const N = +(process.env.N || 12);
for (const src of process.argv.slice(2)) {
  const re = new RegExp(src, 'i');
  const hits = pairs.filter((p) => re.test(p.en) && tt.cleanEnglish(p.en) && p.en.split(/\s+/).length <= 12)
    .sort((a, b) => a.en.length - b.en.length);
  console.log(`## /${src}/ (${hits.length})`);
  const seen = new Set();
  for (const p of hits) {
    if (seen.size >= N) break;
    if (seen.has(p.en + p.vi)) continue;
    seen.add(p.en + p.vi);
    console.log(`${p.engId}/${p.vieId}\t${p.en}\t${p.vi}`);
  }
}
