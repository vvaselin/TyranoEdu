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
[filter layer="base" blur=2]
[turn_end]

#
今日の課題は「関数」だった。[l][r]
処理に名前をつけて、必要なときに呼び出す。[p]
説明だけ聞くと便利そうなのに、どこまでを関数に分ければいいのかで手が止まる。[p]

#&tf.you
宮舞さん、ちょっと見てもらってもいい？[p]

[chara_show name="mocha" width=700 left=300 top=50 time=500 face="normal" ]
[manpu layer="0" name="mocha" type=hatena]
#mocha
うん……。[l][r]
今日は、どこで困ってる？[p]

#&tf.you
今回は、先に自分で説明できるか試したいんだ。[p]
えっと……関数は、よく使う処理に名前をつけて、必要なときに呼び出すもの……だよね。[p]

[chara_mod name="mocha" face="surprise" time=200]
[haneru chara=mocha top=50]
#mocha
……はい。[p]

#&tf.you
それで、全部 main に書くより、役割を分けた方が読みやすくなる。[p]
例えば、最大値を返す処理だけ maxOf って名前の関数に任せる、みたいな。[p]

[chara_mod name="mocha" face="hokkori" time=200]
#mocha
……うん、合ってる。[l][r]
かなり整理できてると思う。[p]

#&tf.you
本当？[l][r]
いつも聞いてばかりだから、ちょっと不安で。[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
必要な知識を呼び出すのも、関数みたいだね……。[p]

#&tf.you
宮舞さんも、いざという時に駆けつけてくれて、[r]
関数みたいに頼りになる存在だよ。[p]

[chara_mod name="mocha" face="aseri" time=200]
[manpu layer="0" name="mocha" type=ase]
[yureru_x chara=mocha left=300 time=200]
#mocha
わ、私は関数では……。[p]

#&tf.you
ごめん、変な例えだった……。[l][r]
力になってくれる頼りになる存在、って意味で言ったんだ。[p]

[chara_mod name="mocha" face="terekomari" time=200]
#mocha
……そう言われると、少し安心する。[p]

[mask time=300]
[chara_mod name="mocha" face="magao" ]
[wait time=500]
[mask_off time=300]

#
そのあと、書いた関数を一つずつ見直した。[p]
引数に何を渡すのか、戻り値で何を返すのか。[l][r]
宮舞さんは答えをすぐには言わず、こちらの説明を待ってくれた。[p]

#&tf.you
ここは、関数の中で表示するんじゃなくて、値だけ返した方がいい？[p]

[chara_mod name="mocha" face="thinking" time=200]
#mocha
その方が、使い回しやすいと思う。[l][r]
表示する役割と、計算する役割を分けられるから。[p]

#&tf.you
役割を分ける、か。[l][r]
なんか、前より分かってきた気がする。[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
……うん。えっと、
[font color="0xff4500"]
[emb exp="tf.you"]
[font color="0x000000"]
さ……[p]

[chara_mod name="mocha" face="surprise" time=200]
[haneru chara=mocha top="50" ]
#mocha
あっ。[p]

#&tf.you
ん？[p]

[chara_mod name="mocha" face="aseri" time=200]
[manpu layer="0" name="mocha" type=ase2]
[yureru_x chara=mocha left=300 time=200]
#mocha
な、なんでもないです……！[p]

[chara_mod name="mocha" face="tere" time=200]
[haneru chara=mocha top="50" ]
#mocha
……名前で、呼びそうになった……だけ。[p]

#&tf.you
呼んでくれてもいいのに。[p]

[chara_mod name="mocha" face="sorashi" time=200]
#mocha
あ、あぁ……！それ、ま、まだ……コンパイルが通らない気がする……！[p]

#&tf.you
そっか。[l][r]
じゃあ、ここ直したら――――。[p]

[chara_mod name="mocha" face="tere" time=200]
#mocha
……うん。[l][r]
[chara_mod name="mocha" face="nico" time=200]
そのときは、ちゃんと呼ぶ……と思う。[p]

[chara_hide name="mocha" time=500]

#
答えを教えてもらうだけの時間ではなくなっていた。[p]
自分で考えて、宮舞さんは隣でそれを受け止めてくれる。[l][r]
声をかけられる距離が、少しずつ自然になっていた。[p]

[jump target="*back"]

*back
; 元の画面に戻る
[clearfix]
[free_filter]
[chara_hide name="mocha" time=0]
[jump storage="select/story.ks" target="*start"]
