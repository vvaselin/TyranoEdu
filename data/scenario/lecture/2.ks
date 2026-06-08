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

#
[chara_show name="teacher" time=500 left=400 top=40 width=400]
今日も今日とて、プログラミングの授業が始まる。[p]
[yureru_x chara=teacher left=400]
[wait time=300]
[chara_move name="teacher" left=1500 anim="true" time=500]
[chara_hide name="teacher" time=0]

といっても、先日と同様、先生は最低限の説明をするだけで、あとは自習のようだ。[p]

[mask time=300]
[wait time=500]
[mask_off time=300]

#&tf.you
よし、これでOKかな……？[p]

[filter layer=0 blur=5]
[chara_show_tilt name="mocha" left=700 top=-100 width=1000 face="surprise" deg=-15 time=500 origin="50% 50%"]
[free_filter layer=0 time=500 wait="true"]
[haneru chara=mocha top="-100" ]
#mocha
……あっ、その書き方だと……条件が逆になっちゃいます、ね……[p]

#&tf.you
あ、あれ……？[p]

[chara_untilt name="mocha" time=100]
[chara_mod name="mocha" face="magao" time=200]
[chara_move name="mocha" left=400 top=50 width=800 anim="true" time="500"]
(まだまだ、教わらないといけないことが沢山あるな……)[p]

#mocha
[chara_mod name="mocha" face="hokkori" time=200]
あの、昨日より……出来てます……っ。[l][r]
[chara_mod name="mocha" face="nico" time=200]
……頑張ってます……ね。[p]

#&tf.you
……[l][r]
(褒められた……)[p]

[chara_mod name="mocha" face="tere" time=200]
[haneru chara=mocha top="50" ]
あ……いや、すみません。偉そうなこと言っちゃって……[p]

#&tf.you
いや、全然！ありがとう……。[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
……ふふ、また分からないことがあったら、聞いてくださいね。[p]

#
彼女もプログラミングについて教えることは、嫌いではないようだ。[p]
以前よりも、落ち着いて話してくれるようになった気がする。[p]

#&tf.you
うん！またよろしくね、宮舞さん！[p]

[jump target="*back"]

*back
; 元の画面に戻る
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select/story.ks" target="*start"]
