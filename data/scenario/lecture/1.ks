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

#&tf.you
(プログラミングの授業。[l][r]
C++のプログラミングなんて普段やらないから不安だな。)[p]

#先生
じゃあ、あとは各々で課題やっとくように。[l][r]
分かんなかったら、隣の人にでも聞いてくれ。[p]

#&tf.you
(なんて無責任な先生なんだ……[l][r]
まあ、やるしかないか……)[p]

[mask time=300]
[wait time=500]
[mask_off time=300]

#&tf.you
わかんない！
[quake count=5 time=300 hmax=20 ]
[p]

隣の人に聞くか……[p]

[keyframe name=appear]
[frame p=100% x=-350]
[endkeyframe]

[chara_show name="mocha" width=700 top =100 left="800"  time=200]
[kanim name=mocha keyframe=appear time=600]

……[cm]
この人は宮舞モカさん。[l][r]
隣の席だけど、あまり話したことがない。[p]

#&tf.you
あの……[l][r]
宮舞……さん、ちょっといいかな？[p]

[chara_mod name="mocha" face="surprise" time=200]
#mocha
ふぇっ！？[r]
[haneru chara=mocha]
わ、私……です……か……っ？[p]

[chara_mod name="mocha" face="aseri" time=200]
えっ…えっと、私あの、別にお金とか持ってなくてぇ……！[p]

#&tf.you
いやカツアゲじゃないよ。[p]
(大丈夫かな、この人)[p]

[chara_mod name="mocha" face="frustration" time=200]

ただ、課題の質問したくて。[l][r]
宮舞さんは、課題うまく出来てる感じ？[p]

[chara_mod name="mocha" face="surprise" time=200]
#mocha
あっ、はい。[l][r]
一応、出来てます。[p]
[chara_mod name="mocha" face="akire" time=200]
あの……何か、分からないところとか、ある……ありますか？[p]

#&tf.you
うん、実は……[l][r]
色々質問しちゃっても、いいかな？[p]

[chara_mod name="mocha" face="huhun" time=200]
[haneru chara=mocha]
#mocha
……はいっ！ま、任せてください……！[p]

#&tf.you
(すごい人見知りみたいだけど、プログラミングに関しては頼りになりそう、そんな雰囲気を感じる。)[p]
(分からないことがあれば、どんどん質問してみよう。)[p]

[jump target="*back"]

*back
; 元の画面に戻る
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select/story.ks" target="*start"]