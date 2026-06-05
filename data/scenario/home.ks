*start
[mask time=500]
[hidemenubutton]
[wait time=100]
[clearfix]
[bg storage="bunkabu.jpg" time="0"]
[free_filter layer="base"]


[bg storage="bunkabu.jpg" time="100" wait="true"]
[filter layer="base" blur=2]

[layopt layer="0" visible="true"]
@layopt layer="message0" visible=false
[stop_keyconfig]

*menu_loop
[chara_mod name="mocha" face="normal" wait=false]
; トークモードへ移動
;[glink color="ts22" text="トークモード" target="*developing" x="850" y="570" width="300" size="30"]

;=== ボタン配置（nameで目印をつける） ===
[glink color="mybtn_perspective" name="grp_R" text="<span class='material-icons'>&#xe0b7;</span> エピソード" target="*toSelectStory" x="635" y="130" height="100" width="260" size="35"]
[glink color="mybtn_perspective" name="grp_R" text="<span class='material-icons'>&#xf88c;</span> 課題" target="*toSelectTask"  x="935" y="130" height="100" width="260" size="35"]
[glink color="mybtn_perspective" name="grp_R" text="サンドボックスモード" target="*toSanbox" x="640" y="280" height="60" width="550" size="35"]
[glink color="mybtn_perspective" name="grp_R" text="<span class='material-icons'>&#xe7fd;</span> キャラ" target="*developing"  x="635" y="390" height="100" width="260" size="35"]
[glink color="mybtn_perspective" name="grp_R" text="<span class='material-icons'>&#xe0e0;</span> 資料" target="*toDocment" x="935" y="390" height="100" width="260" size="35"]

