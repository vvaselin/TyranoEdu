*start
[clearfix]
[bg storage="room.jpg" time="0"]
@layopt layer="message0" visible=false

; AIチャットUIを初期化して表示
[stop_keyconfig]
[ai_chat_show]

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
editor_wrapper.css({ 
    "position": "absolute", 
    "left": "1%", "top": "2%", 
    "width": "50%", 
    "height": "88%", 
    "z-index": "100" 
});
$("#monaco-iframe").css({ "width": "100%", "height": "100%" });
[endscript]

; --- 結果表示用のptextを、名前をつけてfixレイヤーに配置 ---


[loadcss file="./tyrano/libs/jquery-ui/jquery-ui.css"]

; fixレイヤーに移動させる
[iscript]
// ティラノの変数 f を参照
var f = TYRANO.kag.stat.f;
// fixレイヤーを取得
var fix_layer = $(".fixlayer").first();

// --- モーダルウィンドウのHTMLを定義 ---
var modal_html = `
<div id="result_modal" title="実行結果">
    <pre id="result_modal_content" style="white-space: pre-wrap; word-wrap: break-word; height: 95%; overflow-y: auto; background: #f5f5f5; border: 1px solid #ccc; padding: 5px;">
        実行ボタンを押してね
    </pre>
</div>
`;

// --- HTMLをfixレイヤーに追加し、非表示にする ---
var $modal = $(modal_html);
fix_layer.append($modal);

// --- jQuery UI Dialog として初期化 ---
$modal.dialog({
    autoOpen: false,
    modal: false,
    width: 400,
    height: 300,
    minWidth: 200,
    minHeight: 150,
    position: { my: "center", at: "center", of: window },
    
    buttons: [
        {
            text: "コピー",
            id: "modal_copy_button_id",
            click: function() {
                var $dialog_content = $(this).find("#result_modal_content");
                var textToCopy = $dialog_content.text();
                
                console.log("コピーボタンクリック: ", textToCopy);
                navigator.clipboard.writeText(textToCopy).then(
                    () => {
                        alertify.success("コピーしました！");
                    },
                    (err) => {
                        alert("コピーに失敗しました。");
                    }
                );
            }
        }
    ],
    open: function(event, ui) {
        $(this).css('font-size', '14px');
        $(this).parent().css('z-index', '10002'); 
    }
});
// コピーボタン無効化
$("#modal_copy_button_id").button("disable");
[endscript]

; 実行ボタン
[glink fix="true" color="btn_01_green" storage="editor.ks" text="コードを実行" target="*execute_code" width="485" size="20" x="10" y="650"]
; 実行結果モーダル表示ボタン
[glink fix="true" color="btn_01_blue" storage="editor.ks" text="実行画面" target="*open_result_window" width="160" size="20" x="490" y="650"]

; すべてのUI配置が終わったので、進行を停止してボタンクリックを待つ
[s]

; ■■■ 実行処理（サブルーチン） ■■■

*open_result_window
; モーダルウィンドウを（中身はそのまま）開く
[iscript]
    var $dialog = $("#result_modal");
    if (!$dialog.dialog("isOpen")) {
        $dialog.dialog("open");
    }
    else {
        $dialog.dialog("close");
    }
[endscript]
[return]

*execute_code
; モーダルウィンドウに「実行中...」と表示し、開く
[iscript]
    var $dialog = $("#result_modal");
    // コピーボタン無効化
    $("#modal_copy_button_id").button("disable");
    
    // 中身を更新
    $("#result_modal_content").text("実行中...");
    
    // ダイアログが閉じていたら開く
    if (!$dialog.dialog("isOpen")) {
        $dialog.dialog("open");
    }
    
    // 時間計測開始
    f.starttime = performance.now();
[endscript]

; サーバーにコードを送信 (プラグインが完了するまで待機)
[execute_cpp code=&f.my_code]

; 完了後、モーダルウィンドウの結果を上書きする
[iscript]
    // 実行結果を変数から取得
    var result_text = f.execution_result || "（不明なエラー）";
    
    // モーダルの中身を更新
    $("#result_modal_content").text(result_text);
    // コピーボタン有効化
    $("#modal_copy_button_id").button("enable");
    
    // 実行時間
    console.error("実行時間：", (performance.now() - f.starttime), "ms");
[endscript]

; sのとこに戻る
[return]
