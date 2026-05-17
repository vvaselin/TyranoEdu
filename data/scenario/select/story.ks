; select.ks - 課題・講義選択画面（カテゴリタブ版）
*start
[mask time=500]
[clearfix]
[wait time=500]
[bg storage="黒板.png" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

[iscript]
$('#lecture_area,.sel_back_btn').remove();
[endscript]

; ── タイトル ──────────────────────────────────────────────
[ptext name="lecture_title" layer="fix" text="📖 講義パート" size="28" color="0xFFFFFF" bold="true" x="640"  y="72" width="560" align="center"]

; ── 戻るボタン ────────────────────────────────────────────
[glink name="sel_back_btn" color="mybtn_09" text="戻る↩" target="*back_home" width="200" size="20" x="100" y="15"]

; ── スクロールエリア ──────────────────────────────────────
[scroll_area_vertical id="lecture_area" top=115 left=640  width=560 height=550 contents_h=450 zindex=1000000]

; ══════════════════════════════════════════════════════════
; ▼ 事前計算（forループ内でのSyntaxError回避のためヘルパー関数化）
; ══════════════════════════════════════════════════════════
[iscript]
    var tasks = f.all_tasks;
    var cats  = tasks._categories;
    var BTN_H = 60, BTN_MARGIN = 16, BTN_STEP = BTN_H + BTN_MARGIN;

    // ── カテゴリ別タスクリストを先に構築（講義・タスク両方で使用） ──
    var catTaskLists = {};
    cats.forEach(function(c) { catTaskLists[c.label] = []; });
    Object.keys(tasks).forEach(function(key) {
        if (!/^task\d+$/.test(key) || !tasks[key].category) return;
        catTaskLists[tasks[key].category].push(key);
    });
    Object.keys(catTaskLists).forEach(function(cat) {
        catTaskLists[cat].sort(function(a, b) {
            return parseInt(a.replace('task','')) - parseInt(b.replace('task',''));
        });
    });

    // ── 講義ボタンデータ ──────────────────────────────────
    // 統制群: 前カテゴリのクリア数が3問以上で解放
    // 実験群: f.level で解放
    var clearedPerCat = cats.map(function(cat) {
        return catTaskLists[cat.label].filter(function(key) {
            return f.cleared_tasks && f.cleared_tasks[key];
        }).length;
    });

    window._sd_lec = {};
    for (var i = 1; i <= 5; i++) {
        var locked;
        if (f.user_role === 'control') {
            // ep.1は常時解放、ep.i は前カテゴリ(cats[i-2])のクリア数が3以上で解放
            locked = i > 1 && clearedPerCat[i - 2] < 3;
        } else {
            locked = f.level < i;
        }
        window._sd_lec[i] = {
            y:      (i - 1) * BTN_STEP + 50,
            name:   'l_btn_ep' + i,
            label:  'ep.' + i,
            locked: locked,
            color:  locked ? 'mybtn_locked' : 'mybtn_10',
            target: locked ? '*locked'       : '*lecture_jump'
        };
    }
    tf.lec_max = 5;

    // forループ内からのアクセス用（[n]がタグ解析されるのを回避）
    window._getLecData  = function(i) { return window._sd_lec[i];  };
[endscript]

; ══════════════════════════════════════════════════════════
; ▼ 講義ボタン（タブなし）
; ══════════════════════════════════════════════════════════
[for name="tf.li" from="1" to="&tf.lec_max"]
    [iscript]
        var d = window._getLecData(parseInt(tf.li));
        tf.lec_name   = d.name;
        tf.lec_label  = d.label;
        tf.lec_y      = d.y;
        tf.lec_color  = d.color;
        tf.lec_target = d.target;
    [endscript]
    [glink name="&tf.lec_name" storage="select/story.ks" target="&tf.lec_target" color="&tf.lec_color" text="&tf.lec_label" x="50" y="&tf.lec_y" width="440" height="60" size="20" exp="&'tf.target_lecture_num='+tf.li"]
    [scroll_area_vertical_in id="lecture_area" name="&tf.lec_name"]
[nextfor]

[mask_off time=500]
[s]

; ══════════════════════════════════════════════════════════
; ▼ ハンドラ
; ══════════════════════════════════════════════════════════

*lecture_jump
[scroll_area_vertical_del id="lecture_area"]
[iscript]
$('#lecture_area,#task_area,#task_tabs,.sel_back_btn').remove();
[endscript]
[clearfix]
@layopt layer="message0" visible=true
[start_keyconfig]
[eval exp="tf.lecture_path='lecture/'+tf.target_lecture_num+'.ks'"]
[jump storage="&tf.lecture_path" target="*start"]

*locked
[dialog type="alert" text="前の課題をクリアすると解放されます。"]
[iscript]
$('.sel_back_btn').remove();
[endscript]
[glink name="sel_back_btn" color="mybtn_09" text="戻る↩" target="*back_home" width="200" size="20" x="100" y="15"]
[s]

*back_home
[clearfix]
[scroll_area_vertical_del id="lecture_area"]
[iscript]
$('#lecture_area,#task_area,#task_tabs,.sel_back_btn').remove();
[endscript]
[clearfix]
[jump storage="home.ks" target="*start"]