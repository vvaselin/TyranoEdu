*start

[mask time=500]
[clearfix]
[start_keyconfig]
[add_theme_button]
[bg storage="standard.png" time="0"]
[free_filter layer="base"]
[layopt layer="message0" visible=true]

[chara_show name="mocha" face="normal" time="50" left=300 width=800 top=50 wait="true"]
[mask_off time=500]

#モカ
こんにちは。[l][r]
これはプログラミング言語「C++」の学習システムです。[p]
最初に、このシステムでできることを少しだけ説明します。[p]

[chara_move name="mocha" left="750" top=100 width=600 anim="true" time="500" ]

[layopt layer="2" visible="true"  ]

[if exp="f.user_role == 'experimental'" ]
    [image storage="tutorial/ホームex.png" layer="2"  width=800 time=500 x=100 y=50]
[else]
    [image storage="tutorial/ホームco.png" layer="2"  width=800 time=500 x=100 y=50]
[endif]

これがホーム画面です。[l][r]
ここから色々な機能を選択できます。[p]

[freeimage layer="2" ]
[image storage="tutorial/エピソード選択.png" layer="2"  width=800 time=500 x=100 y=50]

これがエピソード選択。[l][r]
[chara_mod name="mocha" face="huhun" time=200]
解放条件などは、個別に書いてあるので見てみてください。[p]

[freeimage layer="2" ]
[image storage="tutorial/課題選択.png" layer="2"  width=800 time=500 x=100 y=50]
これが課題選択。[p]
[chara_mod name="mocha" face="thinking" time=200]
どれから初めてもいいですけど、各カテゴリ3問以上クリアするのを目指してほしいです。[p]

やりたい課題を選択して、「この課題を始める」のボタンを押して演習画面に進んでください。[p]

[freeimage layer="2" ]

[chara_mod name="mocha" face="normal" time=200]
[jump target="*ex" cond="f.user_role == 'experimental'"]
[jump target="*control" cond="f.user_role == 'control'" ]

*ex
[image storage="tutorial/エディタex.png" layer="2"  width=800 time=500 x=100 y=50]
これが演習画面です。[l][r]
ここで、コードを書いて課題を解いていきます。[p]
積極的に実行して、コードがどう動くか試してみてください。[p]

課題についてでも、C++についてでも、[l][r]
わからないことがあったら、右のチャットから聞いてくださいね。[p]

勉強を頑張ると、私との親密度が上がりますよ……。[p]

コードを書いて上手く実行出来たら、採点ボタンを押してみてください。[p]

[jump target="*after_role_intro"]

*control
[image storage="tutorial/エディタco.png" layer="2"  width=800 time=500 x=100 y=50]
これが演習画面です。[l][r]
ここで、コードを書いて課題を解いていきます。[p]
積極的に実行して、コードがどう動くか試してみてください。[p]

課題についてでも、C++についてでも、[l][r]
わからないことがあったら、右のチャットから聞いてくださいね。[p]

コードを書いて上手く実行出来たら、採点ボタンを押してみてください。[p]

*after_role_intro
課題を解きつつ、物語も楽しんでいってくださいね。[p]

[freeimage layer="2" ]
[chara_mod name="mocha" face="nico" time=200]
#モカ
それじゃあ、はじめましょう。[p]

[mask time=500]
[chara_hide name="mocha" time=0]
[clearfix]

[if exp="f.tutorial_from_home == true"]
    [eval exp="f.tutorial_from_home = false"]
[endif]
[jump storage="home.ks" target="*start" cond="f.tutorial_from_home == true"]
[jump storage="first.ks" target="*load_user_data" cond="f.tutorial_from_home == false"]
