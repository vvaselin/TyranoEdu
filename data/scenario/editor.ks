*start
[clearfix]
[bg storage="room.jpg" time="0"]
@layopt layer="message0" visible=false

; 課題データの読み込み
[iscript]
// 読み込む JSON ファイルのパス
var json_path = "./data/others/tasks.json";

$.ajax({
    url: json_path,
    type: 'GET',
    dataType: 'json',
    async: false,
    
    success: function(data) {
        TYRANO.kag.stat.f.all_tasks = data;
        console.log("tasks.json 読み込み成功:", TYRANO.kag.stat.f.all_tasks);
    },
    
    error: function(xhr, status, error) {
        console.error("tasks.json 読み込み失敗:", json_path, error);
        
        TYRANO.kag.stat.f.all_tasks = { 
            "error_task": { 
                "title": "読込失敗", 
                "description": "tasks.json が見つかりません。\nパスを確認してください。" 
            }
        };
        TYRANO.kag.stat.f.current_task_id = "error_task";
    }
});
[endscript]

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

; 課題表示UI
[eval exp="f.current_task_id = sf.current_task_id || 'task1'"]
[layopt layer=fix visible=true page=fore]
[html]
<div id="task-box" style="
    position:absolute;
    left:5px; 
    top:15px;
    width:230px; 
    height:650px;
    background-color:rgba(56, 56, 56, 1);
    color:rgb(255, 255, 255);
    border-radius:10px;
    padding:15px;
    overflow:auto;
    box-sizing: border-box;
">
    <h3 id="task-title" style="margin-bottom: 10px;">課題</h3>
  <p id="task-content" style="white-space: pre-wrap;"></p>
</div>
[endhtml]

[iscript]
var tasks = TYRANO.kag.stat.f.all_tasks;
var current_id = TYRANO.kag.stat.f.current_task_id;

var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;

if (task_data) {
    // 成功: データをUIにセット
    $("#task-title").text(task_data.title);
    $("#task-content").text(task_data.description);
} else {
    // 失敗: 課題IDが見つからない
    $("#task-title").text("エラー");
    var error_msg = "課題ID「" + current_id + "」が見つかりません。";
    if (!tasks) {
        error_msg += " (tasks.json が未ロード)";
    }
    $("#task-content").text(error_msg);
}
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

*send_chat_context
[iscript]
// デバッグログ 1
console.log("デバッグ: *send_chat_context が呼び出されました。");
[endscript]

; 1. Monaco Editor から現在のコードを取得
[monaco_editor_get_value variable="tf.current_code"]
[commit] ; 取得完了を待つ

; 2. [iscript] でプロンプトを組み立ててサーバーに送信
[iscript]
    // デバッグログ 2
    console.log("デバッグ: [monaco_editor_get_value] を通過。fetch処理を開始します。");

    // 必要な変数をJS側で取得
    var user_message = TYRANO.kag.stat.tf.chat_message || "";
    var code_content = TYRANO.kag.stat.tf.current_code || "（コードなし）";
    
    // 課題内容を取得
    var tasks = TYRANO.kag.stat.f.all_tasks;
    var current_id = TYRANO.kag.stat.f.current_task_id;
    var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
    var task_description = task_data ? task_data.description : "（課題なし）";

    // サーバーに渡す新しいペイロード
    var payload = {
        message: user_message,
        code: code_content,
        task: task_description
    };
    
    // デバッグログ 3
    console.log("デバッグ: サーバーに送信するペイロード", payload);

    // AIサーバー（main.go）へ送信 (相対パス)
    fetch('/api/chat', { 
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
    })
    .then(response => {
        // デバッグログ 4
        console.log("デバッグ: サーバーから応答あり (status: " + response.status + ")");
        if (!response.ok) {
            // サーバーがエラーを返した場合 (例: 500 Internal Server Error)
            return response.text().then(text => { 
                throw new Error("サーバーエラー (Status " + response.status + "): " + (text || response.statusText)); 
            });
        }
        return response.json(); // 正常なJSONレスポンスを次に渡す
    })
    .then(data => {
        // デバッグログ 5
        console.log("デバッグ: 応答データをチャット欄に表示します。");
        
        // 成功時: グローバル化した addMessage で応答をチャット欄に追加
        TYRANO.kag.plugin.ai_chat.addMessage("あかね", data.text, "./data/fgimage/chat/akane/hirameki.png");
    })
    .catch(error => {
        // デバッグログ 6 (エラー発生時)
        console.error("AIチャットfetchエラー:", error);
        
        // ★★★ エラー内容をチャット欄に表示する ★★★
        // (ネットワークエラー、タイムアウト、JSONパースエラーなど)
        TYRANO.kag.plugin.ai_chat.addErrorMessage(
            "AIとの通信に失敗しました。\n" + 
            "（コンソールで詳細を確認してください）\n" +
            "エラー: " + error.message
        );
    })
    .finally(() => {
        // デバッグログ 7
        console.log("デバッグ: .finally ブロック実行。UIを有効に戻します。");
        
        // ★★★ 成功・失敗に関わらず、必ずUIを元に戻す ★★★
        $(".ai-chat-input").prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
        $(".ai-chat-send-button").prop("disabled", false);
    });
[endscript]

; サブルーチンから戻る
[return]