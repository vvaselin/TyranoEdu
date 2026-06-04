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
配列、文字列、構造体。[l][r]
今日の範囲は、これまでよりも少しだけ情報量が多かった。[p]
同じ型の値を並べたり、文字を一つずつ扱ったり、名前と点数をひとまとめにしたりする。[p]

#&tf.you
覚えること、多いな……。[l][r]
配列の添字が 0 から始まるの、まだ油断すると間違える。[p]

[chara_show name="mocha" width=700 left=300 top=50 time=500 face="normal" ]

#mocha
最初の要素が 0 番目……慣れるまで、不思議だよね。[p]

#&tf.you
モカもそうだった？[p]

[chara_mod name="mocha" face="thinking" time=200]
#mocha
うん。[l][r]
でも、並んでいるものを一つずつ見ていく感じは……少し好き。[p]

#&tf.you
一つずつ？[p]

[chara_mod name="mocha" face="hokkori" time=200]
#mocha
うん。[r]
配列も文字列も、急に全部を分かろうとすると大変だから……端から順番に、だね。[p]

#&tf.you
人と仲良くなるのも、そんな感じかも。[p]

[chara_mod name="mocha" face="surprise" time=200]
#mocha
人と……？[p]

#&tf.you
最初から全部知るんじゃなくて、少しずつ覚えていくというか。[p]
モカのことも、最初は静かな人だと思ってたけど、今はそれだけじゃないって分かるし。[p]

[chara_mod name="mocha" face="tere" time=200]
#mocha
そ、それは……どういう情報として保存されてるの……？[p]

#&tf.you
うーん。[l][r]
「プログラミングに詳しい」「説明が丁寧」「褒めると照れる」。[p]

[chara_mod name="mocha" face="aseri" time=200]
#mocha
最後のは、保存しなくていい……。[p]

#&tf.you
じゃあ、構造体に入れるなら非公開メンバで。[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
C++の構造体に、非公開メンバは……class の方が近いかも。[p]

#&tf.you
そこは真面目に返すんだ。[p]

[chara_mod name="mocha" face="hokkori" time=200]
#mocha
……癖。[p]

[mask time=300]
[wait time=500]
[mask_off time=300]

#
課題は、思ったよりも順調に進んだ。[p]
配列の合計、文字列の逆順、構造体での成績管理。[l][r]
一つずつ確認していくと、ばらばらに見えた知識が少しずつ並んでいく。[p]

#&tf.you
よし、今日の分も通った。[l][r]
……モカ、ありがとう。[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
ううん。[l][r]
今日は、ほとんど自分で進めてたと思う。[p]

#&tf.you
でも、隣にいてくれると安心する。[p]

[chara_mod name="mocha" face="tere" time=200]
#mocha
……そう、なんだ。[p]

#&tf.you
あ、課題の話だけじゃなくて。[l][r]
少し雑談してもいい？[p]

[chara_mod name="mocha" face="surprise" time=200]
#mocha
雑談……？[p]

#&tf.you
うん。[l][r]
例えば、モカって休みの日は何してるの？[p]

[chara_mod name="mocha" face="komari" time=200]
#mocha
えっと……猫と遊んだり、次の日の課題を見たり……。[l][r]
あと、紅茶を飲んだり、かな。[p]

#&tf.you
紅茶好きなんだ。[p]

[chara_mod name="mocha" face="hokkori" time=200]
#mocha
うん。[l][r]
近くに美味しい喫茶店があるんだ。[p]

#&tf.you
じゃあ今度、一緒に寄ってみる？[l][r]
おすすめのメニューも、よかったら教えて。[p]

[chara_mod name="mocha" face="surprise" time=200]
[haneru chara=mocha top=50]
#mocha
……一緒に？[p]

#&tf.you
嫌なら無理にとは言わないけど。[p]

[chara_mod name="mocha" face="tere" time=200]
#mocha
嫌じゃないよ。[l][r]
ただ……そういうの、あまり慣れてなくて。[p]

#&tf.you
じゃあ、課題と同じで少しずつ。[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
……うん。[l][r]
少しずつ、なら。[p]

#
分からないところを聞くためだけに、モカへ話しかけていたはずだった。[p]
けれど今は、課題が終わっても隣で話していたいと思う。[p]
並んで覚えていくものは、プログラムの書き方だけではないのかもしれない。[p]

[jump target="*back"]

*back
; 元の画面に戻る
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select/story.ks" target="*start"]
