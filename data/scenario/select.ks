; select.ks - 課題・講義選択画面（カテゴリタブ版）
*start
[mask time=500]
[clearfix]

; ── 前回の残骸を確実に削除（エラー等で残った場合の保険） ────
[iscript]
$('#lecture_area,#task_area,#lecture_tabs,#task_tabs,.sel_back_btn').remove();
console.error(f.level);
[endscript]

[wait time=500]
[bg storage="黒板.png" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

; ── タイトル（ptextタグ） ────────────────────────────────────
[ptext name="lecture_title" layer="fix" text="📖 講義パート" size="28" color="0xFFFFFF" bold="true" x="30"  y="72" width="560" align="center"]
[ptext name="task_title"    layer="fix" text="🖊 課題パート"  size="28" color="0xFFFFFF" bold="true" x="640" y="72" width="560" align="center"]

; ── 戻るボタン（fix=trueを使わず、jQueryのnameで削除する） ──
; fix=trueはglink_exで正常動作しないため外す
[glink name="sel_back_btn" color="mybtn_09" text="戻る↩" target="*back_home" width="200" size="20" x="100" y="15"]

; ── スクロールエリアを作成 ────────────────────────────────────
; タブ行(42px) + 余白 = top 157
[scroll_area_vertical id="lecture_area" top=157 left=50  width=560 height=508 contents_h=450 zindex=1000000]
[scroll_area_vertical id="task_area"    top=157 left=640 width=560 height=508 contents_h=800 zindex=1000000]

; ── ボタンデータを全てforループの外で事前計算 ────────────────
; （forループ内のiscriptでの配列アクセスによるSyntaxError回避のため
;   アクセスはwindow._getXxx()経由にする）
[iscript]
var tasks = f.all_tasks;
var cats  = tasks._categories;
var BTN_H = 60, BTN_MARGIN = 16;

// カテゴリ内タスクリストを構築
var catTaskLists = {};
cats.forEach(function(c) { catTaskLists[c.label] = []; });
Object.keys(tasks).forEach(function(key) {
    if (!/^task\d+$/.test(key) || !tasks[key].category) return;
    catTaskLists[tasks[key].category].push(key);
});
Object.keys(catTaskLists).forEach(function(cat) {
    catTaskLists[cat].sort(function(a,b){
        return parseInt(a.replace('task','')) - parseInt(b.replace('task',''));
    });
});

// タスクボタンデータを格納
window._sd_task = {};
var maxTaskNum = 0;
Object.keys(catTaskLists).forEach(function(cat) {
    catTaskLists[cat].forEach(function(key, pos) {
        var i = parseInt(key.replace('task',''));
        if (i > maxTaskNum) maxTaskNum = i;
        var prevId  = pos > 0 ? catTaskLists[cat][pos-1] : null;
        var locked  = prevId !== null && (!f.cleared_tasks || !f.cleared_tasks[prevId]);
        window._sd_task[i] = {
            y:      pos * (BTN_H + BTN_MARGIN) + 50,
            name:   't_btn_task' + i,
            label:  '課題' + i + ': ' + tasks[key].title.replace(/^課題\d+[:：]\s*/, ''),
            color:  locked ? 'mybtn_locked' : 'mybtn_08',
            target: locked ? '*locked' : '*common_task_start',
            locked: locked,
            taskId: key
        };
    });
});
tf.task_max = maxTaskNum;

// 講義ボタンデータ
window._sd_lec = {};
for (var i = 1; i <= 5; i++) {
    window._sd_lec[i] = {
        y: (i - 1) * (BTN_H + BTN_MARGIN) + 50,
        name: 'l_btn_ep' + i,
        label: 'ep.' + i,
        lec_num: i,
        locked: f.level < i,
        color: (f.level < i)
            ? 'mybtn_locked'
            : 'mybtn_10',
        target: (f.level < i)
            ? '*locked'
            : '*lecture_jump'
    };
}

tf.lec_max = 5;

// 取得用
window._getLecData = function(i) {
    return window._sd_lec[i];
};

// forループ内からアクセスするためのヘルパー関数
// （直接window._sd_task[n]と書くと[n]がタグ解析される恐れがあるため）
window._getTaskData = function(i) { return window._sd_task[i]; };
window._getLecData  = function(i) { return window._sd_lec[i];  };
[endscript]

; ── タスクボタン forループ ────────────────────────────────────
[for name="tf.i" from="1" to="&tf.task_max"]
    [iscript]
    var d = window._getTaskData(parseInt(tf.i));
    if (!d) {
        tf.skip = true;
    } else {
        tf.skip      = false;
        tf.btn_y     = d.y;
        tf.btn_name  = d.name;
        tf.btn_label = d.label;
        tf.btn_color  = d.color;
        tf.btn_target = d.target;
    }
    [endscript]
    [if exp="tf.skip == false"]
        [glink name="&tf.btn_name" color="&tf.btn_color" text="&tf.btn_label" x="50" y="&tf.btn_y" width="440" height="60" size="18" target="&tf.btn_target" exp="&'f.current_task_id = \"task' + tf.i + '\"'" ]
        [scroll_area_vertical_in id="task_area" name="&tf.btn_name"]
    [endif]
[nextfor]

; ── 講義ボタン ─────────────────────

[for name="tf.li" from="1" to="5"]

    [iscript]
    var d = window._getLecData(parseInt(tf.li));

    tf.lec_name   = d.name;
    tf.lec_label  = d.label;
    tf.lec_color  = d.color;
    tf.lec_target = d.target;
    tf.lec_y      = d.y;
    [endscript]

    [glink name="&tf.lec_name" storage="select.ks" target="&tf.lec_target" color="&tf.lec_color" text="&tf.lec_label" x="50" y="&tf.lec_y" width="440" height="60" size="20" exp="&'tf.target_lecture_num='+tf.li"]

    [scroll_area_vertical_in id="lecture_area" name="&tf.lec_name"]

[nextfor]

; ── タブUIと初期表示制御（iscriptはここだけ） ────────────────
[iscript]

var $fix = TYRANO.kag.layer.getLayer("fix");
var cats = f.all_tasks._categories;

window._sel_taskMap = {};
window._sel_curCat  = 0;

cats.forEach(function(c, idx) {
    window._sel_taskMap[idx] = [];
});
Object.keys(f.all_tasks).forEach(function(key) {
    if (!/^task\d+$/.test(key)) return;
    var catIdx = cats.findIndex(function(c){ return c.label === f.all_tasks[key].category; });
    if (catIdx >= 0) window._sel_taskMap[catIdx].push('.t_btn_' + key);
});

// カテゴリ0以外を非表示
cats.forEach(function(c, idx) {
    if (idx === 0) return;
    window._sel_taskMap[idx].forEach(function(s){ $(s).hide(); });
});

// タブ切り替え
window._sel_switch = function(newIdx) {
    window._sel_taskMap[window._sel_curCat].forEach(function(s){ $(s).hide(); });
    window._sel_taskMap[newIdx].forEach(function(s){ $(s).show(); });
    $('#task_area_view').scrollTop(0);
    window._sel_curCat = newIdx;
};

// タブ行を生成
var TAB_H = 42;
var C_ON='#27ae60', C_OFF='rgba(0,0,0,0.55)', C_HOV='rgba(0,110,80,0.65)';

function buildTabRow(rowId, top, left, width) {
    var $row = $('<div>').attr('id', rowId).css({
        position:'absolute', top:top+'px', left:left+'px',
        width:width+'px', height:TAB_H+'px',
        display:'flex', 'z-index':1000002,
        'border-radius':'10px 10px 0 0', overflow:'hidden'
    });
    cats.forEach(function(cat, idx) {
        var $tab = $('<div>').text(cat.short)
            .addClass('_sel_tab').attr('data-idx', idx).css({
                flex:'1', height:TAB_H+'px', 'line-height':TAB_H+'px',
                'text-align':'center', cursor:'pointer', 'font-size':'14px',
                color:'white',
                background: idx===0 ? C_ON : C_OFF,
                'font-weight': idx===0 ? 'bold' : 'normal',
                'border-right': idx<cats.length-1 ? '1px solid rgba(255,255,255,0.2)' : 'none',
                'user-select':'none', transition:'background 0.15s'
            });
        $tab.on('mouseenter', function(){
            if (parseInt($(this).attr('data-idx'))!==window._sel_curCat) $(this).css('background',C_HOV);
        }).on('mouseleave', function(){
            if (parseInt($(this).attr('data-idx'))!==window._sel_curCat) $(this).css('background',C_OFF);
        }).on('click', function(){
            var newIdx = parseInt($(this).attr('data-idx'));
            if (newIdx===window._sel_curCat) return;
            $('._sel_tab').css({background:C_OFF,'font-weight':'normal'});
            $('._sel_tab[data-idx="'+newIdx+'"]').css({background:C_ON,'font-weight':'bold'});
            window._sel_switch(newIdx);
        });
        $row.append($tab);
    });
    $fix.append($row);
}

buildTabRow('task_tabs', 115, 640, 560);

[endscript]

[mask_off time=500]
[s]

; ──────────────────────────────────────────────────────────
; ▼ ハンドラ
; 全パスで scroll_area_del → jQuery直接削除（保険）→ clearfix
; ──────────────────────────────────────────────────────────

*lecture_jump
[scroll_area_vertical_del id="lecture_area"]
[scroll_area_vertical_del id="task_area"]
[iscript]
$('#lecture_area,#task_area,#lecture_tabs,#task_tabs,.sel_back_btn').remove();
[endscript]
[clearfix]
@layopt layer="message0" visible=true
[start_keyconfig]
[eval exp="tf.lecture_path='lecture/'+tf.target_lecture_num+'.ks'"]
[jump storage="&tf.lecture_path" target="*start"]

*locked
[dialog type="alert" text="前の課題をクリアすると解放されます。"]
[s]

*back_home
[scroll_area_vertical_del id="lecture_area"]
[scroll_area_vertical_del id="task_area"]
[iscript]
$('#lecture_area,#task_area,#lecture_tabs,#task_tabs,.sel_back_btn').remove();
[endscript]
[clearfix]
[jump storage="home.ks" target="*start"]

*common_task_start
[scroll_area_vertical_del id="lecture_area"]
[scroll_area_vertical_del id="task_area"]
[clearfix]
[iscript]
$('#lecture_area,#task_area,#lecture_tabs,#task_tabs,.sel_back_btn').remove();
var taskData = f.all_tasks[f.current_task_id];
if (taskData) {
    f.my_code = Array.isArray(taskData.initial_code)
        ? taskData.initial_code.join('\n')
        : taskData.initial_code;
} else {
    f.my_code = '// 課題データが見つかりません: ' + f.current_task_id;
}
[endscript]
[clearfix]
[eval exp="f.is_sandbox=false"]
@layopt layer="message0" visible=true
[start_keyconfig]
[jump storage="editor.ks" target="*start"]
