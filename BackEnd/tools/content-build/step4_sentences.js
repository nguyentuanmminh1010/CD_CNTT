// Bước 4: lọc cặp câu Anh–Việt Tatoeba theo 16 chủ đề giao tiếp, xếp hạng và in danh sách ứng viên để duyệt tay.
// Ghi ../work/sentence_candidates.json + .txt.
const fs = require('fs');
const path = require('path');
const tt = require('./tatoeba.js');
const ROOT = path.join(__dirname, '..');

const TOPICS = [
  ['Chào hỏi & Làm quen', /\b(hello|hi|good (morning|afternoon|evening|night)|nice to meet|how are you|how have you been|see you|goodbye|welcome|long time)\b/i],
  ['Giới thiệu bản thân', /\b(my name|i'm from|i am from|i live in|i work (as|at|in|for)|i'm an? |years old|where are you from|what do you do|what's your name|i was born|my job)\b/i],
  ['Gia đình & Bạn bè', /\b(family|mother|father|parents|brother|sister|son|daughter|wife|husband|grandmother|grandfather|grandparents|cousin|uncle|aunt|children|friends?)\b/i],
  ['Sở thích & Thời gian rảnh', /\b(hobby|hobbies|like to|likes to|enjoy|free time|weekend|play the|playing|music|movies?|films?|reading|favorite|swimming|soccer|tennis|guitar|piano|cook(ing)?)\b/i],
  ['Ăn uống & Nhà hàng', /\b(menu|order|bill|restaurant|eat|hungry|thirsty|delicious|dinner|lunch|breakfast|coffee|tea|waiter|food|drink|meal)\b/i],
  ['Mua sắm', /\b(how much|price|buy|bought|cheap|expensive|size|try (it|this|these|them) on|pay|cash|credit card|discount|store|shop|shopping|sale)\b/i],
  ['Hỏi đường & Đi lại', /\b(where is|where's|how do i get|how can i get|station|bus|train|taxi|turn (left|right)|straight|far from|near here|lost|map|street|subway|ticket|way to)\b/i],
  ['Du lịch & Khách sạn', /\b(hotel|room|reservation|trip|travel|vacation|holiday|passport|visit|abroad|luggage|suitcase|check in|check out|tourist|beach|country)\b/i],
  ['Công việc & Văn phòng', /\b(work|job|office|meeting|boss|colleague|company|project|report|deadline|busy|schedule|salary|interview|customer)\b/i],
  ['Học tập', /\b(study|studying|school|class|teacher|exam|test|homework|lesson|learn|learning|university|english|student|library|grammar|language)\b/i],
  ['Sức khoẻ', /\b(sick|ill|doctor|hospital|medicine|headache|fever|a cold|pain|health|healthy|tired|rest|dentist|feel (better|well|sick)|exercise)\b/i],
  ['Thời tiết', /\b(weather|rain|raining|rained|snow|snowing|sunny|cloudy|windy|hot|cold|warm|cool|temperature|umbrella|storm)\b/i],
  ['Điện thoại & Hẹn gặp', /\b(call|phone|number|message|speak to|hold on|appointment|meet|free (tomorrow|tonight|on)|what time|o'clock|tomorrow|tonight|later)\b/i],
  ['Cảm xúc & Ý kiến', /\b(i think|i believe|in my opinion|i agree|i disagree|i feel|happy|sad|angry|worried|afraid|glad|surprised|excited|bored|i'm sure|i hope)\b/i],
  ['Lời mời & Đề nghị', /\b(would you like|let's|shall we|why don't we|how about|could you|can you|would you mind|please|help me|can i)\b/i],
  ['Cảm ơn & Xin lỗi', /\b(thank|thanks|sorry|excuse me|apologize|you're welcome|no problem|don't mention it|pardon|forgive)\b/i],
];

const eng = tt.loadEnglish();
const { pairs } = tt.loadPairs(eng);
const cleanVi = (s) => /^[^\s].*[.?!]$/.test(s) && !/[A-Za-z]{2,}\d|[<>"“”]/.test(s) && s.length <= 120;

const out = {};
const txt = [];
for (const [name, re] of TOPICS) {
  const seen = new Set();
  const list = [];
  for (const p of pairs) {
    if (!re.test(p.en) || !tt.cleanEnglish(p.en) || !cleanVi(p.vi)) continue;
    const words = p.en.split(/\s+/);
    if (words.length < 3 || words.length > 11) continue;
    const key = p.en.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    const toks = tt.tokens(p.en);
    const hard = toks.filter((w) => !tt.isBasic(w)).length;
    const names = words.filter((w, i) => /^[A-Z]/.test(w) && !/^(I|I'm|I'll|I've|I'd)\b/.test(w) && i > 0).length
      + (/^(Tom|Mary|John)\b/.test(p.en) ? 1 : 0);
    const personal = /\b(i|you|we|my|your|let's)\b/i.test(p.en) ? 2 : 0;
    const score = personal - 3 * names - 2 * hard - Math.abs(words.length - 7) * 0.7;
    list.push({ ...p, n: words.length, hard, score });
  }
  list.sort((a, b) => b.score - a.score || a.engId - b.engId);
  out[name] = list.slice(0, 45);
  txt.push(`### ${name} (${list.length})`);
  for (const c of out[name]) txt.push(`${c.engId}/${c.vieId}\t${c.en}\t${c.vi}`);
}
fs.writeFileSync(path.join(ROOT, 'work/sentence_candidates.json'), JSON.stringify(out, null, 1));
fs.writeFileSync(path.join(ROOT, 'work/sentence_candidates.txt'), txt.join('\n'));
console.log(TOPICS.map(([n]) => `${n}: ${out[n].length}`).join('\n'));
