// Bước 7: dựng sentences.json từ các cặp câu Tatoeba đã duyệt tay (mã câu Anh/mã câu Việt).
// Độ khó theo độ dài và cấp CEFR-J cao nhất của các từ: ≤ 6 từ, không có từ B1 = 1; ≥ 9 từ, có từ B2+ hoặc ≥ 2 từ B1 = 3.
const fs = require('fs');
const path = require('path');
const tt = require('./tatoeba.js');
const ROOT = path.join(__dirname, '..');
const pairs = JSON.parse(fs.readFileSync(path.join(ROOT, 'work/pairs.json'), 'utf8'));
const byKey = new Map(pairs.map((p) => [`${p.engId}/${p.vieId}`, p]));

const PICK = [
  ['Chào hỏi & Làm quen', 'Chào hỏi, hỏi thăm và tạm biệt', 'waving_hand_rounded',
    '2194/5938 138868/11973450 372787/9051350 3575357/4456378 417009/13726735 12422505/14028992 3738105/9003249 453072/8774938 32706/3121012 2543873/11364020'],
  ['Giới thiệu bản thân', 'Tên, tuổi, quê quán, nghề nghiệp', 'badge_rounded',
    '408293/4950229 436243/4950225 17125/10670113 329612/5901 13838769/13840939 5641941/13519019 11356714/11356716 252968/13769797 11328503/11328506 1188743/13726805'],
  ['Gia đình & Bạn bè', 'Nói về người thân và bạn bè', 'family_restroom_rounded',
    '1354/5698 24088/488951 3050944/10146674 11314548/11314549 11333204/11333207 11450806/11450808 11318210/11318211 3361170/6546691 11362822/11362823 2406060/9006148'],
  ['Sở thích & Thời gian rảnh', 'Sở thích, cuối tuần và giải trí', 'sports_soccer_rounded',
    '23957/1552380 69229/11452656 707451/1551852 3350127/13769848 11363894/11363895 251151/4274419 321510/13726778 254036/5147975 54115/934993 13524649/13525711'],
  ['Ăn uống & Nhà hàng', 'Gọi món, mời ăn uống, khẩu vị', 'restaurant_menu_rounded',
    '1504/10557698 24765/10274134 400191/4950228 62214/5911247 3868383/5763143 1105358/1554972 3817582/5147641 254987/13841065 13496002/13496531 277792/1548758'],
  ['Mua sắm', 'Hỏi giá, chọn hàng và thanh toán', 'local_mall_rounded',
    '1885879/11277713 11277689/11277690 2485314/4611353 5909701/8976390 274630/9726044 5336539/13666178 5904763/8995663 1335215/14029213 14083005/14083101 3917720/5142815'],
  ['Hỏi đường & Đi lại', 'Hỏi đường, chỉ đường và phương tiện', 'signpost_rounded',
    '1655633/3681274 3097534/9038109 2136/5919 61662/510405 264209/510426 9434177/13565129 11317048/11317049 38190/1563750 61996/9039853 5900634/13249740'],
  ['Du lịch & Khách sạn', 'Đặt phòng, nhận phòng và đi du lịch', 'hotel_rounded',
    '33360/510388 280945/9629934 464588/593009 6436473/9704827 35272/510398 7976624/8854547 480006/1575830 12207616/13173277 271162/10265381 51858/5159933'],
  ['Công việc & Văn phòng', 'Giao tiếp nơi công sở', 'business_center_rounded',
    '242094/2639271 243008/1578973 13451455/10290280 13886915/13888075 254262/713707 261271/10274135 70314/11273262 13928920/13929052 11374570/11374579 2912515/11266537'],
  ['Học tập', 'Trường lớp, bài tập và việc học', 'school_rounded',
    '13892555/13896443 30181/9006419 268912/5763262 754023/9029818 2792348/8991724 370763/9013902 1477313/9726058 6225471/10670110 252626/13769764 535041/11330570'],
  ['Sức khoẻ', 'Ốm đau, đi khám và giữ gìn sức khoẻ', 'favorite_rounded',
    '38381/5149403 433669/9165698 9408766/11475756 11338382/11338384 10784781/11434717 16315/13769779 28041/13726688 10777864/13599551 1510783/1510782 6784134/10291524'],
  ['Thời tiết', 'Nói về thời tiết hôm nay và ngày mai', 'wb_sunny_rounded',
    '323448/9003255 5123834/9722849 11303152/11303154 70644/9419185 1428036/9004367 79464/13870235 11276046/11276047 5851425/13342815 33150/1563752 456163/13249710'],
  ['Điện thoại & Hẹn gặp', 'Gọi điện, nhắn lời và hẹn lịch', 'call_rounded',
    '282837/9741771 1824/5845 2538238/5160029 7120770/9031432 453601/1564358 3444808/5145607 1064227/9740853 71871/9010997 1956119/5162227 4013222/5759030'],
  ['Cảm xúc & Ý kiến', 'Bày tỏ cảm xúc, hy vọng và quan điểm', 'emoji_emotions_rounded',
    '71573/1542986 2712945/11449257 2407754/4787885 1321685/11426570 18882/8949939 308113/9064473 1184694/6564798 5651022/5763258 2591706/9034118 6474829/10267742'],
  ['Lời mời & Đề nghị', 'Mời, rủ rê và nhờ giúp đỡ lịch sự', 'chat_bubble_rounded',
    '682289/4932042 400597/13173484 2518523/11432298 6126352/8961985 39965/8997652 3321167/3333608 38988/9023420 267691/11584701 490674/490676 4895545/5148019'],
  ['Cảm ơn & Xin lỗi', 'Cảm ơn, xin lỗi và đáp lời lịch sự', 'volunteer_activism_rounded',
    '1839560/13522885 35673/5642124 63873/3455671 10775525/11449217 1403/8974571 8945563/8945626 3537633/5148644 1039687/4950224 2361909/4950209 24940/9039854'],
];

function level(en) {
  const words = en.split(/\s+/).length;
  const lv = tt.tokens(en).map((w) => tt.levelOfWord(w)).filter(Boolean);
  const b1 = lv.filter((l) => l === "B1").length;
  const b2 = lv.some((l) => l >= "B2");
  if (words >= 9 || b2 || b1 >= 2) return 3;
  if (words <= 6 && b1 === 0) return 1;
  return 2;
}

const out = [];
const problems = [];
for (const [name, description, icon, ids] of PICK) {
  const items = [];
  for (const key of ids.split(/\s+/)) {
    const p = byKey.get(key);
    if (!p) { problems.push(`${name}: không thấy cặp ${key}`); continue; }
    items.push({ term: p.en, meaning: p.vi, example: null, level: level(p.en), source: { example: `tatoeba:${p.engId}`, meaning: `tatoeba:${p.vieId}` } });
  }
  out.push({ name, description, icon, items });
}
fs.writeFileSync(path.join(ROOT, 'work/sentences.json'), JSON.stringify(out, null, 1));
for (const t of out) console.log(`${t.items.length}\t[${[1, 2, 3].map((l) => t.items.filter((i) => i.level === l).length)}]\t${t.name}`);
console.log('PROBLEMS:', problems.join('\n') || 'none');
