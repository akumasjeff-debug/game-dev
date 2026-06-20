// 國語小練習 v2.0 — 仿考卷 8 種題型，純 HTML/JS
const VERSION = '20260620 1500';

// =====================================================================
// ZHUYIN TABLE — 一至三年級常見字
// =====================================================================
const ZHUYIN = {
  // 數字
  一:'ㄧ',二:'ㄦˋ',三:'ㄙㄢ',四:'ㄙˋ',五:'ㄨˇ',六:'ㄌㄧㄡˋ',七:'ㄑㄧ',八:'ㄅㄚ',九:'ㄐㄧㄡˇ',十:'ㄕˊ',
  百:'ㄅㄞˇ',千:'ㄑㄧㄢ',萬:'ㄨㄢˋ',
  // 自然
  天:'ㄊㄧㄢ',地:'ㄉㄧˋ',人:'ㄖㄣˊ',山:'ㄕㄢ',水:'ㄕㄨㄟˇ',火:'ㄏㄨㄛˇ',木:'ㄇㄨˋ',日:'ㄖˋ',
  月:'ㄩㄝˋ',星:'ㄒㄧㄥ',雲:'ㄩㄣˊ',雨:'ㄩˇ',雪:'ㄒㄩㄝˇ',風:'ㄈㄥ',花:'ㄏㄨㄚ',草:'ㄘㄠˇ',
  樹:'ㄕㄨˋ',葉:'ㄧㄝˋ',石:'ㄕˊ',土:'ㄊㄨˇ',田:'ㄊㄧㄢˊ',河:'ㄏㄜˊ',海:'ㄏㄞˇ',湖:'ㄏㄨˊ',
  光:'ㄍㄨㄤ',虹:'ㄏㄨㄥˊ',
  // 動物
  魚:'ㄩˊ',鳥:'ㄋㄧㄠˇ',牛:'ㄋㄧㄡˊ',羊:'ㄧㄤˊ',馬:'ㄇㄚˇ',狗:'ㄍㄡˇ',貓:'ㄇㄠ',兔:'ㄊㄨˋ',
  鵝:'ㄜˊ',蛙:'ㄨㄚ',蝶:'ㄉㄧㄝˊ',蜂:'ㄈㄥ',
  // 身體
  手:'ㄕㄡˇ',口:'ㄎㄡˇ',耳:'ㄦˇ',心:'ㄒㄧㄣ',頭:'ㄊㄡˊ',眼:'ㄧㄢˇ',鼻:'ㄅㄧˊ',臉:'ㄌㄧㄢˇ',腳:'ㄐㄧㄠˇ',
  // 家人
  爸:'ㄅㄚˋ',媽:'ㄇㄚ',哥:'ㄍㄜ',姐:'ㄐㄧㄝˇ',弟:'ㄉㄧˋ',妹:'ㄇㄟˋ',家:'ㄐㄧㄚ',
  叔:'ㄕㄨˊ',姑:'ㄍㄨ',舅:'ㄐㄧㄡˋ',姨:'ㄧˊ',
  // 學校
  學:'ㄒㄩㄝˊ',校:'ㄒㄧㄠˋ',書:'ㄕㄨ',課:'ㄎㄜˋ',讀:'ㄉㄨˊ',寫:'ㄒㄧㄝˇ',字:'ㄗˋ',老:'ㄌㄠˇ',
  師:'ㄕ',同:'ㄊㄨㄥˊ',班:'ㄅㄢ',業:'ㄧㄝˋ',功:'ㄍㄨㄥ',
  // 動作
  走:'ㄗㄡˇ',跑:'ㄆㄠˇ',跳:'ㄊㄧㄠˋ',吃:'ㄔ',喝:'ㄏㄜ',看:'ㄎㄢˋ',說:'ㄕㄨㄛ',聽:'ㄊㄧㄥ',
  做:'ㄗㄨㄛˋ',玩:'ㄨㄢˊ',唱:'ㄔㄤˋ',畫:'ㄏㄨㄚˋ',笑:'ㄒㄧㄠˋ',哭:'ㄎㄨ',睡:'ㄕㄨㄟˋ',
  打:'ㄉㄚˇ',拉:'ㄌㄚ',推:'ㄊㄨㄟ',游:'ㄧㄡˊ',遊:'ㄧㄡˊ',升:'ㄕㄥ',落:'ㄌㄨㄛˋ',
  停:'ㄊㄧㄥˊ',收:'ㄕㄡ',送:'ㄙㄨㄥˋ',洗:'ㄒㄧˇ',刷:'ㄕㄨㄚ',掃:'ㄙㄠˇ',放:'ㄈㄤˋ',
  站:'ㄓㄢˋ',坐:'ㄗㄨㄛˋ',記:'ㄐㄧˋ',知:'ㄓ',認:'ㄖㄣˋ',
  // 形容詞
  大:'ㄉㄚˋ',小:'ㄒㄧㄠˇ',多:'ㄉㄨㄛ',少:'ㄕㄠˇ',高:'ㄍㄠ',低:'ㄉㄧ',長:'ㄔㄤˊ',短:'ㄉㄨㄢˇ',
  好:'ㄏㄠˇ',快:'ㄎㄨㄞˋ',慢:'ㄇㄢˋ',新:'ㄒㄧㄣ',美:'ㄇㄟˇ',冷:'ㄌㄥˇ',熱:'ㄖㄜˋ',
  忙:'ㄇㄤˊ',紅:'ㄏㄨㄥˊ',黃:'ㄏㄨㄤˊ',藍:'ㄌㄢˊ',綠:'ㄌㄩˋ',白:'ㄅㄞˊ',黑:'ㄏㄟ',
  彩:'ㄘㄞˇ',漂:'ㄆㄧㄠˋ',亮:'ㄌㄧㄤˋ',清:'ㄑㄧㄥ',楚:'ㄔㄨˇ',真:'ㄓㄣ',神:'ㄕㄣˊ',奇:'ㄑㄧˊ',
  每:'ㄇㄟˇ',
  // 時間方向
  今:'ㄐㄧㄣ',明:'ㄇㄧㄥˊ',早:'ㄗㄠˇ',晚:'ㄨㄢˇ',年:'ㄋㄧㄢˊ',
  上:'ㄕㄤˋ',下:'ㄒㄧㄚˋ',左:'ㄗㄨㄛˇ',右:'ㄧㄡˋ',中:'ㄓㄨㄥ',前:'ㄑㄧㄢˊ',後:'ㄏㄡˋ',裡:'ㄌㄧˇ',
  外:'ㄨㄞˋ',旁:'ㄆㄤˊ',
  // 常用字
  我:'ㄨㄛˇ',你:'ㄋㄧˇ',他:'ㄊㄚ',她:'ㄊㄚ',是:'ㄕˋ',不:'ㄅㄨˋ',有:'ㄧㄡˇ',在:'ㄗㄞˋ',
  和:'ㄏㄜˊ',也:'ㄧㄝˇ',都:'ㄉㄡ',就:'ㄐㄧㄡˋ',很:'ㄏㄣˇ',這:'ㄓㄜˋ',那:'ㄋㄚˋ',的:'˙ㄉㄜ',
  了:'˙ㄌㄜ',著:'˙ㄓㄜ',們:'˙ㄇㄣ',嗎:'˙ㄇㄚ',吧:'˙ㄅㄚ',
  // 課文詞彙
  夢:'ㄇㄥˋ',躺:'ㄊㄤˇ',自:'ㄗˋ',己:'ㄐㄧˇ',變:'ㄅㄧㄢˋ',成:'ㄔㄥˊ',棉:'ㄇㄧㄢˊ',糖:'ㄊㄤˊ',
  得:'ㄉㄜˊ',更:'ㄍㄥˋ',鞋:'ㄒㄧㄝˊ',雙:'ㄕㄨㄤ',穿:'ㄔㄨㄢ',滴:'ㄉㄧ',戲:'ㄒㄧˋ',顆:'ㄎㄜ',
  珍:'ㄓㄣ',珠:'ㄓㄨ',面:'ㄇㄧㄢˋ',缸:'ㄍㄤ',金:'ㄐㄧㄣ',過:'ㄍㄨㄛˋ',去:'ㄑㄩˋ',來:'ㄌㄞˊ',
  太:'ㄊㄞˋ',陽:'ㄧㄤˊ',國:'ㄍㄨㄛˊ',王:'ㄨㄤˊ',要:'ㄧㄠˋ',除:'ㄔㄨˊ',淨:'ㄐㄧㄥˋ',
  給:'ㄍㄟˇ',件:'ㄐㄧㄢˋ',事:'ㄕˋ',情:'ㄑㄧㄥˊ',化:'ㄏㄨㄚˋ',趣:'ㄑㄩˋ',線:'ㄒㄧㄢˋ',
  箏:'ㄓㄥ',道:'ㄉㄠˋ',生:'ㄕㄥ',謝:'ㄒㄧㄝˋ',第:'ㄉㄧˋ',次:'ㄘˋ',到:'ㄉㄠˋ',張:'ㄓㄤ',
  卡:'ㄎㄚˇ',片:'ㄆㄧㄢˋ',祝:'ㄓㄨˋ',福:'ㄈㄨˊ',燈:'ㄉㄥ',點:'ㄉㄧㄢˇ',半:'ㄅㄢˋ',
  誰:'ㄕㄟˊ',分:'ㄈㄣ',出:'ㄔㄨ',休:'ㄒㄧㄡ',息:'ㄒㄧˊ',會:'ㄏㄨㄟˋ',兒:'ㄦˊ',加:'ㄐㄧㄚ',
  油:'ㄧㄡˊ',感:'ㄍㄢˇ',表:'ㄅㄧㄠˇ',示:'ㄕˋ',物:'ㄨˋ',禮:'ㄌㄧˇ',開:'ㄎㄞ',
  志:'ㄓˋ',願:'ㄩㄢˋ',名:'ㄇㄧㄥˊ',照:'ㄓㄠˋ',樣:'ㄧㄤˋ',句:'ㄐㄩˋ',富:'ㄈㄨˋ',
  立:'ㄌㄧˋ',刻:'ㄎㄜˋ',然:'ㄖㄢˊ',已:'ㄧˇ',體:'ㄊㄧˇ',力:'ㄌㄧˋ',完:'ㄨㄢˊ',
  根:'ㄍㄣ',內:'ㄋㄟˋ',場:'ㄔㄤˊ',紀:'ㄐㄧˋ',作:'ㄗㄨㄛˋ',
};

