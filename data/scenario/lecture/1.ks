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
プログラミング言語「C++」の授業中、[r]
大量の課題を前に
[font color="0xff4500"]
[emb exp="tf.you"]
[font color="0x000000"]
は途方に暮れていた。[p]

[chara_show name="teacher" time=500 left=400 top=40 width=400]

#先生
じゃあ、あとは各々で課題やっとくように。[l][r]
分かんなかったら、まぁ……隣の人にでも聞いてくれ。[p]

#
[haneru chara=teacher top=40]
担任は最低限の説明をし終えると、教室を後にした。[l][r]
[chara_move name="teacher" left=1500 anim="true" time=500]
[chara_hide name="teacher" time=0]
生徒の質問を自分が受ける気は無いようだ。[p]

#&tf.you
なんて無責任な先生なんだ……[l][r]
まあ、やるしかないか……[p]

[mask time=300]
[wait time=500]
[mask_off time=300]

#&tf.you
む、難しい！
[quake count=5 time=300 hmax=10 ]
[p]

隣の人に聞くか……[p]

[chara_show name="mocha" width=700 top =50 left="800"  time=500 face="magao" ]
[chara_move name="mocha" left="300" anim="true" time="1000"   ]

#
隣には、黙々とタイピングをする少女、
[font color="0xff4500"] 宮舞モカ
[font color="0x000000"] が座っている。[p]
彼女がクラスの誰かと話しているのを[emb exp="tf.you"]は、あまり見たことが無い。[p]
#&tf.you
(多分、無口な人なんだろうな。優しく声をかけてみよう。)[p]

あの……[l][r]
宮舞……さん、ちょっといいかな？[p]

[chara_mod name="mocha" face="surprise" time=200]
#mocha
ふぇっ！？[r]
[haneru chara=mocha top="50" ]
[manpu layer="0" name="mocha" type=bikkuri2]
わ、私……です……か……っ！？[p]

[chara_mod name="mocha" face="aseri" time=200]
[yureru_x chara=mocha left=300]
[manpu layer="0" name="mocha" type=ase2]
えっ…えっと、ななな何でしょう、何か気に障ることでも……！？[p]

#&tf.you
(大丈夫かな、この人)[p]
[chara_mod name="mocha" face="frustration" time=200]

えっと……急に話しかけてごめん。ただ、課題の質問したくて。[l][r]
宮舞さんは、課題うまく出来てる感じ？[p]

[chara_mod name="mocha" face="surprise" time=200]
#mocha
あっ、はい……。[l][r]
一応……出来てます……。[p]
[chara_mod name="mocha" face="akire" time=200]
あの……何か、分からないところとか、困ってるとこ、ある……ありますか？[p]

#&tf.you
うん、教材みても難しくて……[l][r]
色々質問しちゃっても、いいかな？[p]

[chara_mod name="mocha" face="tere" time=200]
[haneru chara=mocha top="50" ]
#mocha
……は、はいっ！あの……課題の範囲は全然大丈夫なので……。[l][r]
えと……説明……頑張ります……っ。[p]

#&tf.you
(すごい人見知りみたいだけど、プログラミングに関しては頼りになりそう、そんな雰囲気を感じる。)[p]
(分からないことがあれば、どんどん質問してみよう。)[p]

[jump target="*back"]

*back
; 元の画面に戻る
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select/story.ks" target="*start"]
