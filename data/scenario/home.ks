*start
[mask time=500]
[hidemenubutton]
[wait time=500]
[clearfix]
[bg storage="bunkabu.jpg" time="0"]
[filter layer="base" blur=2]

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
[glink color="mybtn_perspective mybtn_R" text="サンドボックス" target="*toSanbox" x="610" y="280" height="60" width="515" size="40"]

;キャラ情報
[glink color="mybtn_perspective mybtn_R" text="<span class='material-icons'>&#xe7fd;</span> キャラ" target="*developing"  x="630" y="390" height="80" width="230" size="35" cond="f.user_role == 'experimental' "]

; 資料
[glink color="mybtn_perspective mybtn_R" text="<span class='material-icons'>&#xe0e0;</span> 資料" target="*toDocment" x="935" y="395" height="105" width="200" size="35"]


[chara_show name="mocha" left=40  width=680 top =90 cond="f.user_role == 'experimental' "]
[clickable x=220 y=110 width=300 height=540 target="*mocha_reaction" cond="f.user_role == 'experimental'" ]

[image name="バー" storage="bar.png" layer="0" x=10 y=650 time="0" width="1000" height="50" ]

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

[button name="edit_name_btn" graphic="../fgimage/icons/edit.svg" x="400" y="15" height="40" fix="true" role="none"]
[button_ex name="edit_name_btn" enter_fade=100 tip="../fgimage/tiptools/ユーザー名変更.png" tip_pos="static" tip_x="300" tip_y="50"]

[ptext layer="fix" x="30" y="13" color="0xF4E511" text="Lv." size="25" align="center" bold="bold"  cond="f.user_role == 'experimental' "]
[ptext layer="fix" x="25" y="33" color="white" text="&TYRANO.kag.stat.f.love_level" size="50" align="center" bold="bold"  cond="f.user_role == 'experimental' "]

; アンケートボタン
[button name="question_before" graphic="../fgimage/icons/quiz_blue.svg" x=100 y=610 height="80" ]
[button_ex name="question_before" enter_fade=100 tip="../fgimage/tiptools/事前アンケート.png" tip_pos="top"]
[button name="test_before" graphic="../fgimage/icons/edit_square_blue.svg" x=250 y=610 height="80" ]
[button_ex name="test_before" enter_fade=100 tip="../fgimage/tiptools/事前テスト.png" tip_pos="top"]
[button name="test_after" graphic="../fgimage/icons/edit_square_red.svg" x=400 y=610 height="80" ]
[button_ex name="test_after" enter_fade=100 tip="../fgimage/tiptools/事後テスト.png" tip_pos="top"]
[button name="question_after" graphic="../fgimage/icons/quiz_red.svg" x=550 y=610 height="80" ]
[button_ex name="question_after" enter_fade=100 tip="../fgimage/tiptools/事後アンケート.png" tip_pos="top"]

[html]
<div id="dialog-confirm" title="名前の変更" style="display:none;">
    <p style="font-size:16px; margin-bottom:10px; color: white;">新しいユーザー名（2〜10文字）</p>
    <input type="text" id="new-user-name" maxlength="10">
</div>
[endhtml]

[iscript]
// 編集ボタンのクリックイベント
$(".edit_name_btn").off("click").on("click", function() {
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

[mask_off time=500]

[s]

*toSelect
[free_filter]
[freeimage layer="0" ]
; 課題選択画面へ移動
[clearfix]

[chara_hide name="mocha" time=0]
[jump storage="select.ks" target="*start"]

*toDocment
[free_filter]
[freeimage layer="0" ]
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="doc.ks" target="*start"]

*toSanbox
[free_filter]
[freeimage layer="0" ]
; エディタ画面(サンドボックスモード)へ移動
[clearfix]

[chara_hide name="mocha" time=0]

[eval exp="f.Isandbox = true"]

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
あっ、お…おはよう…！[wait time=1000]
[er]

@layopt layer="message0" visible=false
#
[jump target="*menu_loop"]