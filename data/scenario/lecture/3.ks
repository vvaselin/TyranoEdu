*start

[iscript]
tf.system.backlog=[];
tf.you = f.user_name;
[endscript]

[clearfix]
[start_keyconfig]
[add_theme_button]
[bg storage="room.jpg" time="0"]
@layopt layer="message0" visible=true
[turn_end]


[jump target="*back"]

*back
; 元の画面に戻る
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select/story.ks" target="*start"]