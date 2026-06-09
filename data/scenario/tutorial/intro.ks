*start

[mask time=500]
[clearfix]
[start_keyconfig]
[add_theme_button]
[bg storage="standard.png" time="0"]
[free_filter layer="base"]
[layopt layer="message0" visible=true]

[iscript]
tf.system.backlog=[];
tf.you = f.user_name;
[endscript]

[mask_off time=500]

[chara_show name="mocha" face="normal" time="50" left=300 width=800 top=50 wait="true"]
[haneru chara=mocha top=50]
#モカ
こんにちは。[l][r]
これはプログラミング言語「C++」の学習システムです。[p]

チュートリアルを読みますか？[p]

[glink color="ts22" text="チュートリアルを読む" target="*read_tutorial" width="500" size="30" x="400" y="200"]

[glink color="ts22" text="チュートリアルを読まない" target="*after_role_intro" width="500" size="30" x="400" y="400"]

[s]

*read_tutorial
では、このシステムでできることを少しだけ説明します。[p]

[font color="0xff4500"]
[emb exp="tf.you"]
[font color="0x000000"]
さんには、これからC++を勉強しながら、物語を進めてもらいます。[p]

[chara_tilt name="mocha" deg=-20 time=180 origin="50% 30%"]
[chara_mod name="mocha" face="hokkori" time=200]
[chara_move name="mocha" left="1000" top=100 width=600 anim="true" time="500" ]


[layopt layer="2" visible="true"  ]

[if exp="f.user_role == 'experimental'" ]
    [image storage="tutorial/ホームex.png" layer="2"  width=800 time=500 x=100 y=50]
[else]
    [image storage="tutorial/ホームco.png" layer="2"  width=800 time=500 x=100 y=50]
[endif]

これがホーム画面です。[l][r]
ここから色々な機能を選択できます。[p]

[chara_mod name="mocha" face="sorashi" time=200]
一部開発中の機能もありますけど……。[p]

[freeimage layer="2" ]
[image storage="tutorial/エピソード選択.png" layer="2"  width=800 time=500 x=100 y=50]

[chara_mod name="mocha" face="normal" time=200]
これがエピソード選択。[l][r]
[chara_mod name="mocha" face="huhun" time=200]
解放条件などは、個別に書いてあるので見てみてください。[p]

[freeimage layer="2" ]
[image storage="tutorial/課題選択.png" layer="2"  width=800 time=500 x=100 y=50]
これが課題選択。[p]
[chara_mod name="mocha" face="thinking" time=200]
まずは、各カテゴリ2問以上クリアするのを目指してほしいです。[p]

[rect_show name="task_button" x=545 y=430 width=300 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
やりたい課題を選択して、「この課題を始める」のボタンを押して演習画面に進んでください。[p]

[freeimage layer="2" ]
[rect_hide name="task_button"]

[chara_mod name="mocha" face="normal" time=200]
[jump target="*ex" cond="f.user_role == 'experimental'"]
[jump target="*control" cond="f.user_role == 'control'" ]

*ex
[image storage="tutorial/エディタex.png" layer="2"  width=800 time=500 x=100 y=50]
これが演習画面です。[l][r]
ここで、コードを書いて課題を解いていきます。[p]
[rect_show name="exe_button" x=250 y=450 width=260 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
積極的に実行して、コードがどう動くか試してみてください。[p]

課題についてでも、C++についてでも、[l][r]
[rect_hide name="exe_button"]
[rect_show name="chat" x=650 y=450 width=180 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
[chara_mod name="mocha" face="nico" time=200]
わからないことがあったら、右のチャットから聞いてくださいね。[p]

[chara_mod name="mocha" face="tere" time=200]
[yureru_x chara=mocha left=1000 time=200]
勉強を頑張ると、私との親密度が上がりますよ……。[p]
[rect_hide name="chat"]

[rect_show name="hint" x=650 y=450 width=180 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
[chara_mod name="mocha" face="thinking" time=200]
ヒントが読みたいときはヒント開いたり、[l][r]
[rect_show name="doc" x=650 y=450 width=180 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
[haneru chara=mocha top=100]
教材を開いて、読んでみるのも良いかもしれません。[p]

[rect_hide name="hint"]
[rect_hide name="doc"]

[rect_show name="sub_button" x=100 y=450 width=150 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
[chara_mod name="mocha" face="huhun" time=200]
コードを書いて上手く実行出来たら、採点ボタンを押してみてください。[p]

[rect_hide name="sub_button"]
課題を解きつつ、物語を進めましょう。[p]
[freeimage layer="2" ]

[chara_untilt name="mocha" time=180]
[chara_move name="mocha" left=300 top=50 width=800 anim="true" time="500" ]
[jump target="*after_role_intro"]

*control
[image storage="tutorial/エディタco.png" layer="2"  width=800 time=500 x=100 y=50]
これが演習画面です。[l][r]
ここで、コードを書いて課題を解いていきます。[p]
[rect_show name="exe_button" x=250 y=450 width=260 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
積極的に実行して、コードがどう動くか試してみてください。[p]

課題についてでも、C++についてでも、[l][r]
[rect_hide name="exe_button"]
[rect_show name="chat" x=650 y=450 width=180 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
[chara_mod name="mocha" face="nico" time=200]
わからないことがあったら、右のチャットから聞いてくださいね。[p]
[rect_hide name="chat"]

[rect_show name="hint" x=650 y=450 width=180 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
[chara_mod name="mocha" face="thinking" time=200]
ヒントが読みたいときはヒント開いたり、[l][r]
[rect_show name="doc" x=650 y=450 width=180 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
[haneru chara=mocha top=100]
教材を開いて、読んでみるのも良いかもしれません。[p]

[rect_hide name="hint"]
[rect_hide name="doc"]

[rect_show name="sub_button" x=100 y=450 width=150 height=50 color="#ff4500" border=4 bg="rgb(0,0,0,0)" radius=5]
[chara_mod name="mocha" face="huhun" time=200]
コードを書いて上手く実行出来たら、採点ボタンを押してみてください。[p]
[rect_hide name="sub_button"]
課題を解きつつ、物語を進めましょう。[p]
[freeimage layer="2" ]

[chara_untilt name="mocha" time=180]
[chara_move name="mocha" left=300 top=50 width=800 anim="true" time="500" ]
*after_role_intro

[chara_mod name="mocha" face="nico"]
#モカ
[haneru chara=mocha top=50]
[manpu layer="0" name="mocha" type=onpu]
それじゃあ、はじめましょう。[p]

[mask time=500]
[chara_hide name="mocha" time=0]
[clearfix]

[if exp="f.tutorial_from_home == true"]
    [eval exp="f.tutorial_from_home = false"]
[endif]
[jump storage="home.ks" target="*start" cond="f.tutorial_from_home == true"]
[jump storage="first.ks" target="*load_user_data" cond="f.tutorial_from_home == false"]
