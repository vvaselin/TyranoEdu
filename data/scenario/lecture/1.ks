*start
[clearfix]
[start_keyconfig]
[add_theme_button]
[bg storage="room.jpg" time="0"]
@layopt layer="message0" visible=true

[chara_new name name="mocha" storage="chara/mocha/normal.png" jname="モカ"]
[chara_show name="mocha" width=600 top =100]
#モカ
こんにちは！[l]

[jump target="*back_real"]

*back_real
; 元の画面に戻る
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select.ks" target="*start"]