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
    "left": "18.5%", 
    "top": "2.5%", 
    "width": "45%", 
    "height": "87%", 
    "z-index": "100" 
});
$("#monaco-iframe").css({ "width": "100%", "height": "100%" });
[endscript]

; --- 結果表示用モーダル---
[loadcss file="./tyrano/libs/jquery-ui/jquery-ui.css"]
[loadcss file="./data/others/css/modal_dark_theme.css"]

[iscript]
// ティラノの変数 f を参照
var f = TYRANO.kag.stat.f;
// fixレイヤーを取得
var fix_layer = $(".fixlayer").first();

// --- モーダルウィンドウのHTMLを定義 ---
var modal_html = `
<div id="result_modal" title="コンソール">
    <pre id="result_modal_content">
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
    minWidth: 300,
    maxWidth: 800,
    minHeight: 200,
    maxHeight: 600,
    position: { my: "center", at: "center", of: window },
    dialogClass: "dialog-dark",
    helper: "ui-resizable-helper",
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
                        alertify.success("実行結果をコピー");
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
    },
    // リサイズの負荷軽減
    resizeStart: function(event, ui) {
        $("#monaco-iframe").css('pointer-events', 'none');
        $(this).find("#result_modal_content").css('visibility', 'hidden');
    },
    resizeStop: function(event, ui) {
        $("#monaco-iframe").css('pointer-events', 'auto');
        $(this).find("#result_modal_content").css('visibility', 'visible');
    }
});
// コピーボタン無効化
$("#modal_copy_button_id").button("disable");
[endscript]

; 実行ボタン
[glink fix="true" color="btn_01_green" storage="editor.ks" text="コードを実行" target="*execute_code" width="410" size="20" x="240" y="650"]
; 実行結果モーダル表示ボタン
[glink fix="true" color="btn_01_blue" storage="editor.ks" text="コンソール" target="*open_result_window" width="150" size="20" x="655" y="650"]

; すべてのUI配置が終わったので、進行を停止してボタンクリックを待つ
[s]

; ■■■ 実行処理（サブルーチン） ■■■
*open_result_window
; モーダルウィンドウを開く
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
; モーダルウィンドウに「実行中...」と表示
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
