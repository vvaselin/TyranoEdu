*start
[bg storage="room.jpg" time="0"]
@layopt layer="message0" visible=false

; プラグインを読み込む
[plugin name="monaco_editor"]
[plugin name="glink_ex"]
[plugin name="ai_chat"]

; AIチャットUIを初期化して表示
[stop_keyconfig]
[ai_chat_show]

; 実行ボタンglinkのデザイン用マクロ
[loadcss file="./data/others/css/glink.css"]
[macro name="execute_button"]
[glink fix="true" color=%color storage="first.ks" target=%target text=%text width="640" size="20" x=%x y=%y]
[endmacro]

; ■■■ 初期設定（UIをfixレイヤーに一度だけ配置） ■■■

[iscript]
f.my_code = [
    '#include <iostream>',
    '',
    'int main() {',
    '    std::cout << "Hello, C++ from Tyrano!" << std::endl;',
    '    return 0;',
    '}'
].join('\n');
[endscript]

; --- Monaco Editorを生成し、fixレイヤーに移動 ---
@monaco_show storage="f.my_code"
[iscript]
var editor_wrapper = $("#monaco-iframe").parent();
var fix_layer = $(".fixlayer").first();
fix_layer.append(editor_wrapper);
editor_wrapper.css({ "position": "absolute", "left": "1%", "top": "2%", "width": "50%", "height": "60%", "z-index": "100" });
$("#monaco-iframe").css({ "width": "100%", "height": "100%" });
[endscript]

; --- 結果表示用のptextを、名前をつけてfixレイヤーに配置 ---
;@image layer="fix" name="result_box"  storage="result_box.png" x=10 y=490 time="0" width=645 height=230
;@ptext layer="fix" name="result_text" text="実行結果" x=40 y=510 size=18

[html]
<div id="result_area" class="result_area_style">
    <div id="result_text_content">実行結果</div>
</div>
[endhtml]

[loadcss file="./data/others/css/result_area.css"]

; fixレイヤーに移動させる
[iscript]
    var result_area = $("#result_area");
    var fix_layer = $(".fixlayer").first();
    fix_layer.append(result_area);
    result_area.on("mousedown", function(e) {
        e.stopPropagation();
    });
[endscript]

[execute_button color="btn_01_green" text="コードを実行" target="*execute_code" x="10" y="447"]

; すべてのUI配置が終わったので、進行を停止してボタンクリックを待つ
[s]

; ■■■ 実行処理（サブルーチン） ■■■

*execute_code
; ptextの内容を「実行中...」に上書きする
[iscript]
    $("#result_text_content").html("実行中...");
[endscript]


; サーバーにコードを送信
[iscript]
var cpp_code = f.my_code; 
fetch('http://localhost:8088/execute', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code: cpp_code }),
})
.then(response => {
    if (!response.ok) { return response.text().then(text => { throw new Error(text) }); }
    return response.json();
})
.then(data => {
    f.execution_result = "実行結果:<br>" + data.result.replace(/\n/g, '<br>');
    TYRANO.kag.ftag.startTag('jump', { storage: "first.ks", target: '*display_and_return' });
})
.catch(error => {
    f.execution_result = "エラー:<br>" + error.message.replace(/\n/g, '<br>');
    TYRANO.kag.ftag.startTag('jump', { storage: "first.ks", target: '*display_and_return' });
});
[endscript]
[s]

*display_and_return
; ptextの内容を実行結果に上書きする
[iscript]
    // 実行結果のヘッダーはCSSで表現するので不要に
    // tf.result_text_with_header = '実行結果：<br>' + f.execution_result;
    $("#result_text_content").html(f.execution_result);
[endscript]

; サブルーチンを終了し、*startの[s]の位置に戻る
[return]