*start
[mask time=500]
[hidemenubutton]
[wait time=100]
[clearfix]
[bg storage="bunkabu.jpg" time="0"]
[free_filter layer="base"]

[if exp="f.user_role == 'experimental' "]
    [bg storage="bunkabu.jpg" time="100" wait="true"]
    [filter layer="base" blur=2]
[else]
    [bg storage="standard.png" time="100" wait="true"]
[endif]

[layopt layer="0" visible="true"]
@layopt layer="message0" visible=false
[stop_keyconfig]

*menu_loop
[chara_mod name="mocha" face="normal" wait=false]
; トークモードへ移動
[glink color="ts22" text="トークモード" target="*developing" x="850" y="570" width="300" size="30" cond="f.user_role == 'experimental' "]
; 課題選択画面へ移動
[glink color="mybtn_perspective mybtn_R" text="<span class='material-icons'>&#xf88c;</span> 課題" target="*toSelect" x="600" y="100" height="100" width="510" size="60"]
; サンドボックスモード
[glink color="mybtn_perspective mybtn_R" text="サンドボックス" target="*toSanbox" x="610" y="280" height="60" width="520" size="40"]
;キャラ情報
[glink color="mybtn_perspective mybtn_R" text="<span class='material-icons'>&#xe7fd;</span> キャラ" target="*developing"  x="630" y="390" height="80" width="230" size="35" cond="f.user_role == 'experimental' "]
; 資料
[glink color="mybtn_perspective mybtn_R" text="<span class='material-icons'>&#xe0e0;</span> 資料" target="*toDocment" x="935" y="395" height="105" width="200" size="35"]
[wait time=100]

; キャラクター表示
[chara_show name="mocha" time="50"  left=40  width=680 top =90 cond="f.user_role == 'experimental' " time=100 wait="true" ]
[clickable x=220 y=110 width=300 height=540 target="*mocha_reaction" cond="f.user_role == 'experimental'" ]
[wait time=100]

; ログアウトボタン
[button name="logout_btn" graphic="../others/plugin/theme_kopanda_22_HD_anim/image/button/title.png" enterimg="../others/plugin/theme_kopanda_22_HD_anim/image/button/title2.png" x=1180 y=20 height=50 role="sleep" fix="true"]

[iscript]
$(".logout_btn").off("click").on("click", async function() {
    if (!confirm("ログアウトしますか？")) return;
    if (window.sb) await window.sb.auth.signOut();
    TYRANO.kag.stat.f.user_id = null;
    TYRANO.kag.stat.f.ai_memory = null;
    tyrano.plugin.kag.ftag.startTag("chara_hide", { name: "mocha", time: 0 });
    tyrano.plugin.kag.ftag.startTag("jump", { storage: "auth_google.ks" });
    tyrano.plugin.kag.ftag.startTag("free_filter");
    tyrano.plugin.kag.ftag.startTag("freeimage", { layer: "0" });
});
[endscript]

[image name="ネームプレート" storage="NamePlate.png" layer="0" x=-10 y=10 time="0"  height="100" width="450" ]

; ユーザー情報
[ptext name="user_name_display" layer="fix" x="100" y="15" color="white" text="&TYRANO.kag.stat.f.user_name" size="30" align="left"  bold="bold" ]

; ユーザー名編集ボタン
[glink name="btn-svg-icon btn-size-s btn-icon-edit tooltip-bottom" text=""  x="400" y="15" ]

[ptext layer="fix" x="30" y="13" color="0xF4E511" text="Lv." size="25" align="center" bold="bold"  cond="f.user_role == 'experimental' "]
[ptext layer="fix" x="25" y="33" color="white" text="&TYRANO.kag.stat.f.love_level" size="50" align="center" bold="bold"  cond="f.user_role == 'experimental' "]

[wait time=100]

; アンケートボタン
[image name="バー" storage="bar.png" layer="0" x=10 y=650 time="0" width="1000" height="50" ]
[glink name="btn-svg-icon btn-quiz-blue" text="" target="*pre_test" x=100 y=600 ]
[glink name="btn-svg-icon btn-edit-blue" text="" target="*pre_survey" x=250 y=600 ]
[glink name="btn-svg-icon btn-edit-red" text="" target="*post_survey" x=400 y=600 ]
[glink name="btn-svg-icon btn-quiz-red" text="" target="*post_test" x=550 y=600 ]

[iscript]
$(".btn-icon-edit").attr("data-tooltip", "ユーザー名変更");
$(".btn-quiz-blue").attr("data-tooltip", "事前テスト");
$(".btn-edit-blue").attr("data-tooltip", "事前アンケート");
$(".btn-edit-red").attr("data-tooltip", "事後アンケート");
$(".btn-quiz-red").attr("data-tooltip", "事後テスト");
[endscript]

[html]
<div id="dialog-confirm" title="名前の変更" style="display:none;">
    <p style="font-size:16px; margin-bottom:10px; color: white;">新しいユーザー名（2〜10文字）</p>
    <input type="text" id="new-user-name" maxlength="10">
</div>
[endhtml]

[iscript]
// 編集ボタンのクリックイベント
$(".btn-size-s").off("click").on("click", function() {
    // 現在の名前をインプットにセット
    $("#new-user-name").val(TYRANO.kag.stat.f.user_name);
    
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
[endscript]

[wait time=100]

[mask_off time=500]

[s]

*toSelect
[free_filter]
[freeimage layer="0" ]
; 課題選択画面へ移動
[clearfix]

[chara_hide name="mocha" time=50]
[jump storage="select.ks" target="*start"]

*toDocment
[free_filter]
[freeimage layer="0" ]
[clearfix]
[chara_hide name="mocha" time=50]
[jump storage="doc.ks" target="*start"]

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

[if exp="f.user_role == 'experimental' "]
[jump storage="editor.ks" target="*start"]
[else]
[jump storage="editor_control.ks" target="*start"]
[endif]

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
[web url="https://forms.cloud.microsoft/r/SF5yeuaADx" ]
[jump target="*menu_loop"]

*post_test
; 事後テスト
[web url="https://forms.cloud.microsoft/r/SF5yeuaADx" ]
[jump target="*menu_loop"]

*post_survey
; 事後アンケート
[web url="https://forms.cloud.microsoft/r/SF5yeuaADx" ]
[jump target="*menu_loop"]