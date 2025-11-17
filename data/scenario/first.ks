*start
[bg storage="rouka.jpg" time="0"]
@layopt layer="message0" visible=false

; プラグインを読み込む
[plugin name="monaco_editor"]
[plugin name="cpp_executor"]
[plugin name="glink_ex"]
[plugin name="mascot_chat"]

; 実行ボタンglinkのデザイン用マクロ
[loadcss file="./data/others/css/glink.css"]
[macro name="start_button"]
[glink color=%color storage="first.ks" target=%target text=%text width="640" size="20" x=%x y=%y]
[endmacro]


[start_button color="btn_01_blue" target="*editor_start" text="コードエディタを開く" x="50" y="70"]

[s]

*editor_start

[jump storage="editor.ks" target="*start"]

[s]