// =====================================================================
// 部件（部首）群組 — 用於「找相同部件」題
// =====================================================================
const RADICAL_GROUPS = [
  { radical:'氵', label:'三點水', chars:['游','清','洗','海','湖','河','滴','淨','泳','漂'] },
  { radical:'木', label:'木字旁', chars:['樹','棉','橋','桌','校','根','格','椅','梯','植'] },
  { radical:'忄', label:'心字旁', chars:['忙','快','情','忘','感','慢','怕','悶','悲','恩'] },
  { radical:'口', label:'口字旁', chars:['唱','喝','叫','哭','嗎','吧','問','啊','嗯','嚷'] },
  { radical:'扌', label:'手字旁', chars:['打','拉','推','拿','接','握','拍','抓','抱','掃'] },
  { radical:'艹', label:'草字頭', chars:['花','草','葉','菜','茶','芳','苗','荷','薄','蓮'] },
  { radical:'訁', label:'言字旁', chars:['說','讀','謝','請','話','認','語','識','訴','諾'] },
  { radical:'足', label:'足字旁', chars:['跑','跳','踢','跡','蹦','跨','踩','路','踏','跟'] },
  { radical:'火', label:'火字旁', chars:['燈','炒','烤','焦','燒','炸','熱','燦','燒','灼'] },
  { radical:'目', label:'目字旁', chars:['看','眼','睛','眉','眨','睡','瞧','瞪','瞭','眺'] },
];