;=== ラッパーを作り、glinkをまとめて移動 ===
[iscript]
    // 1. 外枠（perspective担当）
    var $outer = $('<div class="perspective-outer">').css({
        position: 'absolute',
        left: 0,
        top: 0,
        width: '100%',
        height: '100%',
        pointerEvents: 'none'       // ラッパー自体はクリック透過
    });
    // 2. 内枠（rotateY担当）
    var $inner = $('<div class="perspective-inner-R">').css({
        pointerEvents: 'none'
    });
    $outer.append($inner);
    // 3. フリーレイヤに追加
    $('.layer_free').append($outer);
    $('.grp_R').css('pointer-events', 'auto').appendTo($inner);

    // f.has_unread_lecture 計算
    (function() {
        var cats = f.all_tasks && f.all_tasks._categories;
        if (!cats) { f.has_unread_lecture = false; return; }

        // 解放済みエピソード数を算出
        var unlockedCount;
        if (f.user_role === 'control') {
            var clearedPerCat = cats.map(function(c) {
                return Object.keys(f.all_tasks).filter(function(k) {
                    return /^task\d+$/.test(k) && f.all_tasks[k].category === c.label;
                }).filter(function(k) {
                    return f.cleared_tasks && f.cleared_tasks[k];
                }).length;
            });
            unlockedCount = Math.min(clearedPerCat.filter(function(n) { return n >= 3; }).length + 1, 5);
        } else {
            // f.love_level から直接レベルを算出（f.level に依存しない）
            var love = parseInt(f.love_level) || 0;
            var th = [0, 10, 25, 40, 70, 100];
            unlockedCount = 1;
            for (var i = 1; i < th.length; i++) {
                if (love >= th[i]) unlockedCount = i + 1;
            }
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

; エピソードボタン右上に NEW 表示
[ptext name="new_episode_tag" layer="fix" text="NEW" color="0xFF3333" edge="2px white" bold="true" size="28" x="840" y="130" cond="f.has_unread_lecture == true"]

; キャラクター表示
[chara_show name="mocha" time="50"  left=40  width=680 top =90 time=100 wait="true" ]
[clickable x=220 y=110 width=300 height=540 target="*mocha_reaction"]
[wait time=100]

;[chara_show name="adviser" time="50"  left=-50  width=800 top =-50 cond="f.user_role == 'control' " time=100 wait="true" ]

; ログアウトボタン
[button name="logout_btn" graphic="../others/plugin/theme_kopanda_22_HD_anim/image/button/title.png" enterimg="../others/plugin/theme_kopanda_22_HD_anim/image/button/title2.png" x=1180 y=20 height=50 role="sleep" fix="true"]

[iscript]
$(".logout_btn").off("click").on("click", async function() {
    if (!confirm("ログアウトしますか？")) return;
    if (window.sb) await window.sb.auth.signOut();
    TYRANO.kag.stat.f.user_id = null;
    TYRANO.kag.stat.f.ai_memory = null;
    tyrano.plugin.kag.ftag.startTag("chara_hide", { name: "mocha", time: 0 });
    tyrano.plugin.kag.ftag.startTag("jump", { storage: "auth_anonymous.ks" });
    tyrano.plugin.kag.ftag.startTag("free_filter");
    tyrano.plugin.kag.ftag.startTag("freeimage", { layer: "0" });
});
[endscript]

[image name="ネームプレート" storage="NamePlate.png" layer="0" x=-10 y=10 time="0"  height="100" width="450" ]

; ユーザー情報
[ptext name="user_name_display" layer="fix" x="100" y="15" color="white" text="&TYRANO.kag.stat.f.user_name" size="30" align="left"  bold="bold" ]

; ユーザー名編集ボタン
[glink name="btn-svg-icon btn-size-s btn-icon-edit tooltip-bottom" text=""  x="400" y="15" ]

[wait time=100]

; アンケートボタン
[image name="バー" storage="bar.png" layer="0" x=10 y=650 time="0" width="1000" height="50" ]
[glink name="btn-svg-icon btn-quiz-blue" text="" target="*pre_survey" x=100 y=600 ]
[glink name="btn-svg-icon btn-edit-blue" text="" target="*pre_test" x=250 y=600 ]
[glink name="btn-svg-icon btn-edit-red" text="" target="*post_test" x=400 y=600 ]
[glink name="btn-svg-icon btn-quiz-red" text="" target="*post_survey" x=550 y=600 ]
[glink name="btn-svg-icon btn-size-m btn-tutorial" text="" target="*toTutorial" x=900 y=630 ]



[iscript]
    $(".btn-icon-edit").attr("data-tooltip", "ユーザー名変更");
    $(".btn-quiz-blue").attr("data-tooltip", "事前アンケート");
    $(".btn-edit-blue").attr("data-tooltip", "事前テスト");
    $(".btn-edit-red").attr("data-tooltip", "事後テスト");
    $(".btn-quiz-red").attr("data-tooltip", "事後アンケート");
    $(".btn-tutorial").attr("data-tooltip", "チュートリアル");
[endscript]

[html]
    <div id="dialog-confirm" title="名前の変更" style="display:none;">
        <p style="font-size:16px; margin-bottom:10px; color: white;">新しいユーザー名（2〜10文字）</p>
        <input type="text" id="new-user-name" maxlength="10">
    </div>
[endhtml]
[if exp="f.user_role == 'experimental' "]
    [html]
        <div class="gauge-box">
            <div class="gauge-track">
                <div class="gauge-fill"></div>
            </div>
        </div>
    [endhtml]
[endif]

[iscript]
    // 編集ボタンのクリックイベント
    $(".btn-size-s").off("click").on("click", function() {
        // 現在の名前をインプットにセット
        $("#new-user-name").val(f.user_name);
        
        $("#dialog-confirm").dialog({
            resizable: false,
            height: "auto",
            width: 400,
            modal: true,
            draggable: false,
            dialogClass: "name-edit-dialog",
            buttons: {
                "保存": async function() {
                    const newName = $("#new-user-name").val().trim();
                    
                    // バリデーション
                    if (newName.length < 2) {
                        alert("ユーザー名は2文字以上で入力してください");
                        return;
                    }
                    const validPattern = /^[a-zA-Z0-9あ-んア-ン一-龠々]+$/;
                    if (!validPattern.test(newName)) {
                        alert("記号やスペースは使用できません");
                        return;
                    }

                    // Supabase更新
                    if (window.sb) {
                        const { error } = await window.sb
                            .from('profiles')
                            .update({ name: newName })
                            .eq('id', TYRANO.kag.stat.f.user_id);

                        if (error) {
                            alert("エラー: " + error.message);
                            return;
                        }
                    }

                    // ティラノ変数の更新と表示のリフレッシュ
                    TYRANO.kag.stat.f.user_name = newName;
                    $(".user_name_display").text(newName);
                    
                    $(this).dialog("close");
                },
                "キャンセル": function() {
                    $(this).dialog("close");
                }
            }
        });
    });
    // 親密度ゲージ
    var totalLove = parseInt(f.love_level) || 0;
    var thresholds = [1, 16, 31, 66, 101, 101]; 
    var currentLv = 1;
    var minLove = 0;
    var maxLove = 0;

    for (var i = 0; i < thresholds.length - 1; i++) {
        if (totalLove >= thresholds[i] - 1) {
            currentLv = i + 1;
            minLove = thresholds[i] - 1;    
            maxLove = thresholds[i + 1] - 1;
        }
    }

    var percent = 0;
    var displayStr = "";

    if (currentLv <= 5) {
        var range = maxLove - minLove;
        var currentProgress = totalLove - minLove;

        if (range > 0) {
            percent = (currentProgress / range) * 100;
        } else {
            percent = 100;
        }

        // 通常の表示文字列
        displayStr = currentProgress + " / " + range;

        if (totalLove >= 100) {
            displayStr = " (MAX)";
            percent = 100;
            $(".gauge-fill").css(
                'background',
                'linear-gradient(90deg, #fff197 0%, #fff12c 100%)'
            );
        }
    }
    f.level = currentLv;
    $(".gauge-fill").css("width", percent + "%");
    tf.displayStr = displayStr;

[endscript]
; レベル表示
[ptext layer="fix" x="30" y="13" color="0xF4E511" text="Lv." size="25" align="center" bold="bold"  cond="f.user_role == 'experimental' "]
[ptext layer="fix" x="25" y="33" color="white" text="&f.level" size="50" align="center" bold="bold"  cond="f.user_role == 'experimental' "]
[ptext layer="fix" x="100" y="70" color="white" text="&tf.displayStr" size="20" align="left" bold="bold"  cond="f.user_role == 'experimental' "]

[wait time=100]

[mask_off time=500]

[s]

*toSelectTask
[free_filter]
[freeimage layer="0" ]
; 課題選択画面へ移動
[clearfix]

[chara_hide name="mocha" time=50]
[jump storage="select/task.ks" target="*start"]

*toSelectStory
[free_filter]
[freeimage layer="0" ]
[clearfix]

[chara_hide name="mocha" time=50]
[jump storage="select/story.ks" target="*start"]

*toDocment
[free_filter]
[freeimage layer="0" ]
[clearfix]
[chara_hide name="mocha" time=50]
[jump storage="doc.ks" target="*start"]

*toTutorial
[free_filter]
[freeimage layer="0" ]
[clearfix]
[chara_hide name="mocha" time=50]
[eval exp="f.tutorial_from_home = true"]
[jump storage="tutorial/intro.ks" target="*start"]

*toSanbox
[free_filter]
[freeimage layer="0" ]
; エディタ画面(サンドボックスモード)へ移動
[clearfix]

[chara_hide name="mocha" time=50]

[eval exp="f.is_sandbox = true"]
[eval exp="f.current_task_id = 'sandbox'"]

[iscript]
var taskData = TYRANO.kag.stat.f.all_tasks["sandbox"];
if (taskData && taskData.initial_code) {
    if (Array.isArray(taskData.initial_code)) {
        TYRANO.kag.stat.f.my_code = taskData.initial_code.join('\n');
    } else {
        TYRANO.kag.stat.f.my_code = taskData.initial_code;
    }
}
[endscript]

[jump storage="editor.ks" target="*start"]

*developing
[iscript]
alert("ただいま開発中です。");
[endscript]
[jump target="*menu_loop" ]

*mocha_reaction
@layopt layer="message0" visible=true
[chara_mod name="mocha" face="surprise" wait=false]
#モカ
あっ、お…おはよう…！[wait time=1500]
[er]

@layopt layer="message0" visible=false
#
[jump target="*menu_loop"]

*pre_survey
; 事前アンケート
[web url="https://forms.cloud.microsoft/r/SF5yeuaADx" ]
[jump target="*menu_loop"]

*pre_test
; 事前テスト
[web url="https://forms.cloud.microsoft/r/8R55L3ec0M" ]
[jump target="*menu_loop"]

*post_test
; 事後テスト
[web url="https://forms.cloud.microsoft/r/1sXxwRviJM" ]
[jump target="*menu_loop"]

*post_survey
; 事後アンケート
[web url="https://forms.cloud.microsoft/r/EMPTPmkMMp" ]
[jump target="*menu_loop"]
