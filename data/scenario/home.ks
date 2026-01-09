*start
[hidemenubutton] 
[clearfix]
[bg storage="rouka.jpg" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

; ログアウトボタン
[button name="logout_btn" graphic="../others/plugin/theme_kopanda_22_HD_anim/image/button/title.png" enterimg="../others/plugin/theme_kopanda_22_HD_anim/image/button/title2.png" x=1180 y=20 height=50 role="sleep" fix="true"]

; トークモードへ移動
[glink color="ts22" text="トークモード" storage="conversation.ks" target="*start" x="850" y="570" width="300" size="30"]

; 課題選択画面へ移動
[glink color="mybtn_perspective mybtn_R" text="課題" storage="select.ks" target="*start" x="600" y="100" width="300" size="50"]

; 資料
[glink color="mybtn_perspective mybtn_R" text="資料" x="850" y="235" width="140" size="30"]

[s]