// =====================================================================
// 看注音選字題 — 同音字辨別（含句子語境）
// =====================================================================
const CHAR_FILL_Q = [
  { before:'我喜歡玩（　）戲。', zhuyin:'ㄧㄡˊ', answer:'遊', options:['遊','游','由','油'] },
  { before:'路（　）亮起來了。', zhuyin:'ㄉㄥ', answer:'燈', options:['燈','等','登','澄'] },
  { before:'他年（　）大了，頭髮白了。', zhuyin:'ㄐㄧˋ', answer:'紀', options:['紀','記','計','繼'] },
  { before:'他（　）己整理書包。', zhuyin:'ㄗˋ', answer:'自', options:['自','字','仔','紫'] },
  { before:'謝謝你的（　）福。', zhuyin:'ㄓㄨˋ', answer:'祝', options:['祝','住','柱','注'] },
  { before:'今天是我的（　）日快樂。', zhuyin:'ㄕㄥ', answer:'生', options:['生','升','聲','繩'] },
  { before:'七彩的（　）好漂亮。', zhuyin:'ㄏㄨㄥˊ', answer:'虹', options:['虹','紅','洪','宏'] },
  { before:'她（　）著長長的線放風箏。', zhuyin:'ㄌㄚ', answer:'拉', options:['拉','啦','辣','蠟'] },
  { before:'太陽國王要大（　）除了。', zhuyin:'ㄙㄠˇ', answer:'掃', options:['掃','嫂','叟','搜'] },
  { before:'風箏升得很（　），好神奇。', zhuyin:'ㄍㄠ', answer:'高', options:['高','告','搞','稿'] },
  { before:'媽媽很（　）真地工作。', zhuyin:'ㄖㄣˋ', answer:'認', options:['認','韌','任','忍'] },
  { before:'她收到一張生（　）卡片。', zhuyin:'ㄖˋ', answer:'日', options:['日','耳','二','而'] },
  { before:'黑天（　）好漂亮！', zhuyin:'ㄜˊ', answer:'鵝', options:['鵝','哦','餓','惡'] },
  { before:'妹妹的紅雨（　）很可愛。', zhuyin:'ㄒㄧㄝˊ', answer:'鞋', options:['鞋','些','寫','謝'] },
  { before:'大魚（　）裡有紅金魚。', zhuyin:'ㄍㄤ', answer:'缸', options:['缸','剛','崗','鋼'] },
  { before:'我最（　）心！', zhuyin:'ㄎㄞ', answer:'開', options:['開','楷','凱','慨'] },
  { before:'謝謝老師一直（　）油。', zhuyin:'ㄐㄧㄚ', answer:'加', options:['加','夾','家','假'] },
  { before:'大樹葉子刷得好（　）亮。', zhuyin:'ㄆㄧㄠˋ', answer:'漂', options:['漂','票','飄','瓢'] },
  { before:'棉（　）糖像一朵白雲。', zhuyin:'ㄏㄨㄚ', answer:'花', options:['花','化','貨','火'] },
  { before:'一顆顆的雨（　）落在水面。', zhuyin:'ㄉㄧ', answer:'滴', options:['滴','笛','嫡','敵'] },
  { before:'風（　）升得越來越高。', zhuyin:'ㄓㄥ', answer:'箏', options:['箏','正','掙','睜'] },
  { before:'這個故事真的好（　）趣。', zhuyin:'ㄑㄩˋ', answer:'趣', options:['趣','取','去','娶'] },
  { before:'他很（　）真地寫功課。', zhuyin:'ㄓㄣ', answer:'真', options:['真','針','珍','貞'] },
  { before:'大家跑跑（　）跳，好快樂。', zhuyin:'ㄊㄧㄠˋ', answer:'跳', options:['跳','眺','挑','逃'] },
];

// =====================================================================
// 填空題 — 不給注音，選詞填入
// =====================================================================
const FILL_BLANK_Q = [
  { sent:'一顆顆的雨滴，像小（　）珠。', answer:'珍', options:['珍','珠','真','金'] },
  { sent:'大（　）缸裡有紅金魚游過去。', answer:'魚', options:['魚','玻','水','石'] },
  { sent:'七彩的虹送給他（　）。', answer:'們', options:['們','個','的','啊'] },
  { sent:'我收到一張生日（　）片，好開心！', answer:'卡', options:['卡','名','明','信'] },
  { sent:'太（　）國王要大掃除了。', answer:'陽', options:['陽','陰','太','火'] },
  { sent:'太陽（　）王要大掃除了。', answer:'國', options:['國','公','天','老'] },
  { sent:'她拉著長（　）的線放風箏。', answer:'長', options:['長','短','細','粗'] },
  { sent:'七（　）的虹好漂亮！', answer:'彩', options:['彩','色','光','百'] },
  { sent:'路燈在我（　）面跑，我追不上。', answer:'前', options:['前','後','旁','上'] },
  { sent:'她不太清（　），路怎麼走。', answer:'楚', options:['楚','清','明','白'] },
  { sent:'媽媽說：「（　）油！加油！」', answer:'加', options:['加','打','幫','給'] },
  { sent:'大（　）很認真地刷亮葉子。', answer:'樹', options:['樹','草','花','石'] },
  { sent:'她第一次（　）到生日卡片。', answer:'收', options:['收','接','拿','得'] },
  { sent:'今天是我的（　）日，謝謝大家！', answer:'生', options:['生','身','升','聲'] },
  { sent:'風箏升得（　）高，好神奇！', answer:'很', options:['很','也','都','最'] },
  { sent:'大掃除以後，家裡很（　）淨。', answer:'乾', options:['乾','清','整','漂'] },
  { sent:'雨（　）一落下，水面就開了。', answer:'滴', options:['滴','水','珠','點'] },
  { sent:'（　）彩的虹高高掛在天上。', answer:'七', options:['七','十','百','三'] },
  { sent:'他把書（　）放在桌上。', answer:'本', options:['本','頁','包','袋'] },
  { sent:'小珍珠一（　）下，水面就開了。', answer:'落', options:['落','掉','飛','升'] },
  { sent:'棉花（　）像一朵白白的雲。', answer:'糖', options:['糖','花','雲','球'] },
  { sent:'妹妹穿上紅（　）鞋，好可愛。', answer:'雨', options:['雨','運','雙','紅'] },
  { sent:'大家說說（　）（　），好快樂。', answer:'笑', options:['笑','歌','唱','叫'] },
  { sent:'我每天早上都會（　）起來運動。', answer:'早', options:['早','快','先','準'] },
];

