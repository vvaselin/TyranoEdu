*start
[mask time=1000]
[wait time=1000]
[hidemenubutton] 
[clearfix]
[bg storage="rouka.jpg" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

; トークモードへ移動
[glink color="ts22" text="トークモード" target="*developing" x="850" y="570" width="300" size="30" cond="f.user_role == 'experimental' "]

; 課題選択画面へ移動
[glink color="mybtn_perspective mybtn_R" text="<span class='material-icons'>&#xf88c;</span> 課題" target="*toSelect" x="600" y="100" height="130" width="510" size="60"]

;キャラ情報
[glink color="mybtn_perspective mybtn_R" text="<span class='material-icons'>&#xe7fd;</span> キャラ" target="*developing"  x="630" y="320" height="80" width="230" size="35" cond="f.user_role == 'experimental' "]

; 資料
[glink color="mybtn_perspective mybtn_R" text="<span class='material-icons'>&#xe0e0;</span> 資料" target="*toDocment" x="935" y="312" height="105" width="200" size="35"]


[chara_show name="mocha" left=80  width=680 top =90 cond="f.user_role == 'experimental' "]

; ログアウトボタン
[button name="logout_btn" graphic="../others/plugin/theme_kopanda_22_HD_anim/image/button/title.png" enterimg="../others/plugin/theme_kopanda_22_HD_anim/image/button/title2.png" x=1180 y=20 height=50 role="sleep" fix="true"]

[iscript]
$(".logout_btn").off("click").on("click", async function() {
    if (!confirm("ログアウトしますか？")) return;
    if (window.sb) await window.sb.auth.signOut();
    TYRANO.kag.stat.f.user_id = null;
    TYRANO.kag.stat.f.ai_memory = null;
    tyrano.plugin.kag.ftag.startTag("chara_hide", { name: "mocha", time: 0 });
    tyrano.plugin.kag.ftag.startTag("jump", { storage: "auth.ks" });
});
[endscript]

[mask_off time=500]
[s]

*toSelect
; 課題選択画面へ移動
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select.ks" target="*start"]

*toDocment
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="doc.ks" target="*start"]

*developing
[iscript]
alert("ただいま開発中です。");
[endscript]
[jump target="*start" ]
