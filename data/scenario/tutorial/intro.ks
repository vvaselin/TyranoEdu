*start

[mask time=500]
[clearfix]
[start_keyconfig]
[add_theme_button]
[bg storage="bunkabu.jpg" time="0"]
[free_filter layer="base"]
[layopt layer="message0" visible=true]

[chara_show name="mocha" face="normal" time="50" left=735 width=520 top=145 wait="true"]
[mask_off time=500]

#モカ
最初に、このアプリでできることを少しだけ説明します。[p]


[chara_mod name="mocha" face="nico" time=200]
#モカ
それじゃあ、はじめよう。[p]

[mask time=500]
[chara_hide name="mocha" time=0]
[clearfix]

[if exp="f.tutorial_from_home == true"]
    [eval exp="f.tutorial_from_home = false"]
    [jump storage="home.ks" target="*start"]
[else]
    [jump storage="first.ks" target="*load_user_data"]
[endif]