// =====================================================================
// 改錯字題 — 句中一字錯，選正確字
// =====================================================================
const WRONG_CHAR_Q = [
  { text:'他起床以後，【白】己整理書包。', wrongChar:'白', answer:'自', options:['自','由','目','己'] },
  { text:'爸爸年【記】大了，頭髮白了。', wrongChar:'記', answer:'紀', options:['紀','己','已','計'] },
  { text:'我喜歡在公園裡玩【游】戲。', wrongChar:'游', answer:'遊', options:['遊','由','友','油'] },
  { text:'她把書本放在【卓】子上。', wrongChar:'卓', answer:'桌', options:['桌','椅','台','板'] },
  { text:'一【雙】小珍珠落在水面上。', wrongChar:'雙', answer:'顆', options:['顆','粒','個','條'] },
  { text:'大樹【很】真地刷亮葉子。', wrongChar:'很', answer:'認', options:['認','用','努','仔'] },
  { text:'七彩的虹【高】給他們。', wrongChar:'高', answer:'送', options:['送','給','帶','拿'] },
  { text:'天上的星星好像一【課】顆珍珠。', wrongChar:'課', answer:'顆', options:['顆','粒','個','枚'] },
  { text:'他說：「我不太【請】楚。」', wrongChar:'請', answer:'清', options:['清','明','知','懂'] },
  { text:'她拉著風【棉】，升得好高。', wrongChar:'棉', answer:'箏', options:['箏','筆','竿','線'] },
  { text:'我每天都很【忍】真地念書。', wrongChar:'忍', answer:'認', options:['認','記','想','努'] },
  { text:'妹妹穿了一【隻】紅雨鞋。', wrongChar:'隻', answer:'雙', options:['雙','條','個','件'] },
  { text:'太陽國【往】要大掃除了。', wrongChar:'往', answer:'王', options:['王','公','皇','帝'] },
  { text:'路燈在我【錢】面跑，好快！', wrongChar:'錢', answer:'前', options:['前','後','旁','外'] },
  { text:'今天是我的生【目】快樂。', wrongChar:'目', answer:'日', options:['日','月','年','時'] },
  { text:'黑天【餓】游在水上，好漂亮。', wrongChar:'餓', answer:'鵝', options:['鵝','鴨','雞','鳥'] },
  { text:'棉【化】糖甜甜的，很好吃。', wrongChar:'化', answer:'花', options:['花','火','貨','華'] },
  { text:'風箏升得好【低】，好神奇！', wrongChar:'低', answer:'高', options:['高','遠','快','大'] },
  { text:'她不太【青】楚路怎麼走。', wrongChar:'青', answer:'清', options:['清','明','知','懂'] },
  { text:'雨滴一落下，水面就【閉】了。', wrongChar:'閉', answer:'開', options:['開','動','破','碎'] },
];


// =====================================================================
// ○× 判斷題
// =====================================================================
const TRUE_FALSE_Q = [
  { text:'「跑跑跳跳」是一個疊字詞（有重複的字）。', answer:true },
  { text:'「棉花糖」一共有三個字。', answer:true },
  { text:'「很認真」的「認」注音是ㄖㄣˋ。', answer:true },
  { text:'「一雙」是用來計算魚的量詞。', answer:false },
  { text:'「黑天鵝」的「鵝」注音是ㄜˋ（第四聲）。', answer:false },
  { text:'「游泳」的「游」和「遊公園」的「遊」是同一個字。', answer:false },
  { text:'「生日快樂」一共有四個字。', answer:true },
  { text:'「魚缸」的「缸」注音是ㄍㄤ。', answer:true },
  { text:'風箏的線越長，風箏可以升得越高。', answer:true },
  { text:'「清楚」的「清」注音是ㄑㄧㄥ。', answer:true },
  { text:'「疊字詞」是指有兩個不同的字在一起的詞。', answer:false },
  { text:'「一顆」是用來計算雨鞋的量詞。', answer:false },
  { text:'「加油」的「加」注音是ㄐㄧㄚ。', answer:true },
  { text:'「太陽」的「陽」注音是ㄧㄤˊ（第二聲）。', answer:true },
  { text:'「生日快樂」裡的「快」注音是ㄎㄨㄞˋ。', answer:true },
  { text:'說說笑笑、跑跑跳跳都是疊字詞。', answer:true },
  { text:'「棉花糖」的「棉」注音是ㄇㄧㄢˊ。', answer:true },
  { text:'「一隻」可以用來數一雙鞋子。', answer:false },
  { text:'「路燈」的「燈」注音是ㄉㄥ（第一聲）。', answer:true },
  { text:'「謝謝」是一個疊字詞。', answer:true },
];

// =====================================================================
// 量詞題
// =====================================================================
const CLASSIFIERS = [
  { word:'雨鞋', answer:'雙', options:['雙','隻','條','個'] },
  { word:'珍珠', answer:'顆', options:['顆','粒','個','片'] },
  { word:'生日卡片', answer:'張', options:['張','本','份','冊'] },
  { word:'黑天鵝', answer:'隻', options:['隻','匹','頭','條'] },
  { word:'魚', answer:'條', options:['條','隻','匹','頭'] },
  { word:'書', answer:'本', options:['本','張','冊','份'] },
  { word:'花', answer:'朵', options:['朵','株','棵','片'] },
  { word:'樹', answer:'棵', options:['棵','朵','株','根'] },
  { word:'紙', answer:'張', options:['張','本','頁','冊'] },
  { word:'衣服', answer:'件', options:['件','條','雙','套'] },
  { word:'褲子', answer:'條', options:['條','件','雙','套'] },
  { word:'牛', answer:'頭', options:['頭','隻','條','匹'] },
  { word:'馬', answer:'匹', options:['匹','頭','隻','條'] },
  { word:'蛋糕', answer:'個', options:['個','塊','片','顆'] },
  { word:'風箏', answer:'個', options:['個','隻','條','支'] },
];

