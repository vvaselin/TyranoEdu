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
今日の課題は、同じ処理を何度も繰り返す「ループ」だった。[p]
黒板には for 文と while 文の例が並んでいる。[l][r]
けれど、見本を見ているだけでは簡単そうに見えるものほど、自分で書くと急に難しくなる。[p]

#&tf.you
えっと……ここで i を増やして……あれ、また止まらない……？[p]

#
画面には、同じ数字がずらりと並び続けている。[l][r]
何度直しても、似たようなところで間違えてしまう。[p]

#&tf.you
また同じミスだ……。[l][r]
さすがに、ちょっと情けないな……。[p]

[chara_show name="mocha" width=700 left=300 top=50 time=500 face="thinking" ]

#mocha
……あの。[p]

#&tf.you
宮舞さん？[p]

[chara_mod name="mocha" face="komari" time=200]
#mocha
その、ループって……最初は、同じところで何回も間違えます……。[l][r]
だから……変、じゃないです。[p]

#&tf.you
でも、さっきからずっと同じこと聞いてる気がするし……。[p]

[chara_mod name="mocha" face="normal" time=200]
#mocha
同じように見えても、たぶん……少しずつ違います。[l][r]
さっきは条件で、今は増やすところで止まってました。[p]

#&tf.you
……ちゃんと見てくれてたんだ。[p]

[chara_mod name="mocha" face="tere" time=200]
#mocha
あっ……す、すみません。勝手に……。[p]

#&tf.you
いや、助かるよ。[l][r]
自分だと、全部同じ失敗に見えてたから。[p]

[chara_mod name="mocha" face="hokkori" time=200]
#mocha
何度でも、直せばいいと……思います。[l][r]
ループも、条件が合うまで繰り返すものなので……。[p]

#&tf.you
その言い方、ちょっといいな。[p]

[chara_mod name="mocha" face="aseri" time=200]
#mocha
えっ……。[l][r]
い、今のは別に、うまいことを言ったつもりでは……。[p]

#&tf.you
うん。でも、少し楽になった。[l][r]
もう一回、落ち着いて見てみる。[p]

[mask time=300]
[wait time=500]
[mask_off time=300]

#&tf.you
よし……今度は、ちゃんと 1 から n まで出た！[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
……できましたね。[p]

#&tf.you
宮舞さんのおかげだよ。[l][r]
何度も付き合わせちゃって、ごめん。[p]

[chara_mod name="mocha" face="thinking" time=200]
#mocha
いえ……私も、何度も繰り返してますから。[p]

#&tf.you
プログラムを？[p]

[chara_mod name="mocha" face="komari" time=200]
#mocha
……会話を、です。[l][r]
何か言う前に、頭の中で何回も考えて……それでも、変になったりします。[p]

#&tf.you
そっか……。[l][r]
じゃあ、お互い繰り返しながら練習中なんだな。[p]

[chara_mod name="mocha" face="surprise" time=200]
#mocha
お互い……。[p]

[chara_mod name="mocha" face="tere" time=200]
#mocha
……はい。たぶん、そうです。[p]

#&tf.you
また分からなくなったら、聞いてもいい？[l][r]
……いや、また一緒に考えてほしい。[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
……はい。[l][r]
私でよければ、一緒に……考えます。[p]

#
同じ失敗を繰り返していたはずなのに、さっきよりも少し前に進めた気がした。[p]
ループの課題も、宮舞さんとの会話も、焦らずに繰り返せばいい。[p]

[jump target="*back"]

*back
; 元の画面に戻る
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select/story.ks" target="*start"]
