; select/task.ks - 課題選択画面（固定リスト＋詳細パネル）
*start
[mask time=500]
[hidemenubutton]
[clearfix]
[wait time=500]
[bg storage="黒板.png" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

[iscript]
$('.select_ui,#task_tabs,#lecture_area,#task_area,#task_title,#lecture_title,#new_episode_tag,.sel_back_btn').remove();
[endscript]

; ── 戻るボタン ────────────────────────────────────────────
[glink name="sel_back_btn" color="mybtn_09" text="戻る↩" target="*back_home" width="200" size="20" x="80" y="15"]
[glink name="sel_back_btn" color="mybtn_09" text="<span class='material-icons'>&#xe0b7;</span> エピソード" target="*toSelectStory" width="200" height="50" size="20" x="300" y="15"]

; task.ks が表示されるたびに未読エピソードフラグを再計算
[iscript]
    (function() {
        var cats = f.all_tasks && f.all_tasks._categories;
        if (!cats) { f.has_unread_lecture = false; return; }

        var unlockedCount;
        if (f.user_role === 'control') {
            var clearedPerCat = cats.map(function(c) {
                return Object.keys(f.all_tasks).filter(function(k) {
                    return /^task\d+$/.test(k) && f.all_tasks[k].category === c.label;
                }).filter(function(k) {
                    return f.cleared_tasks && f.cleared_tasks[k];
                }).length;
            });
            unlockedCount = clearedPerCat.filter(function(n) { return n >= 2; }).length + 1;
        } else {
            var love = parseInt(f.love_level) || 0;
            var gaugeState = window.AppProgressConfig.getLoveGaugeState(love);
            f.level = gaugeState.level;
            unlockedCount = window.AppProgressConfig.getUnlockedCountByLove(love, 5);
        }

        var hasUnread = false;
        for (var j = 1; j <= Math.min(unlockedCount, 5); j++) {
            if (!f.watched_lectures || !f.watched_lectures[j]) {
                hasUnread = true;
                break;
            }
        }
        f.has_unread_lecture = hasUnread;
    })();
[endscript]

; ══════════════════════════════════════════════════════════
; ▼ 固定UI
; ══════════════════════════════════════════════════════════
[iscript]
(function() {
    var $fix = TYRANO.kag.layer.getLayer("fix");
    var tasks = f.all_tasks || {};
    var cats = tasks._categories || [];
    var clearedTasks = f.cleared_tasks || {};

    function cleanupSelectUi() {
        $('.select_ui,#task_tabs,#lecture_area,#task_area,#task_title,#lecture_title,#new_episode_tag,.sel_back_btn').remove();
    }

    function escapeHtml(str) {
        return String(str == null ? '' : str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function nl2br(str) {
        return escapeHtml(str).replace(/\n/g, '<br>');
    }

    function summaryDescription(str) {
        return String(str == null ? '' : str).split(/出力形式(?:[^\n:：]*)?[:：]/)[0].trim();
    }

    function stars(n) {
        n = Math.max(1, Math.min(5, parseInt(n) || 1));
        return '★★★★★'.slice(0, n) + '☆☆☆☆☆'.slice(0, 5 - n);
    }

    function taskNumber(key) {
        return parseInt(String(key).replace('task', ''), 10) || 0;
    }

    var catTaskLists = {};
    cats.forEach(function(c) { catTaskLists[c.label] = []; });
    Object.keys(tasks).forEach(function(key) {
        if (!/^task\d+$/.test(key) || !tasks[key].category) return;
        if (!catTaskLists[tasks[key].category]) catTaskLists[tasks[key].category] = [];
        catTaskLists[tasks[key].category].push(key);
    });
    Object.keys(catTaskLists).forEach(function(cat) {
        catTaskLists[cat].sort(function(a, b) { return taskNumber(a) - taskNumber(b); });
    });

    function lowDifficultyClearedCount(catLabel) {
        return (catTaskLists[catLabel] || []).filter(function(key) {
            var task = tasks[key] || {};
            var difficulty = parseInt(task.difficulty, 10) || 1;
            return difficulty <= 2 && clearedTasks[key];
        }).length;
    }

    function highDifficultyTasksUnlocked() {
        if (!cats.length) return true;
        return cats.every(function(cat) {
            return lowDifficultyClearedCount(cat.label) >= 2;
        });
    }

    var isHighDifficultyUnlocked = highDifficultyTasksUnlocked();

    function isTaskLocked(taskId) {
        var task = tasks[taskId] || {};
        var difficulty = parseInt(task.difficulty, 10) || 1;
        return difficulty >= 3 && !isHighDifficultyUnlocked;
    }

    window._sel_curCat = 0;
    window._sel_selectedTaskId = (catTaskLists[cats[0] && cats[0].label] || [])[0] || null;

    var $root = $('<div>').addClass('select_ui').attr('id', 'task_select_ui').css({
        position: 'absolute',
        left: '0px',
        top: '0px',
        width: '1280px',
        height: '720px',
        'z-index': 1000000,
        color: '#fff',
        'font-family': 'sans-serif',
        'pointer-events': 'none'
    });

    var $title = $('<div>').addClass('select_ui').attr('id', 'task_title').html('🖋️ 課題選択').css({
        position: 'absolute',
        top: '100px',
        width: '1270px',
        height: '40px',
        'line-height': '40px',
        'text-align': 'center',
        'font-size': '28px',
        'font-weight': 'bold',
        'text-shadow': '0 2px 4px rgba(0,0,0,0.55)',
        'background': 'rgba(0, 0, 0, 0.8)',
        'pointer-events': 'none'
    });

    if (f.has_unread_lecture === true) {
        $('<div>').addClass('select_ui').attr('id', 'new_episode_tag').text('NEW').css({
            position: 'absolute',
            left: '470px',
            top: '2px',
            color: '#FF3333',
            'font-size': '28px',
            'font-weight': 'bold',
            '-webkit-text-stroke': '1px white',
            'pointer-events': 'none'
        }).appendTo($root);
    }

    var panelBase = {
        position: 'absolute',
        background: 'rgba(8, 42, 58, 0.90)',
        border: '2px solid rgba(255,255,255,0.90)',
        'box-shadow': '0 8px 18px rgba(0,0,0,0.28)',
        'border-radius': '8px',
        'pointer-events': 'auto'
    };

    var $detail = $('<div>').addClass('task_detail_panel').css($.extend({}, panelBase, {
        left: '700px',
        top: '160px',
        width: '500px',
        height: '530px',
        padding: '18px',
        'box-sizing': 'border-box'
    }));

    var $list = $('<div>').addClass('task_list_panel').css($.extend({}, panelBase, {
        left: '80px',
        top: '160px',
        width: '555px',
        height: '530px',
        padding: '62px 22px 20px',
        'box-sizing': 'border-box'
    }));

    var $tabs = $('<div>').attr('id', 'task_tabs').addClass('select_ui').css({
        position: 'absolute',
        left: '80px',
        top: '160px',
        width: '555px',
        height: '44px',
        display: 'flex',
        overflow: 'hidden',
        'border-radius': '8px 8px 0 0',
        'z-index': 1000002,
        'pointer-events': 'auto'
    });

    function renderDetail(taskId) {
        var task = tasks[taskId];
        if (!task) {
            $detail.html('<div style="font-size:22px;font-weight:bold;">課題データがありません</div>');
            return;
        }
        var cleared = !!clearedTasks[taskId];
        var locked = isTaskLocked(taskId);
        var desc = summaryDescription(task.description);
        var lockMessage = locked
            ? '<div style="font-size:15px;line-height:1.5;margin-bottom:10px;color:#ffd166;">難易度3以上の課題は、全カテゴリで難易度2以下を2問ずつクリアすると解放されます。</div>'
            : '';

        $detail.html(
            '<div style="font-size:13px;color:#a7f3d0;margin-bottom:6px;">' + escapeHtml(task.category || '') + '</div>' +
            '<div style="font-size:24px;font-weight:bold;line-height:1.25;margin-bottom:10px;">' + escapeHtml(task.title || taskId) + '</div>' +
            '<div style="display:flex;gap:8px;align-items:center;margin-bottom:12px;font-size:16px;">' +
                '<span style="color:#ffd166;">' + stars(task.difficulty || 1) + '</span>' +
                '<span style="padding:3px 9px;border-radius:999px;background:' + (cleared ? '#1f9d66' : '#666') + ';">' + (cleared ? 'クリア済み' : '未クリア') + '</span>' +
                (locked ? '<span style="padding:3px 9px;border-radius:999px;background:#777;">ロック中</span>' : '') +
            '</div>' +
            lockMessage +
            '<div style="font-size:16px;line-height:1.65;margin-bottom:70px;min-height:260px;max-height:360px;overflow:hidden;">' + nl2br(desc) + '</div>' +
            '<button id="task_start_btn" ' + (locked ? 'disabled' : '') + ' style="position:absolute;left:18px;bottom:18px;width:464px;height:48px;border:2px solid white;border-radius:8px;background:' + (locked ? '#777' : '#0f8b8d') + ';color:white;font-size:20px;font-weight:bold;cursor:' + (locked ? 'default' : 'pointer') + ';">' + (locked ? '未解放' : 'この課題を始める') + '</button>'
        );
        $('#task_start_btn').on('click', function() {
            if (locked) return;
            f.current_task_id = taskId;
            cleanupSelectUi();
            TYRANO.kag.ftag.startTag('jump', { target: '*common_task_start' });
        });
    }

    function renderTaskButtons(catIdx) {
        $list.find('.task_btn_row').remove();
        var cat = cats[catIdx];
        var list = cat ? (catTaskLists[cat.label] || []) : [];
        list.forEach(function(taskId, pos) {
            var task = tasks[taskId];
            var cleared = !!clearedTasks[taskId];
            var locked = isTaskLocked(taskId);
            var selected = taskId === window._sel_selectedTaskId;
            var $btn = $('<button>').addClass('task_btn_row').attr('data-task-id', taskId).css({
                position: 'absolute',
                left: '32px',
                top: (72 + pos * 90) + 'px',
                width: '435px',
                height: '58px',
                border: selected ? '3px solid #ffd166' : '3px solid white',
                'border-radius': '8px',
                background: locked ? '#777' : (selected ? '#0b9a9c' : '#087b7d'),
                color: 'white',
                'font-size': '17px',
                cursor: 'pointer',
                'box-shadow': '0 3px 0 rgba(0,0,0,0.35)',
                overflow: 'hidden',
                'white-space': 'nowrap',
                'text-overflow': 'ellipsis'
            }).text((locked ? '未解放: ' : '') + (task && task.title ? task.title : taskId).replace(/^課題\d+[-ー]\d+[:：]\s*/, ''));
            var $check = $('<span>').addClass('task_btn_row').css({
                position: 'absolute',
                left: '485px',
                top: (72 + pos * 90) + 'px',
                width: '42px',
                height: '58px',
                'line-height': '58px',
                'text-align': 'center',
                'font-size': '30px',
                color: cleared ? '#37ffab' : '#fff'
            }).text(cleared ? '☑' : '☐');
            $btn.on('click', function() {
                window._sel_selectedTaskId = taskId;
                renderTaskButtons(window._sel_curCat);
                renderDetail(taskId);
            });
            $list.append($btn).append($check);
        });
    }

    cats.forEach(function(cat, idx) {
        var cleared = lowDifficultyClearedCount(cat.label);
        var $tab = $('<div>').addClass('_sel_tab').attr('data-idx', idx).text(cat.short + ' ' + Math.min(cleared, 2) + '/' + 2).css({
            flex: '1',
            height: '44px',
            'line-height': '44px',
            'text-align': 'center',
            cursor: 'pointer',
            'font-size': '13px',
            color: 'white',
            background: idx === 0 ? '#27ae60' : 'rgba(0,0,0,0.55)',
            'font-weight': idx === 0 ? 'bold' : 'normal',
            'border-right': idx < cats.length - 1 ? '1px solid rgba(255,255,255,0.2)' : 'none',
            'user-select': 'none'
        });
        $tab.on('click', function() {
            var newIdx = parseInt($(this).attr('data-idx'));
            window._sel_curCat = newIdx;
            $('._sel_tab').css({ background: 'rgba(0,0,0,0.55)', 'font-weight': 'normal' });
            $(this).css({ background: '#27ae60', 'font-weight': 'bold' });
            window._sel_selectedTaskId = (catTaskLists[cats[newIdx].label] || [])[0] || null;
            renderTaskButtons(newIdx);
            renderDetail(window._sel_selectedTaskId);
        });
        $tabs.append($tab);
    });

    $root.append($title).append($detail).append($list).append($tabs);
    $fix.append($root);
    renderTaskButtons(0);
    renderDetail(window._sel_selectedTaskId);
})();
[endscript]

[mask_off time=500]
[s]

; ══════════════════════════════════════════════════════════
; ▼ ハンドラ
; ══════════════════════════════════════════════════════════

*back_home
[iscript]
$('.select_ui,#task_tabs,#lecture_area,#task_area,#task_title,#lecture_title,#new_episode_tag,.sel_back_btn').remove();
[endscript]
[clearfix]
[jump storage="home.ks" target="*start"]

*toSelectStory
[iscript]
$('.select_ui,#task_tabs,#lecture_area,#task_area,#task_title,#lecture_title,#new_episode_tag,.sel_back_btn').remove();
[endscript]
[clearfix]
[jump storage="select/story.ks" target="*start"]

*common_task_start
[iscript]
    $('.select_ui,#task_tabs,#lecture_area,#task_area,#task_title,#lecture_title,#new_episode_tag,.sel_back_btn').remove();
    var allTasks = f.all_tasks || {};
    var cats = allTasks._categories || [];
    var clearedTasks = f.cleared_tasks || {};
    var currentTask = allTasks[f.current_task_id] || {};
    var currentDifficulty = parseInt(currentTask.difficulty, 10) || 1;
    var highDifficultyUnlocked = !cats.length || cats.every(function(cat) {
        var count = Object.keys(allTasks).filter(function(key) {
            var task = allTasks[key] || {};
            var difficulty = parseInt(task.difficulty, 10) || 1;
            return /^task\d+$/.test(key) && task.category === cat.label && difficulty <= 2 && clearedTasks[key];
        }).length;
        return count >= 2;
    });
    f.current_task_locked = currentDifficulty >= 3 && !highDifficultyUnlocked;
    var taskData = allTasks[f.current_task_id];
    if (!f.current_task_locked && taskData) {
        f.my_code = Array.isArray(taskData.initial_code)
            ? taskData.initial_code.join('\n')
            : taskData.initial_code;
    } else if (!f.current_task_locked) {
        f.my_code = '// 課題データが見つかりません: ' + f.current_task_id;
    }
[endscript]
[if exp="f.current_task_locked == true"]
[dialog type="alert" text="この課題はまだ解放されていません。全カテゴリで難易度2以下の課題を2問ずつクリアすると解放されます。"]
[jump storage="select/task.ks" target="*start"]
[endif]
[clearfix]
[eval exp="f.is_sandbox=false"]
@layopt layer="message0" visible=true
[start_keyconfig]
[jump storage="editor.ks" target="*start"]