// =====================================================================
// 詞語列表（詞彙庫）
// =====================================================================
const WORDS = [
  '作夢','黑雲','躺在','自己','變成','黑天鵝','棉花糖','變得','更漂亮','妹妹的紅雨鞋',
  '一雙','穿上','雨滴','玩遊戲','一顆顆','小珍珠','一落下','水面','大魚缸','紅金魚',
  '游過去','來','太陽','國王','要大掃除','洗淨','高高低低','馬路','很認真','大樹',
  '葉子','刷亮','七彩的虹','送給他們','跑跑跳跳','說說笑笑','每件事情','草地','變化',
  '好有趣','拉著','長長的','線','放風箏','升得','高','好神奇','下課時','知道','嗎',
  '記得','今天是','生日快樂','謝謝','第一次','這','放學時','我','收到',
  '一張','生日卡片','祝福','跑','路燈','在我','前面','快一點','一半','到','加油',
  '不太','清楚','停下來','誰快','誰慢','分不出','休息','一會兒','吧',
];

// =====================================================================
// 輔助函式
// =====================================================================
function shuffle(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
function pick(arr, n) { return shuffle(arr).slice(0, n); }
function rand(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

function hasRepeat(w) {
  for (let i = 0; i < w.length - 1; i++) if (w[i] === w[i+1]) return true;
  return false;
}
const REDUP_WORDS = WORDS.filter(hasRepeat);
const ALL_ZY_CHARS = Object.keys(ZHUYIN);

// 注音直排渲染
const TONES = new Set(['ˊ','ˇ','ˋ','˙']);
function parseZy(zy) {
  let tone = '', syms = [];
  const chars = Array.from(zy);
  if (chars[0] === '˙') { tone = '˙'; syms = chars.slice(1); }
  else if (TONES.has(chars[chars.length - 1])) { tone = chars.pop(); syms = chars; }
  else syms = chars;
  return { syms, tone };
}
function zyVertical(zy) {
  const { syms, tone } = parseZy(zy);
  if (!syms.length) return zy;
  const rows = syms.map((s, i) => {
    const isLast = i === syms.length - 1;
    const toneSpan = (isLast && tone) ? `<span class="zy-tone">${tone}</span>` : '';
    return `<div class="zy-row"><span class="zy-sym">${s}</span>${toneSpan}</div>`;
  });
  return `<div class="zy-block">${rows.join('')}</div>`;
}

// ruby 僅用於管理員題庫瀏覽
function withRuby(text) {
  return Array.from(text).map(ch => {
    const zy = ZHUYIN[ch];
    return zy ? `<ruby>${ch}<rt style="font-size:10px;color:#888">${zy}</rt></ruby>` : ch;
  }).join('');
}

// 兒童書格式注音：字右側直排，聲調在最後符號右下
function inlineZy(zy) {
  const { syms, tone } = parseZy(zy);
  if (!syms.length) return '';
  const rows = syms.map((s, i) => {
    const isLast = i === syms.length - 1;
    const t = (isLast && tone) ? `<span class="ann-tone">${tone}</span>` : '';
    return `<div class="ann-row">${s}${t}</div>`;
  });
  return `<div class="ann-zy">${rows.join('')}</div>`;
}

// 題目注音標注；hideChars（Set）內的字只顯示字，不顯示注音
function annotate(text, hideChars = new Set()) {
  return Array.from(text).map(ch => {
    const zy = ZHUYIN[ch];
    if (!zy) return ch;
    if (hideChars.has(ch)) return ch;
    return `<span class="char-unit">${ch}${inlineZy(zy)}</span>`;
  }).join('');
}

// =====================================================================
// 產生題目
// =====================================================================
function genZhuyinQ() {
  // 從課文詞語表抽字（只考 8-12 課詞彙中出現的字）
  const pool = [...new Set(WORDS.flatMap(w => [...w]))].filter(ch => ZHUYIN[ch]);
  const char = rand(pool);
  const answer = ZHUYIN[char];
  const wrongChars = pick(pool.filter(c => ZHUYIN[c] !== answer), 3);
  const options = shuffle([answer, ...wrongChars.map(c => ZHUYIN[c])]);
  return { type:'zhuyin', char, answer, options, key:`zy:${char}` };
}

function genCharFillQ() {
  // 給注音+句子，選正確字（同音字辨別）
  const q = rand(CHAR_FILL_Q);
  return { type:'char_fill', ...q, key:`cf:${q.answer}` };
}

function genClassifierQ() {
  const q = rand(CLASSIFIERS);
  return { type:'classifier', ...q, key:`cls:${q.word}` };
}

function genRedupQ() {
  const correct = rand(REDUP_WORDS);
  const wrong = pick(WORDS.filter(w => !hasRepeat(w) && w !== correct), 3);
  return { type:'redup', answer:correct, options:shuffle([correct, ...wrong]), key:`rd:${correct}` };
}

function genFillBlankQ() {
  const q = rand(FILL_BLANK_Q);
  return { type:'fill_blank', ...q, key:`fb:${q.answer}:${q.sent.slice(0,5)}` };
}

function genWrongCharQ() {
  const q = rand(WRONG_CHAR_Q);
  return { type:'wrong_char', ...q, key:`wc:${q.wrongChar}:${q.answer}` };
}

function genRadicalQ() {
  const group = rand(RADICAL_GROUPS);
  // 從該部件群組選3個「有此部件」的字，再加1個沒有此部件的（混淆項）
  const correctChars = pick(group.chars, 3);
  const allOtherChars = RADICAL_GROUPS
    .filter(g => g.radical !== group.radical)
    .flatMap(g => g.chars);
  const wrongChar = rand(allOtherChars);
  const chars = shuffle([...correctChars, wrongChar]);
  return {
    type:'radical',
    radical: group.radical,
    label: group.label,
    chars,
    answer: wrongChar,   // 選「不屬於此部件」的那一個
    key:`rad:${group.radical}:${wrongChar}`
  };
}

function genTrueFalseQ() {
  const q = rand(TRUE_FALSE_Q);
  return { type:'true_false', ...q, key:`tf:${q.text.slice(0,14)}` };
}

const GEN_FNS = [
  genZhuyinQ, genZhuyinQ,          // 注音佔比高一點
  genCharFillQ, genCharFillQ,       // 看注音選字
  genClassifierQ,                   // 量詞
  genRedupQ,                        // 疊字詞
  genFillBlankQ, genFillBlankQ,     // 填空
  genWrongCharQ,                    // 改錯字
  genRadicalQ,                      // 部首
  genTrueFalseQ,                    // ○×
];

function genQuestionSet(total) {
  const set = [], seen = new Set();
  let guard = 0;
  while (set.length < total && guard < total * 40) {
    guard++;
    const q = rand(GEN_FNS)();
    if (seen.has(q.key)) continue;
    seen.add(q.key);
    set.push(q);
  }
  return set;
}

// =====================================================================
// 狀態 & localStorage
// =====================================================================
let state = { index:0, score:0, questions:[], total:10 };
const app = document.getElementById('app');

const LS_SCORES = 'cq_scores';
const LS_WRONGS = 'cq_wrongs';
function lsGet(k) { try { return JSON.parse(localStorage.getItem(k)||'[]'); } catch { return []; } }
function lsSet(k,v) { try { localStorage.setItem(k,JSON.stringify(v)); } catch {} }

function saveScore(score, total) {
  const s = lsGet(LS_SCORES);
  const now = new Date();
  const label = `${now.getMonth()+1}/${now.getDate()} ${now.getHours()}:${String(now.getMinutes()).padStart(2,'0')}`;
  s.unshift({ date:label, score, total });
  lsSet(LS_SCORES, s.slice(0,10));
}
function saveWrong(q) {
  const ws = lsGet(LS_WRONGS);
  if (!ws.find(w => w.key === q.key)) ws.unshift(q);
  lsSet(LS_WRONGS, ws.slice(0,60));
}
function clearWrongs() { lsSet(LS_WRONGS, []); }

// =====================================================================
// 開始畫面（含題數選擇 + 歷史記錄）
// =====================================================================
function renderStart() {
  const scores = lsGet(LS_SCORES).slice(0, 5);
  const wrongs = lsGet(LS_WRONGS);

  const scoresHtml = scores.length
    ? scores.map(s => {
        const pct = Math.round(s.score/s.total*100);
        const color = pct>=80?'#2e7d32':pct>=60?'#e67e22':'#c0392b';
        return `<div class="history-row">
          <span>${s.date}</span>
          <span>${s.score}/${s.total}</span>
          <span class="history-score" style="color:${color}">${pct}%</span>
        </div>`;
      }).join('')
    : '<div style="color:#aaa;font-size:13px;text-align:center;padding:8px">尚無記錄</div>';

  const wrongChips = wrongs.slice(0,15).map(q => {
    const label = q.char || q.answer || q.wrongChar || '?';
    return `<span class="wrong-chip">${label}</span>`;
  }).join('');

  app.innerHTML = `
    <h1>📚 國語小練習</h1>
    <div class="sub">仿考卷題型 · 每次不一樣</div>
    <div class="version-tag">v${VERSION}</div>

    ${wrongs.length >= 3 ? `
    <div class="card" style="border:2px solid #fde0e0;padding:12px 16px;">
      <div class="btn danger" id="retryBtn" style="margin:0">🔁 重測錯題（${wrongs.length} 題）</div>
    </div>` : ''}

    <div class="card">
      <div class="section-title">選擇題數</div>
      <div class="count-btns">
        <button class="count-btn" data-n="10">10題</button>
        <button class="count-btn" data-n="20">20題</button>
        <button class="count-btn" data-n="30">30題</button>
        <button class="count-btn" data-n="50">50題</button>
      </div>
      <div class="btn primary" id="startBtn">開始練習 ▶</div>
      <div class="admin-link" id="adminLink">🔧 題庫總覽（老師用）</div>
    </div>

    ${scores.length ? `
    <div class="card">
      <div class="admin-section">📊 最近成績</div>
      ${scoresHtml}
    </div>` : ''}

    ${wrongs.length ? `
    <div class="card">
      <div class="admin-section" style="display:flex;justify-content:space-between;align-items:center">
        <span>❌ 累積錯題</span>
        <span id="clearWrong" style="font-size:12px;color:#aaa;cursor:pointer;text-decoration:underline">清除</span>
      </div>
      <div style="margin-top:6px">${wrongChips}</div>
    </div>` : ''}
  `;

  let selectedN = 10;
  function setN(n) {
    selectedN = n;
    document.querySelectorAll('.count-btn').forEach(b => b.classList.toggle('active', +b.dataset.n === n));
  }
  setN(10);
  document.querySelectorAll('.count-btn').forEach(b => { b.onclick = () => setN(+b.dataset.n); });
  document.getElementById('startBtn').onclick = () => {
    state = { index:0, score:0, questions:genQuestionSet(selectedN), total:selectedN };
    renderQuestion();
  };
  const retryBtn = document.getElementById('retryBtn');
  if (retryBtn) retryBtn.onclick = startRetry;
  const clearBtn = document.getElementById('clearWrong');
  if (clearBtn) clearBtn.onclick = () => { clearWrongs(); renderStart(); };
  document.getElementById('adminLink').onclick = renderAdmin;
}

// 重測錯題
function startRetry() {
  const wrongs = lsGet(LS_WRONGS);
  if (!wrongs.length) return renderStart();
  const questions = shuffle(wrongs).slice(0, Math.min(wrongs.length, 20));
  state = { index:0, score:0, questions, total:questions.length };
  renderQuestion();
}

// =====================================================================
// 題目畫面
// =====================================================================
function renderQuestion() {
  const q = state.questions[state.index];
  const pct = Math.round(state.index / state.questions.length * 100);
  const hdr = `
    <div class="quiz-hdr">
      <div>
        <div class="progress">第 ${state.index+1} 題 / 共 ${state.questions.length} 題</div>
        <div class="score">得分：${state.score}</div>
      </div>
      <button class="exit-btn" id="exitBtn">✕ 離開</button>
    </div>
    <div class="progress-bar"><div class="progress-fill" style="width:${pct}%"></div></div>
  `;
  const dispatch = {
    zhuyin: renderZhuyinQ,
    char_fill: renderCharFillQ,
    classifier: renderClassifierQ,
    redup: renderRedupQ,
    fill_blank: renderFillBlankQ,
    wrong_char: renderWrongCharQ,
    radical: renderRadicalQ,
    true_false: renderTrueFalseQ,
  };
  (dispatch[q.type] || renderFillBlankQ)(hdr, q);
  document.getElementById('exitBtn').onclick = renderStart;
}

function typeTag(label) {
  return `<div class="q-type">${label}</div>`;
}

// --- 注音題：給字，選注音 ---
function renderZhuyinQ(hdr, q) {
  app.innerHTML = `
    ${hdr}
    <div class="card">
      ${typeTag('寫注音')}
      <div class="question">「<span class="big-char">${q.char}</span>」${annotate('的正確注音是？')}</div>
      <div id="choices"></div>
      <div class="feedback" id="fb"></div>
    </div>
  `;
  // options 是注音字串，選項顯示直排
  renderChoices(q.options, q.answer, zyVertical);
}

// --- 看注音選字：給注音+句子，選字 ---
function renderCharFillQ(hdr, q) {
  const hide = new Set([...q.answer]);
  app.innerHTML = `
    ${hdr}
    <div class="card">
      ${typeTag('看注音選字')}
      <div class="question">${annotate(q.before, hide)}</div>
      <div class="zy-hint">${zyVertical(q.zhuyin)}</div>
      <div class="q-sub">${annotate('這個空格應填哪個字？', hide)}</div>
      <div id="choices"></div>
      <div class="feedback" id="fb"></div>
    </div>
  `;
  renderChoices(q.options, q.answer);
}

// --- 量詞題 ---
function renderClassifierQ(hdr, q) {
  const hide = new Set([...q.answer]);
  app.innerHTML = `
    ${hdr}
    <div class="card">
      ${typeTag('量詞')}
      <div class="question">${annotate(`一（　）${q.word}`, hide)}<br>${annotate('該填哪個量詞？', hide)}</div>
      <div id="choices"></div>
      <div class="feedback" id="fb"></div>
    </div>
  `;
  renderChoices(q.options, q.answer);
}

// --- 疊字詞題 ---
function renderRedupQ(hdr, q) {
  app.innerHTML = `
    ${hdr}
    <div class="card">
      ${typeTag('疊字詞')}
      <div class="question">${annotate('哪一個詞有')}<br>「${annotate('重複的字')}」？</div>
      <div id="choices"></div>
      <div class="feedback" id="fb"></div>
    </div>
  `;
  renderChoices(q.options, q.answer);
}

// --- 填空題 ---
function renderFillBlankQ(hdr, q) {
  const hide = new Set([...q.answer]);
  app.innerHTML = `
    ${hdr}
    <div class="card">
      ${typeTag('填空')}
      <div class="question">${annotate(q.sent, hide)}</div>
      <div id="choices"></div>
      <div class="feedback" id="fb"></div>
    </div>
  `;
  renderChoices(q.options, q.answer);
}

// --- 改錯字題 ---
function renderWrongCharQ(hdr, q) {
  const hide = new Set([q.answer]);
  const marker = `【${q.wrongChar}】`;
  const idx = q.text.indexOf(marker);
  const wrongZy = ZHUYIN[q.wrongChar];
  const wrongHtml = wrongZy
    ? `<ruby>${q.wrongChar}<rt>${wrongZy}</rt></ruby>`
    : q.wrongChar;
  const highlighted =
    annotate(q.text.slice(0, idx), hide) +
    `<span class="err-char">【${wrongHtml}】</span>` +
    annotate(q.text.slice(idx + marker.length), hide);
  app.innerHTML = `
    ${hdr}
    <div class="card">
      ${typeTag('改錯字')}
      <div class="question">${highlighted}</div>
      <div class="q-sub">${annotate('紅色那個字寫錯了，正確應該是？', hide)}</div>
      <div id="choices"></div>
      <div class="feedback" id="fb"></div>
    </div>
  `;
  renderChoices(q.options, q.answer);
}

// --- 部首題：4字選不同部件的那個 ---
function renderRadicalQ(hdr, q) {
  const hide = new Set([q.answer]);
  app.innerHTML = `
    ${hdr}
    <div class="card">
      ${typeTag('部首部件')}
      <div class="question">${annotate('以下四個字，哪一個', hide)}<strong>${annotate('沒有', hide)}</strong>「${q.radical}」（${annotate(q.label, hide)}）？</div>
      <div id="choices"></div>
      <div class="feedback" id="fb"></div>
    </div>
  `;
  renderChoices(q.chars, q.answer);
}

// --- ○× 題 ---
function renderTrueFalseQ(hdr, q) {
  app.innerHTML = `
    ${hdr}
    <div class="card">
      ${typeTag('○ × 判斷')}
      <div class="question">${annotate(q.text)}</div>
      <div class="tf-row" id="choices">
        <button class="tf-btn tf-o" data-val="true">○</button>
        <button class="tf-btn tf-x" data-val="false">✕</button>
      </div>
      <div class="feedback" id="fb"></div>
    </div>
  `;
  let locked = false;
  document.querySelectorAll('.tf-btn').forEach(btn => {
    btn.onclick = () => {
      if (locked) return;
      locked = true;
      const ok = (btn.dataset.val === 'true') === q.answer;
      btn.classList.add(ok ? 'correct' : 'wrong');
      const other = btn.dataset.val === 'true'
        ? document.querySelector('.tf-x') : document.querySelector('.tf-o');
      if (!ok) other.classList.add('correct');
      showFeedback(ok, q.answer ? '○ 正確' : '✕ 錯誤');
    };
  });
}

// =====================================================================
// 共用選擇題渲染
// =====================================================================
function renderChoices(options, answer, displayFn) {
  const box = document.getElementById('choices');
  let locked = false;
  options.forEach(opt => {
    const el = document.createElement('div');
    el.className = 'choice';
    el.innerHTML = displayFn ? displayFn(opt) : opt;
    el.dataset.val = opt;
    el.onclick = () => {
      if (locked) return;
      locked = true;
      const ok = opt === answer;
      el.classList.add(ok ? 'correct' : 'wrong');
      if (!ok) {
        [...box.children].forEach(c => {
          if (c.dataset.val === answer) c.classList.add('correct');
        });
      }
      showFeedback(ok, displayFn ? displayFn(answer) : answer);
    };
    box.appendChild(el);
  });
}

function showFeedback(ok, correctHtml) {
  if (ok) state.score++;
  else saveWrong(state.questions[state.index]);
  const fb = document.getElementById('fb');
  fb.className = 'feedback ' + (ok ? 'ok' : 'bad');
  fb.innerHTML = ok ? '✅ 答對了！' : `❌ 正確答案：${correctHtml}`;
  const card = document.querySelector('.card');
  const btn = document.createElement('div');
  btn.className = 'btn primary';
  btn.textContent = state.index + 1 < state.questions.length ? '下一題 ▶' : '看結果 🎉';
  btn.onclick = () => {
    state.index++;
    if (state.index < state.questions.length) renderQuestion();
    else renderResult();
  };
  card.appendChild(btn);
}

// =====================================================================
// 結果畫面
// =====================================================================
function renderResult() {
  saveScore(state.score, state.questions.length);
  const pct = state.score / state.questions.length;
  const pctInt = Math.round(pct * 100);
  const stars = pct >= 0.9 ? '🌟🌟🌟' : pct >= 0.7 ? '🌟🌟' : pct >= 0.5 ? '🌟' : '';
  const msg = pct >= 0.8 ? '太厲害了！' : pct >= 0.6 ? '不錯喔，繼續加油！' : '再練習一次就會更好！';
  const wrongs = lsGet(LS_WRONGS);
  const wrongChips = wrongs.slice(0,12).map(q => {
    const label = q.char || q.answer || q.wrongChar || '?';
    return `<span class="wrong-chip">${label}</span>`;
  }).join('');
  app.innerHTML = `
    <h1>📚 國語小練習</h1>
    <div class="card">
      <div class="result-score">${pctInt}<span class="result-pct-sign">%</span></div>
      <div class="result-detail">${state.score} / ${state.questions.length} 題答對 ${stars}</div>
      <div class="result-msg">${msg}</div>
      ${wrongs.length ? `<div style="margin:10px 0 4px;font-size:13px;color:#888;">累積錯題：</div><div>${wrongChips}</div>` : ''}
      <div class="btn primary" id="againBtn" style="margin-top:16px">再玩一次 🔁</div>
      ${wrongs.length ? `<div class="btn danger" id="retryBtn">重測錯題（${wrongs.length}題）</div>` : ''}
      <div class="btn" id="homeBtn">回首頁</div>
    </div>
  `;
  document.getElementById('againBtn').onclick = () => {
    state = { index:0, score:0, questions:genQuestionSet(state.total), total:state.total };
    renderQuestion();
  };
  const retryBtn = document.getElementById('retryBtn');
  if (retryBtn) retryBtn.onclick = startRetry;
  document.getElementById('homeBtn').onclick = renderStart;
}

// =====================================================================
// 管理員題庫瀏覽
// =====================================================================
function renderAdmin() {
  const wordHtml = WORDS.map(withRuby).join('、');
  const clsHtml = CLASSIFIERS.map(c => `一（${c.answer}）${withRuby(c.word)}`).join('　');
  const rdHtml = REDUP_WORDS.map(withRuby).join('、');
  const radHtml = RADICAL_GROUPS.map(g =>
    `<div><b>「${g.radical}」${g.label}：</b>${g.chars.join(' ')}</div>`).join('');
  const tfHtml = TRUE_FALSE_Q.map(q =>
    `<div>${q.answer ? '○' : '✕'} ${q.text}</div>`).join('');

  app.innerHTML = `
    <h1>🔧 題庫總覽</h1>
    <div class="card"><div class="admin-section">📖 詞語（共 ${WORDS.length} 個）</div>
      <div class="admin-body">${wordHtml}</div></div>
    <div class="card"><div class="admin-section">📏 量詞（${CLASSIFIERS.length} 組）</div>
      <div class="admin-body">${clsHtml}</div></div>
    <div class="card"><div class="admin-section">🔁 疊字詞</div>
      <div class="admin-body">${rdHtml}</div></div>
    <div class="card"><div class="admin-section">🧩 部首部件（${RADICAL_GROUPS.length} 組）</div>
      <div class="admin-body">${radHtml}</div></div>
    <div class="card"><div class="admin-section">○× 判斷題（${TRUE_FALSE_Q.length} 題）</div>
      <div class="admin-body">${tfHtml}</div></div>
    <div class="btn primary" id="backBtn">⬅ 返回</div>
  `;
  document.getElementById('backBtn').onclick = renderStart;
}

// ── 整合 data.js 的課本資料 ──────────────────────────────────
(function mergeData() {
  if (typeof ZHUYIN_EXT !== 'undefined') Object.assign(ZHUYIN, ZHUYIN_EXT);
  if (typeof TEXTBOOK_FILL_Q !== 'undefined') FILL_BLANK_Q.push(...TEXTBOOK_FILL_Q);
  if (typeof TEXTBOOK_CHAR_Q !== 'undefined') CHAR_FILL_Q.push(...TEXTBOOK_CHAR_Q);
  if (typeof TEXTBOOK_TF_Q !== 'undefined') TRUE_FALSE_Q.push(...TEXTBOOK_TF_Q);
  if (typeof BUSHOU_DB !== 'undefined') {
    const byRad = {};
    Object.entries(BUSHOU_DB).forEach(([ch, b]) => {
      (byRad[b] = byRad[b] || []).push(ch);
    });
    Object.entries(byRad).forEach(([rad, chars]) => {
      if (chars.length >= 4 && !RADICAL_GROUPS.find(g => g.radical === rad)) {
        RADICAL_GROUPS.push({ radical: rad, label: rad, chars });
      }
    });
  }
})();

renderStart();
