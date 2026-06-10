; select/story.ks - エピソード選択画面（固定リスト＋詳細パネル）
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
[glink name="sel_back_btn" color="mybtn_09" text="<span class='material-icons'>&#xf88c;</span> 課題" target="*toSelectTask" width="200" height="50" size="20" x="300" y="15"]

; ══════════════════════════════════════════════════════════
; ▼ 固定UI
; ══════════════════════════════════════════════════════════
[iscript]
(function() {
    var $fix = TYRANO.kag.layer.getLayer("fix");
    var tasks = f.all_tasks || {};
    var cats = tasks._categories || [];

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

    var clearedPerCat = cats.map(function(cat) {
        return (catTaskLists[cat.label] || []).filter(function(key) {
            return f.cleared_tasks && f.cleared_tasks[key];
        }).length;
    });
    var controlLectureUnlocked = {};
    for (var unlockIdx = 1; unlockIdx <= 5; unlockIdx++) {
        controlLectureUnlocked[unlockIdx] = unlockIdx === 1 || (cats.length >= unlockIdx && cats.slice(0, unlockIdx).every(function(cat, catIdx) {
            return clearedPerCat[catIdx] >= 2;
        }));
    }
    var experimentalLectureUnlocked = {};
    if (f.user_role !== 'control') {
        var love = parseInt(f.love_level) || 0;
        var gaugeState = window.AppProgressConfig.getLoveGaugeState(love);
        f.level = gaugeState.level;
        for (var expUnlockIdx = 1; expUnlockIdx <= 5; expUnlockIdx++) {
            experimentalLectureUnlocked[expUnlockIdx] = expUnlockIdx === 1 || (
                f.level >= expUnlockIdx &&
                cats.length >= expUnlockIdx &&
                cats.slice(0, expUnlockIdx).every(function(cat, catIdx) {
                    return clearedPerCat[catIdx] >= 1;
                })
            );
        }
    }

    var epSummaries = {
        1: 'C++の授業で、隣の席の宮舞モカに初めて課題の相談をする。',
        2: '条件分岐の課題を通して、モカが少し落ち着いて話してくれるようになる。',
        3: 'ループ課題で失敗を繰り返しながら、一緒に考える関係へ近づく。',
        4: '関数の課題を通し、教わるだけではない関係になる。',
        5: '配列や構造体の課題後、モカは課題以外の雑談もしてくれるように――。'
    };

    window._sd_lec = {};
    for (var i = 1; i <= 5; i++) {
        var locked;
        if (f.user_role === 'control') {
            locked = !controlLectureUnlocked[i];
        } else {
            locked = !experimentalLectureUnlocked[i];
        }
        var cat = cats[i - 1];
        window._sd_lec[i] = {
            idx: i,
            label: 'ep.' + i,
            locked: locked,
            category: cat ? cat.label : '未設定',
            short: cat ? cat.short : 'ep',
            summary: epSummaries[i],
            isUnread: !locked && (!f.watched_lectures || !f.watched_lectures[i])
        };
    }
    window._sel_selectedLecture = 1;

    var $root = $('<div>').addClass('select_ui').attr('id', 'story_select_ui').css({
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

    var $title = $('<div>').addClass('select_ui').attr('id', 'lecture_title').html('📖 エピソード選択').css({
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

    var panelBase = {
        position: 'absolute',
        background: 'rgba(8, 42, 58, 0.78)',
        border: '2px solid rgba(255,255,255,0.78)',
        'box-shadow': '0 8px 18px rgba(0,0,0,0.28)',
        'border-radius': '8px',
        'pointer-events': 'auto'
    };

    var $detail = $('<div>').addClass('story_detail_panel').css($.extend({}, panelBase, {
        left: '700px',
        top: '160px',
        width: '500px',
        height: '530px',
        padding: '20px',
        'box-sizing': 'border-box'
    }));

    var $list = $('<div>').addClass('story_list_panel').css($.extend({}, panelBase, {
        left: '80px',
        top: '160px',
        width: '520px',
        height: '530px',
        padding: '36px 28px',
        'box-sizing': 'border-box'
    }));

    function unlockText(ep) {
        if (ep.idx === 1) return '最初から解放';
        if (f.user_role === 'control') {
            var categoryClear = Math.min(clearedPerCat[ep.idx - 1] || 0, 2);
            return '前のエピソード解放 + 該当カテゴリ2問クリア: ' + categoryClear + '/2';
        }
        var expCategoryClear = Math.min(clearedPerCat[ep.idx - 1] || 0, 1);
        return '親密度Lv.' + ep.idx + ' + 該当カテゴリ1問クリア: ' + expCategoryClear + '/1（現在 Lv.' + (f.level || 1) + '）';
    }

    function renderDetail(idx) {
        var ep = window._sd_lec[idx];
        if (!ep) return;
        var status = ep.locked ? '未解放' : (ep.isUnread ? 'NEW' : '既読');
        var statusColor = ep.locked ? '#777' : (ep.isUnread ? '#ff4757' : '#1f9d66');
        var summaryHtml = ep.locked
            ? '<div style="font-size:16px;line-height:1.65;margin-bottom:22px;color:rgba(255,255,255,0.72);">解放後に表示されます。</div>'
            : '<div style="font-size:16px;line-height:1.65;margin-bottom:22px;">' + escapeHtml(ep.summary) + '</div>';
        $detail.html(
            '<div style="font-size:14px;color:#a7f3d0;margin-bottom:8px;">' + escapeHtml(ep.category) + '</div>' +
            '<div style="font-size:32px;font-weight:bold;margin-bottom:10px;">' + escapeHtml(ep.label) + '</div>' +
            '<div style="display:inline-block;padding:4px 12px;border-radius:999px;background:' + statusColor + ';font-size:15px;font-weight:bold;margin-bottom:18px;">' + status + '</div>' +
            '<div style="font-size:18px;font-weight:bold;margin-bottom:8px;">概要</div>' +
            summaryHtml +
            '<div style="font-size:18px;font-weight:bold;margin-bottom:8px;">解放条件</div>' +
            '<div style="font-size:16px;line-height:1.55;margin-bottom:22px;">' + escapeHtml(unlockText(ep)) + '</div>' +
            '<button id="story_start_btn" ' + (ep.locked ? 'disabled' : '') + ' style="position:absolute;left:20px;bottom:20px;width:460px;height:52px;border:2px solid white;border-radius:8px;background:' + (ep.locked ? '#777' : '#0f8b8d') + ';color:white;font-size:20px;font-weight:bold;cursor:' + (ep.locked ? 'default' : 'pointer') + ';">' + (ep.locked ? '未解放' : 'このエピソードを見る') + '</button>'
        );
        $('#story_start_btn').on('click', function() {
            if (ep.locked) return;
            tf.target_lecture_num = idx;
            cleanupSelectUi();
            TYRANO.kag.ftag.startTag('jump', { target: '*lecture_jump' });
        });
    }

    function renderButtons() {
        $list.empty();
        for (var i = 1; i <= 5; i++) {
            var ep = window._sd_lec[i];
            var selected = i === window._sel_selectedLecture;
            var $btn = $('<button>').addClass('story_btn_row').attr('data-idx', i).css({
                position: 'absolute',
                left: '42px',
                top: (42 + (i - 1) * 95) + 'px',
                width: '390px',
                height: '56px',
                border: selected ? '3px solid #ffd166' : '3px solid rgba(255,255,255,0.82)',
                'border-radius': '8px',
                background: ep.locked ? '#888' : (selected ? '#55c9c9' : '#4bbbbb'),
                color: 'white',
                'font-size': '18px',
                cursor: 'pointer',
                'box-shadow': '0 3px 0 rgba(0,0,0,0.35)'
            }).text(ep.label);
            var $tag = $('<span>').addClass('story_btn_row').css({
                position: 'absolute',
                left: '440px',
                top: (40 + (i - 1) * 95) + 'px',
                color: ep.isUnread ? '#ff3333' : 'rgba(255,255,255,0.55)',
                'font-size': '24px',
                'font-weight': 'bold',
                '-webkit-text-stroke': ep.isUnread ? '0.6px white' : '0',
                display: ep.isUnread ? 'block' : 'none'
            }).text('NEW');
            $btn.on('click', function() {
                var idx = parseInt($(this).attr('data-idx'));
                window._sel_selectedLecture = idx;
                renderButtons();
                renderDetail(idx);
            });
            $list.append($btn).append($tag);
        }
    }

    $root.append($title).append($detail).append($list);
    $fix.append($root);
    renderButtons();
    renderDetail(1);
})();
[endscript]

[mask_off time=500]
[s]

; ══════════════════════════════════════════════════════════
; ▼ ハンドラ
; ══════════════════════════════════════════════════════════

*lecture_jump
[iscript]
if (!f.watched_lectures) f.watched_lectures = {};
var lectureInfo = window._sd_lec && window._sd_lec[tf.target_lecture_num] ? window._sd_lec[tf.target_lecture_num] : {};
var wasUnreadLecture = !lectureInfo.locked && !f.watched_lectures[tf.target_lecture_num];
if (window.logExperimentEvent) {
    window.logExperimentEvent("lecture_view", {
        lecture_num: tf.target_lecture_num,
        lecture_label: lectureInfo.label || ("ep." + tf.target_lecture_num),
        category: lectureInfo.category || "",
        was_unread: wasUnreadLecture,
        user_role: f.user_role || "",
        love_level: f.love_level || 0,
        level: f.level || 1
    }, { task_id: null });
}
f.watched_lectures[tf.target_lecture_num] = true;
var hasUnread = false;
for (var j = 1; j <= 5; j++) {
    if (!window._sd_lec[j].locked && !f.watched_lectures[j]) {
        hasUnread = true;
        break;
    }
}
f.has_unread_lecture = hasUnread;
$('.select_ui,#task_tabs,#lecture_area,#task_area,#task_title,#lecture_title,#new_episode_tag,.sel_back_btn').remove();
[endscript]
[clearfix]
@layopt layer="message0" visible=true
[start_keyconfig]
[eval exp="tf.lecture_path='lecture/'+tf.target_lecture_num+'.ks'"]
[turn_start]
[jump storage="&tf.lecture_path" target="*start"]

*back_home
[clearfix]
[iscript]
$('.select_ui,#task_tabs,#lecture_area,#task_area,#task_title,#lecture_title,#new_episode_tag,.sel_back_btn').remove();
[endscript]
[jump storage="home.ks" target="*start"]

*toSelectTask
[clearfix]
[iscript]
$('.select_ui,#task_tabs,#lecture_area,#task_area,#task_title,#lecture_title,#new_episode_tag,.sel_back_btn').remove();
[endscript]
[jump storage="select/task.ks" target="*start"]
