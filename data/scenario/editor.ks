*start
[clearfix]
[wait time=10]

[bg storage="room.jpg" time="0"]
@layopt layer="message0" visible=false

; AIチャットUIを初期化して表示
[stop_keyconfig]
[ai_chat_show]

[wait time=10]

; 実行ボタンglinkのデザイン用マクロ
[loadcss file="./data/others/css/glink.css"]
[macro name="execute_button"]
[glink fix="true" color=%color storage="editor.ks" target=%target text=%text width="640" size="20" x=%x y=%y]
[endmacro]

; ■■■ 初期設定（UIをfixレイヤーに一度だけ配置） ■■■

[iscript]
f.my_code = [
    '#include <iostream>',
    '',
    'int main() {',
    '    std::cout << "Hello World!" << std::endl;',
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
editor_wrapper.css({ "position": "absolute", "left": "1%", "top": "2%", "width": "50%", "height": "67%", "z-index": "100" });
$("#monaco-iframe").css({ "width": "100%", "height": "100%" });
[endscript]

; --- 結果表示用のptextを、名前をつけてfixレイヤーに配置 ---

[html]
<div id="result_area" class="result_area_style">
    <pre id="result_text_content">実行結果</pre>
    <button class="copy-result-button" id="result_copy_btn" style="display:none;">コピー</button>
</div>
[endhtml]

[loadcss file="./data/others/css/result_area.css"]

; fixレイヤーに移動させる
[iscript]
    var result_area = $("#result_area");
    var fix_layer = $(".fixlayer").first();
    fix_layer.append(result_area);
    
    result_area.on("mousedown mouseup mousemove", function(e) {
        e.stopPropagation();
    });
[endscript]

; --- コピーボタンにクリックイベントを設定 ---
[iscript]
(function() {
    var $button = $("#result_copy_btn");
    
    $button.on("click", function (e) {
        // ティラノスクリプト本体へのクリック伝播を停止
        e.stopPropagation();
        
        // コピー対象のテキストを取得
        var textToCopy = $("#result_text_content").text();

        // "実行結果:\n" または "エラー:\n" というプレフィックスを削除
        if (textToCopy.startsWith("実行結果:\n")) {
            textToCopy = textToCopy.substring("実行結果:\n".length);
        } else if (textToCopy.startsWith("エラー:\n")) {
            textToCopy = textToCopy.substring("エラー:\n".length);
        }

        // クリップボードにコピー
        navigator.clipboard.writeText(textToCopy).then(
            () => {
                // ティラノ標準のalertifyで通知
                alertify.success("コピーしました！");
            },
            (err) => {
                console.error("クリップボードへのコピーに失敗しました:", err);
                alertify.error("コピーに失敗しました");
            }
        );
    });
})();
[endscript]

[execute_button color="btn_01_green" text="コードを実行" target="*execute_code" x="10" y="500"]

; すべてのUI配置が終わったので、進行を停止してボタンクリックを待つ
[s]

; ■■■ 実行処理（サブルーチン） ■■■

*execute_code
; ptextの内容を「実行中...」に上書きする
[iscript]
    $("#result_text_content").text("実行中...");
    $("#result_copy_btn").hide(); // ボタンを隠す
    f.starttime = performance.now();
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
    f.execution_result = "実行結果:\n" + data.result;
    TYRANO.kag.ftag.startTag('jump', { storage: "editor.ks", target: '*display_and_return' });
    f.endtime = performance.now();
    console.log(`コード実行時間: ${f.endtime - f.starttime} ミリ秒`);
})
.catch(error => {
    f.execution_result = "エラー:\n" + error.message;
    TYRANO.kag.ftag.startTag('jump', { storage: "editor.ks", target: '*display_and_return' });
});
[endscript]
[s]

*display_and_return
; ptextの内容を実行結果に上書きする
[iscript]
    $("#result_text_content").text(f.execution_result);
    $("#result_copy_btn").show(); // ボタンを表示
[endscript]

; サブルーチンを終了し、*startの[s]の位置に戻る
[return]