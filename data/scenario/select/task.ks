; select/task.ks - 課題選択画面
*start
[mask time=500]
[clearfix]
[wait time=500]
[bg storage="黒板.png" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

[iscript]
$('#task_area,#task_tabs,.sel_back_btn').remove();
[endscript]

; ── タイトル ──────────────────────────────────────────────
[ptext name="task_title" layer="fix" text="🖊 課題パート" size="28" color="0xFFFFFF" bold="true" x="500" y="72" width="700" align="center"]

; ── 戻るボタン ────────────────────────────────────────────
[glink name="sel_back_btn" color="mybtn_09" text="戻る↩" target="*back_home" width="200" size="20" x="100" y="15"]

; task.ks が表示されるたびに未読エピソードフラグを再計算
[iscript]
    if (!f.has_unread_lecture && f.all_tasks && f.all_tasks._categories) {
        var _unlockedCount;
        if (f.user_role === 'control') {
            var _clearedPerCat = f.all_tasks._categories.map(function(c) {
                return Object.keys(f.all_tasks).filter(function(k) {
                    return /^task[0-9]+$/.test(k) && f.all_tasks[k].category === c.label;
                }).filter(function(k) {
                    return f.cleared_tasks && f.cleared_tasks[k];
                }).length;
            });
            _unlockedCount = _clearedPerCat.filter(function(n) { return n >= 3; }).length + 1;
        } else {
            _unlockedCount = parseInt(f.level) || 1;
        }
        var _hasUnread = false;
        for (var _i = 1; _i <= Math.min(_unlockedCount, 5); _i++) {
            if (!f.watched_lectures || !f.watched_lectures[_i]) {
                _hasUnread = true;
                break;
            }
        }
        f.has_unread_lecture = _hasUnread;
    }
[endscript]

[ptext name="new_episode_tag" layer="fix" text="NEW" color="0xFF3333" bold="true" size="18" edge="2px white" x="315" y="10" cond="f.has_unread_lecture == true"]

; ── スクロールエリア ──────────────────────────────────────
[scroll_area_vertical id="task_area" top=157 left=500 width=700 height=508 contents_h=600 zindex=1000000]

; ══════════════════════════════════════════════════════════
; ▼ 事前計算
; ══════════════════════════════════════════════════════════
[iscript]
    var tasks = f.all_tasks;
    var cats  = tasks._categories;
    var BTN_H = 60, BTN_MARGIN = 16, BTN_STEP = BTN_H + BTN_MARGIN;

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

    window._sd_task = {};
    var maxTaskNum = 0;
    Object.keys(catTaskLists).forEach(function(cat) {
        catTaskLists[cat].forEach(function(key, pos) {
            var i       = parseInt(key.replace('task',''));
            var cleared = !!(f.cleared_tasks && f.cleared_tasks[key]);
            if (i > maxTaskNum) maxTaskNum = i;
            window._sd_task[i] = {
                y:       pos * BTN_STEP + 50,
                name:    't_btn_task' + i,
                chkId:   't_chk_' + key,        // チェックボックス用ID兼クラス名
                label:   tasks[key].title.replace(/^課題\d+[:：]\s*/, ''),
                cleared: cleared,
                color:   'mybtn_08',
                target:  '*common_task_start',
                taskId:  key
            };
        });
    });
    tf.task_max = maxTaskNum;

    window._getTaskData = function(i) { return window._sd_task[i]; };
[endscript]

; ══════════════════════════════════════════════════════════
; ▼ タスクボタン＋チェックボックス
; ══════════════════════════════════════════════════════════
[for name="tf.i" from="1" to="&tf.task_max"]
    [iscript]
        var d = window._getTaskData(parseInt(tf.i));
        if (!d) {
            tf.skip = true;
        } else {
            tf.skip       = false;
            tf.btn_y      = d.y;
            tf.btn_name   = d.name;
            tf.btn_label  = d.label;
            tf.btn_color  = d.color;
            tf.btn_target = d.target;
        }
    [endscript]
    [if exp="tf.skip == false"]
        [glink name="&tf.btn_name" color="&tf.btn_color" text="&tf.btn_label" x="50" y="&tf.btn_y" width="500" height="60" size="18" target="&tf.btn_target" exp="&'f.current_task_id = \"task' + tf.i + '\"'"]
        [scroll_area_vertical_in id="task_area" name="&tf.btn_name"]
        [iscript]
        // ボタン右隣にチェックボックスを配置
        var d = window._getTaskData(parseInt(tf.i));
        $('<div>')
            .attr('id', d.chkId)
            .addClass(d.chkId)
            .css({
                position:        'absolute',
                left:            '600px',
                top:             d.y + 'px',
                width:           '60px',
                height:          '60px',
                'line-height':   '60px',
                'text-align':    'center',
                'font-size':     '34px',
                'z-index':       11,
                'pointer-events':'none',
                color: d.cleared ? '#009959' : 'rgb(252, 252, 252)'
            })
            .text(d.cleared ? '☑' : '☐')
            .appendTo($('#task_area_inner'));
        [endscript]
    [endif]
[nextfor]

; ══════════════════════════════════════════════════════════
; ▼ 課題タブUI
; ══════════════════════════════════════════════════════════
[iscript]
    var $fix = TYRANO.kag.layer.getLayer("fix");
    var cats = f.all_tasks._categories;
    var TAB_H = 42;
    var C_ON = '#27ae60', C_OFF = 'rgba(0,0,0,0.55)', C_HOV = 'rgba(0,110,80,0.65)';

    window._sel_taskMap = {};
    window._sel_curCat  = 0;
    cats.forEach(function(c, idx) { window._sel_taskMap[idx] = []; });
    Object.keys(f.all_tasks).forEach(function(key) {
        if (!/^task\d+$/.test(key)) return;
        var catIdx = cats.findIndex(function(c) { return c.label === f.all_tasks[key].category; });
        if (catIdx >= 0) {
            window._sel_taskMap[catIdx].push('.t_btn_' + key);
            window._sel_taskMap[catIdx].push('.t_chk_' + key); // チェックボックスも連動
        }
    });

    cats.forEach(function(c, idx) {
        if (idx === 0) return;
        window._sel_taskMap[idx].forEach(function(s) { $(s).hide(); });
    });

    window._sel_switch = function(newIdx) {
        window._sel_taskMap[window._sel_curCat].forEach(function(s) { $(s).hide(); });
        window._sel_taskMap[newIdx].forEach(function(s) { $(s).show(); });
        $('#task_area_view').scrollTop(0);
        window._sel_curCat = newIdx;
    };

    // タブラベルにクリア数を表示（例: 基本 3/6）
    var catTaskLists = {};
    cats.forEach(function(c) { catTaskLists[c.label] = []; });
    Object.keys(f.all_tasks).forEach(function(key) {
        if (!/^task\d+$/.test(key) || !f.all_tasks[key].category) return;
        catTaskLists[f.all_tasks[key].category].push(key);
    });

    var $row = $('<div>').attr('id', 'task_tabs').css({
        position:'absolute', top:'115px', left:'500px',
        width:'700px', height:TAB_H+'px',
        display:'flex', 'z-index':1000002,
        'border-radius':'10px 10px 0 0', overflow:'hidden'
    });
    cats.forEach(function(cat, idx) {
        var total   = catTaskLists[cat.label].length;
        var cleared = catTaskLists[cat.label].filter(function(k) {
            return f.cleared_tasks && f.cleared_tasks[k];
        }).length;
        var tabLabel = cat.short + ' ' + cleared + '/' + total;

        var $tab = $('<div>').text(tabLabel)
            .addClass('_sel_tab').attr('data-idx', idx).css({
                flex:'1', height:TAB_H+'px', 'line-height':TAB_H+'px',
                'text-align':'center', cursor:'pointer', 'font-size':'13px',
                color:'white',
                background:    idx === 0 ? C_ON : C_OFF,
                'font-weight': idx === 0 ? 'bold' : 'normal',
                'border-right': idx < cats.length - 1 ? '1px solid rgba(255,255,255,0.2)' : 'none',
                'user-select':'none', transition:'background 0.15s'
            });
        $tab.on('mouseenter', function() {
            if (parseInt($(this).attr('data-idx')) !== window._sel_curCat) $(this).css('background', C_HOV);
        }).on('mouseleave', function() {
            if (parseInt($(this).attr('data-idx')) !== window._sel_curCat) $(this).css('background', C_OFF);
        }).on('click', function() {
            var newIdx = parseInt($(this).attr('data-idx'));
            if (newIdx === window._sel_curCat) return;
            $('._sel_tab').css({ background: C_OFF, 'font-weight': 'normal' });
            $('._sel_tab[data-idx="' + newIdx + '"]').css({ background: C_ON, 'font-weight': 'bold' });
            window._sel_switch(newIdx);
        });
        $row.append($tab);
    });
    $fix.append($row);
[endscript]

[mask_off time=500]
[s]

; ══════════════════════════════════════════════════════════
; ▼ ハンドラ
; ══════════════════════════════════════════════════════════

*back_home
[scroll_area_vertical_del id="task_area"]
[iscript]
$('#lecture_area,#task_area,#task_tabs,.sel_back_btn').remove();
[endscript]
[clearfix]
[jump storage="home.ks" target="*start"]

*common_task_start
[scroll_area_vertical_del id="task_area"]
[iscript]
    $('#lecture_area,#task_area,#task_tabs,.sel_back_btn').remove();
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
