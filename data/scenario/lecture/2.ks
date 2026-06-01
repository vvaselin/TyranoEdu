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
今日も今日とて、プログラミングの授業が始まる。[p]
といっても、先日と同様、先生は最低限の説明をするだけで、あとは各自で課題をやるスタイルのようだ。[p]

#&tf.you
よし、これでOKかな……？[p]

[chara_show name="mocha" width=700 left=300 top =50 time=500 face="surprise" ]
[haneru chara=mocha top="50" ]
#mocha
……あっ、その書き方だと……条件が逆になっちゃいます、ね……[p]

#&tf.you
あ、あれ……？[p]
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