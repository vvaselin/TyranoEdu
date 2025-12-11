;--------------------------------------------------------------------------------
; ティラノスクリプト テーマ一括変換プラグイン theme_kopanda_22_HD_anim
; 作者:こ・ぱんだ
; https://kopacurve.blog.fc2.com/
;--------------------------------------------------------------------------------

[iscript]

mp.font_color    = mp.font_color    || "0x2A2832";
mp.name_color    = mp.name_color    || "0xF2F2F2";
mp.frame_opacity = mp.frame_opacity || "255";
mp.font_color2   = mp.font_color2   || "0x2A2832";
mp.glyph         = mp.glyph         || "on";

if(TG.config.alreadyReadTextColor != "default") {
	TG.config.alreadyReadTextColor = mp.font_color2;
}

[endscript]

; 名前部分のメッセージレイヤ削除
[free name="chara_name_area" layer="message0"]

; メッセージウィンドウの設定
[position layer="message0" width="1200" height="186" top="524" left="40"]
[position layer="message0" frame="../others/plugin/theme_kopanda_22_HD_anim/image/frame_message.png" margint="60" marginl="120" marginr="130" marginb="30" opacity="&mp.frame_opacity" page="fore"]

; 名前枠の設定
[ptext name="chara_name_area" layer="message0" color="&mp.name_color" size="22" x="110" y="530" width="340" align="center"]
[chara_config ptext="chara_name_area"]

; デフォルトのフォントカラー指定
[font color="&mp.font_color"]
[deffont color="&mp.font_color"]

; デフォルトのフォントサイズ指定
[font size="28"]
[deffont size="28"]

; クリック待ちグリフの設定（on設定時のみ有効）
; 初期設定を「on」にしているのでプラグイン導入時に指定しなくてもOKです
[if exp="mp.glyph == 'on'"]
[glyph line="../../../data/others/plugin/theme_kopanda_22_HD_anim/image/system/nextpage.png"]
[endif]

;=================================================================================

; システムボタンを表示するマクロ

;=================================================================================

; システムボタンを表示したいシーンで[add_theme_button]と記述
; 消去するときは[clearfix name="role_button"]で消えます
[macro name="add_theme_button"]

; デフォルトのメニューボタンを消す
[hidemenubutton]

[iscript]

	tf.sysbtn_img_path   = '../others/plugin/theme_kopanda_22_HD_anim/image/button/'; // 画像のパス
	tf.sysbtn_img_width  = 54; // システムボタンの幅
	tf.sysbtn_img_height = 64; // システムボタンの高さ
	tf.sysbtn_posx       = [790, 856, 922, 988, 1054, 1120]; // 配置するX座標
	tf.sysbtn_posy       = 510; // 配置するY座標

[endscript]


; Q.Save
[button name="role_button" role="quicksave" graphic="&tf.sysbtn_img_path + 'qsave.png'" enterimg="&tf.sysbtn_img_path + 'qsave2.png'" activeimg="&tf.sysbtn_img_path + 'qsave3.png'" width="&tf.sysbtn_img_width" height="&tf.sysbtn_img_height" x="&tf.sysbtn_posx[0]" y="&tf.sysbtn_posy"]

; Q.Load
[button name="role_button" role="quickload" graphic="&tf.sysbtn_img_path + 'qload.png'" enterimg="&tf.sysbtn_img_path + 'qload2.png'" activeimg="&tf.sysbtn_img_path + 'qload3.png'" width="&tf.sysbtn_img_width" height="&tf.sysbtn_img_height" x="&tf.sysbtn_posx[1]" y="&tf.sysbtn_posy"]

; Backlog
[button name="role_button" role="backlog" graphic="&tf.sysbtn_img_path + 'log.png'" enterimg="&tf.sysbtn_img_path + 'log2.png'" activeimg="&tf.sysbtn_img_path + 'log3.png'" width="&tf.sysbtn_img_width" height="&tf.sysbtn_img_height" x="&tf.sysbtn_posx[2]" y="&tf.sysbtn_posy"]

; Auto
[button name="role_button" role="auto" graphic="&tf.sysbtn_img_path + 'auto.png'" enterimg="&tf.sysbtn_img_path + 'auto2.png'" activeimg="&tf.sysbtn_img_path + 'auto3.png'" autoimg="&tf.sysbtn_img_path + 'auto4.png'" width="&tf.sysbtn_img_width" height="&tf.sysbtn_img_height" x="&tf.sysbtn_posx[3]" y="&tf.sysbtn_posy"]

; Skip
[button name="role_button" role="skip" graphic="&tf.sysbtn_img_path + 'skip.png'" enterimg="&tf.sysbtn_img_path + 'skip2.png'" activeimg="&tf.sysbtn_img_path + 'skip3.png'" skipimg="&tf.sysbtn_img_path + 'skip4.png'" width="&tf.sysbtn_img_width" height="&tf.sysbtn_img_height" x="&tf.sysbtn_posx[4]" y="&tf.sysbtn_posy"]

; Screen
[button name="role_button" role="fullscreen" graphic="&tf.sysbtn_img_path + 'screen.png'" enterimg="&tf.sysbtn_img_path + 'screen2.png'" activeimg="&tf.sysbtn_img_path + 'screen3.png'" width="&tf.sysbtn_img_width" height="&tf.sysbtn_img_height" x="&tf.sysbtn_posx[5]" y="&tf.sysbtn_posy"]

; Menu
[button name="role_button" role="menu" graphic="&tf.sysbtn_img_path + 'menu.png'" enterimg="&tf.sysbtn_img_path + 'menu2.png'" activeimg="&tf.sysbtn_img_path + 'menu3.png'" width="80" height="84" x="1176" y="24"]

; Close
[button name="role_button" role="window" graphic="&tf.sysbtn_img_path + 'close.png'" enterimg="&tf.sysbtn_img_path + 'close2.png'" width="24" height="24" x="1198" y="564"]

[endmacro]


;=================================================================================

; システムで利用するHTML,CSSの設定

;=================================================================================
; セーブ画面
[sysview type="save" storage="./data/others/plugin/theme_kopanda_22_HD_anim/html/save.html"]

; ロード画面
[sysview type="load" storage="./data/others/plugin/theme_kopanda_22_HD_anim/html/load.html"]

; バックログ画面
[sysview type="backlog" storage="./data/others/plugin/theme_kopanda_22_HD_anim/html/backlog.html"]

; メニュー画面
[sysview type="menu" storage="./data/others/plugin/theme_kopanda_22_HD_anim/html/menu.html"]

; CSS
[loadcss file="./data/others/plugin/theme_kopanda_22_HD_anim/css/ts22.css"]

; メニュー画面からコンフィグを呼び出すための設定ファイル
[loadjs storage="plugin/theme_kopanda_22_HD_anim/setting.js"]

;=================================================================================

; テストメッセージ出力プラグインの読み込み

;=================================================================================
[loadjs storage="plugin/theme_kopanda_22_HD_anim/testMessagePlus/gMessageTester.js"]
[loadcss file="./data/others/plugin/theme_kopanda_22_HD_anim/testMessagePlus/style.css"]

[macro name="test_message_start"]
[eval exp="gMessageTester.create()"]
[endmacro]

[macro name="test_message_end"]
[eval exp="gMessageTester.destroy()"]
[endmacro]

[macro name="test_message_reset"]
[eval exp="gMessageTester.currentTextNumber=0;gMessageTester.next(true)"]
[endmacro]


[return]
