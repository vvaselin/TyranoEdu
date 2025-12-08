*start
[clearfix]
[bg storage="room.jpg" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

; AIチャットUIを初期化して表示
[ai_chat_show]

[show_doc_button file="sample.md"]

; ■■■ 初期設定（UIをfixレイヤーに一度だけ配置） ■■■

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
    "width": "43%", 
    "height": "87%", 
    "z-index": "100" 
});
$("#monaco-iframe").css({ "width": "100%", "height": "100%" });
[endscript]

; --- 結果表示用モーダル---
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
                var $button = $(event.target).closest("button");
                navigator.clipboard.writeText(textToCopy).then(
                    () => {
                        $button.text("コピー完了!");
                        setTimeout(() => { 
                            $button.text("コピー"); 
                        }, 2000);
                    },
                    (err) => {
                        $button.text("失敗");
                        setTimeout(() => { 
                            $button.text("コピー"); 
                        }, 2000);
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
[glink fix="true" color="mybtn_06" storage="editor.ks" text="コードを実行" target="*execute_code" width="400" size="20" x="240" y="650"]
; 実行結果モーダル表示ボタン
[glink fix="true" color="mybtn_01" storage="editor.ks" text="コンソール" target="*open_result_window" width="140" size="20" x="645" y="650"]
; 採点
[glink fix="true" color="mybtn_07" storage="editor.ks" text="提出" target="*submit" width="200" size="20" x="15" y="655"]
; 課題選択に戻る
[glink color="mybtn_09" storage="editor.ks" text="戻る↩" target="*exit_chat" width="200" size="20" x="20" y="10"]

; 課題表示UI
[layopt layer=fix visible=true page=fore]
[html]
<div id="task-box" style="
    position:absolute;
    left:5px; 
    top:68px;
    width:230px; 
    height:575px;
    background-color:rgba(56, 56, 56, 1);
    color:rgb(255, 255, 255);
    border-radius:10px;
    padding:15px;
    overflow:auto;
    box-sizing: border-box;
">
    <h3 id="task-title" style="margin-bottom: 10px;">課題</h3>
    <p id="task-content" style="white-space: pre-wrap;"></p>
    <div id="grade-result-area" style="
        display:none; 
        margin-top:15px; 
        padding:10px; 
        background:rgba(0,0,0,0.5); 
        border-radius:5px;
    ">
        <h4 style="color:#ffcc00; margin:0 0 5px 0;">▼ 採点結果</h4>
        <div id="grade-content" style="font-size:14px; line-height:1.4;">
            </div>
    </div>
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

; すべてのUI配置が終わったので、進行を停止してボタンクリックを待つ、待機状態
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
    var result_text = f.execution_result || "（何も出力されなかったよ）";
    
    // モーダルの中身を更新
    $("#result_modal_content").text(result_text);
    // コピーボタン有効化
    $("#modal_copy_button_id").button("enable");
    
    // 実行時間
    console.error("実行時間：", (performance.now() - f.starttime), "ms");
[endscript]

[return]

*submit
[iscript]
    $("#grade-result-area").show();
    $("#grade-content").html("<span style='color:gray;'>採点中...</span>");
[endscript]
;コード実行
[execute_cpp code=&f.my_code]
; 採点処理
[iscript]
// 課題データ
var task = TYRANO.kag.stat.f.all_tasks[TYRANO.kag.stat.f.current_task_id];
var payload = {
    code: TYRANO.kag.stat.f['my_code'],     
    output: TYRANO.kag.stat.f.execution_result,
    task_desc: task.description,               
    expected_output: task.expected_output || ""
};

$.ajax({
    url: "/api/grade",
    type: "POST",
    data: JSON.stringify(payload),
    contentType: "application/json",
    dataType: "json",
    
    success: function(data) {
        var html = "";

        // 点数によって色を変える演出
        var scoreColor = (data.score >= 80) ? "#00ff00" : "#ff4444";
        html += "<strong style='font-size:18px; color:" + scoreColor + ";'>" + data.score + "点</strong><br>";

        html += "<strong>理由:</strong> " + data.reason + "<br>";
        html += "<strong style='color:#ffffaa;'>アドバイス:</strong> " + data.improvement;      
        $("#grade-content").html(html);
        
        // 合格判定などのフラグ処理があればここに記述
        if(data.score >= 80){
            alertify.success("合格!");
        }
        else{
            alertify.error("不合格...");
        }
    },
    error: function() {
        $("#grade-content").text("採点サーバーとの通信に失敗しました。");
    }
});
[endscript]

[return]

*exit_chat
[iscript]
var $dialog = $("#result_modal");
if ($dialog.dialog("isOpen")) $dialog.dialog("close");

$(".ai-chat-container").css("pointer-events", "none");

// 保存処理を実行し、完了後に *back_real へジャンプ
if (window.mascot_chat_save) {
    window.mascot_chat_save(function() {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*back_real"});
    });
} else {
    // 関数がない場合のフォールバック
    tyrano.plugin.kag.ftag.startTag("jump", {target: "*back_real"});
}
[endscript]
[s]

*back_real
; 元の画面に戻る
[jump storage="select.ks" target="*start"]