; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; スクロールエリアプラグイン　サンプルシナリオ
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

*start

[cm]
[clearfix]
[layopt layer="message0" visible="false"]

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 横スクロールエリアのデモ
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

*horizontal_demo

[cm]
[clearfix]

; タイトル表示
[ptext name="title_h" layer="fix" text="横スクロールエリアデモ" size="40" color="0xFFFFFF" x="400" y="30" bold="true"]

; クエストカード的なボタンを複数作成
[button name="quest1" graphic="icons/quiz_blue.svg" width="200" height="200" x="100" y="100" fix="true"]
[button name="quest2" graphic="icons/quiz_red.svg" width="200" height="200" x="400" y="100" fix="true"]
[button name="quest3" graphic="icons/edit_square_blue.svg" width="200" height="200" x="700" y="100" fix="true"]
[button name="quest4" graphic="icons/edit_square_red.svg" width="200" height="200" x="1000" y="100" fix="true"]
[button name="quest5" graphic="icons/battle.svg" width="200" height="200" x="1300" y="100" fix="true"]
[button name="quest6" graphic="icons/menu_book.svg" width="200" height="200" x="1600" y="100" fix="true"]
[button name="quest7" graphic="icons/person.svg" width="200" height="200" x="1900" y="100" fix="true"]
[button name="quest8" graphic="icons/edit_document.svg" width="200" height="200" x="2200" y="100" fix="true"]

; 横スクロールエリアを作成（幅1280px、高さ400px、内部は2500px分）
[scroll_area id="quest_scroll" width="1280" height="400" contents_w="2500" top="150" left="0"]

; ボタンをスクロールエリア内に配置
[scroll_area_in id="quest_scroll" name="quest1,quest2,quest3,quest4,quest5,quest6,quest7,quest8"]

; 説明テキスト
[ptext name="desc_h" layer="fix" text="←→ボタンまたはマウスホイールでスクロールできます" size="24" color="0xFFFFFF" x="300" y="600" ]

; 次へ進むボタン
[button name="next_v" graphic="button/close.png" width="150" height="60" x="565" y="650" fix="true" target="*vertical_demo"]

[s]

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 縦スクロールエリアのデモ
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

*vertical_demo

[cm]
[clearfix]

; 前のエリアを削除
[scroll_area_del id="quest_scroll"]

; タイトル表示
[ptext name="title_v" layer="fix" text="縦スクロールエリアデモ" size="40" color="0xFFFFFF" x="50" y="30" bold="true"]

; リスト的なアイテムを縦に並べる
[button name="item1" graphic="icons/menu_book.svg" width="300" height="150" x="50" y="50" fix="true"]
[button name="item2" graphic="icons/quiz.svg" width="300" height="150" x="50" y="250" fix="true"]
[button name="item3" graphic="icons/edit.svg" width="300" height="150" x="50" y="450" fix="true"]
[button name="item4" graphic="icons/battle.svg" width="300" height="150" x="50" y="650" fix="true"]
[button name="item5" graphic="icons/person.svg" width="300" height="150" x="50" y="850" fix="true"]
[button name="item6" graphic="icons/content_paste.svg" width="300" height="150" x="50" y="1050" fix="true"]
[button name="item7" graphic="icons/memo.svg" width="300" height="150" x="50" y="1250" fix="true"]
[button name="item8" graphic="icons/edit_document.svg" width="300" height="150" x="50" y="1450" fix="true"]

; 縦スクロールエリアを作成（幅400px、高さ650px、内部は1650px分）
[scroll_area_vertical id="item_list" width="400" height="650" contents_h="1650" top="50" left="50"]

; ボタンをスクロールエリア内に配置
[scroll_area_vertical_in id="item_list" name="item1,item2,item3,item4,item5,item6,item7,item8"]

; 説明テキスト
[ptext name="desc_v" layer="fix" text="▲▼ボタンまたはマウスホイールでスクロールできます" size="24" color="0xFFFFFF" x="500" y="300"]

; キャラクター表示（右側）
[chara_new name="mocha" storage="chara/mocha/normal.png" jname="モカ"]
[chara_show name="mocha" width="600" left="600" top="100"]

; メッセージウィンドウを表示
[layopt layer="message0" visible="true"]
[position layer="message0" left="500" top="450" width="700" height="200"]

[chara_mod name="mocha" storage="chara/mocha/happy.png"]

#モカ
「縦スクロールエリアも使えるよ！リスト表示とかに便利だね！」[p]

; 戻るボタン
[button name="back_h" graphic="button/close.png" width="150" height="60" x="900" y="650" fix="true" target="*cleanup"]

[s]

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; クリーンアップ
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

*cleanup

[cm]
[clearfix]

; スクロールエリアを削除
[scroll_area_vertical_del id="item_list"]

; キャラクターも非表示
[chara_hide name="mocha"]

[layopt layer="message0" visible="true"]

デモ終了。お疲れ様でした！[p]

[jump storage="select.ks" target="*start"]

[s]
