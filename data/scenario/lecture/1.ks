*start

[iscript]
tf.system.backlog=[];
[endscript]

[clearfix]
[start_keyconfig]
[add_theme_button]
[bg storage="room.jpg" time="0"]
@layopt layer="message0" visible=true
[turn_end]

#先生
じゃあ、各々で課題やっとくように。[l][r]
分かんなかったら、隣の人にでも聞いてくれ。[p]

#


[chara_show name="mocha" width=600 top =100]
#モカ
こんにちは！[l]

[jump target="*back_real"]

*back_real
; 元の画面に戻る
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select/story.ks" target="*start"]