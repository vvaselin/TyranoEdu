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
今日の課題は「関数」だった。[l][r]
処理に名前をつけて、必要なときに呼び出す。[p]
説明だけ聞くと便利そうなのに、どこまでを関数に分ければいいのかで手が止まる。[p]

#&tf.you
宮舞さん、ちょっと見てもらってもいい？[p]

[chara_show name="mocha" width=700 left=300 top=50 time=500 face="normal" ]

#mocha
うん……。[l][r]
今日は、どこで困ってる？[p]

#&tf.you
今回は、先に自分で説明できるか試したいんだ。[p]
えっと……関数は、よく使う処理に名前をつけて、必要なときに呼び出すもの……だよね。[p]

[chara_mod name="mocha" face="surprise" time=200]
#mocha
……はい。[p]

#&tf.you
それで、全部 main に書くより、役割を分けた方が読みやすくなる。[l][r]
例えば、最大値を返す処理だけ maxOf に任せる、みたいな。[p]

[chara_mod name="mocha" face="hokkori" time=200]
#mocha
……うん、合ってる。[l][r]
かなり整理できてると思う。[p]

#&tf.you
本当？[l][r]
いつも聞いてばかりだから、ちょっと不安で。[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
今日は、私は先生役じゃなくて……確認役、だね。[p]

#&tf.you
確認役か。[l][r]
それ、頼もしいな。[p]

[chara_mod name="mocha" face="tere" time=200]
#mocha
頼もしい……んだ。[p]

#&tf.you
うん。[l][r]
必要なときに呼び出せる関数みたいで。[p]

[chara_mod name="mocha" face="aseri" time=200]
#mocha
わ、私は関数では……。[p]

#&tf.you
ごめん、変な例えだった。[l][r]
でも、いてくれると処理が進むというか……考えやすいんだ。[p]

[chara_mod name="mocha" face="terekomari" time=200]
#mocha
……そう言われると、少し安心する。[p]

[mask time=300]
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
……うん。えっと、[emb exp="tf.you"]さ……[p]

[chara_mod name="mocha" face="surprise" time=200]
[haneru chara=mocha top="50" ]
#mocha
あっ。[p]

#&tf.you
ん？[p]

[chara_mod name="mocha" face="aseri" time=200]
#mocha
な、なんでもないです……！[l][r]
今のは、呼び出し間違いというか……。[p]

#&tf.you
呼び出し間違い？[p]

[chara_mod name="mocha" face="tere" time=200]
#mocha
……名前で、呼びそうになった……だけ。[p]

#&tf.you
呼んでくれてもいいのに。[p]

[chara_mod name="mocha" face="komari" time=200]
#mocha
ま、まだ……コンパイルが通らない気がする。[p]

#&tf.you
そっか。[l][r]
じゃあ、通りそうになったらで。[p]

[chara_mod name="mocha" face="nico" time=200]
#mocha
……うん。[l][r]
そのときは、ちゃんと呼ぶ……と思う。[p]

#
答えを教えてもらうだけの時間ではなくなっていた。[p]
考える役割は自分にあり、宮舞さんは隣でそれを受け止めてくれる。[l][r]
必要なときに声をかけられる距離が、少しずつ自然になっていた。[p]

[jump target="*back"]

*back
; 元の画面に戻る
[clearfix]
[chara_hide name="mocha" time=0]
[jump storage="select/story.ks" target="*start"]
