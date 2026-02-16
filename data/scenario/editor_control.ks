*start
[mask time=1000]
[hidemenubutton]
[clearfix]
@layopt layer="message0" visible=false
[bg storage="standard.png" time="0"]
[stop_keyconfig]

; AIチャットUIを初期化して表示
[ai_chat_show]

[show_doc_button file="top.md"]

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
// 明示的に読み込む
tyrano.plugin.kag.ftag.startTag("loadcss", {file: "./data/others/css/modal_dark_theme.css"});
// ティラノの変数 f を参照
var f = TYRANO.kag.stat.f;
// fixレイヤーを取得
var fix_layer = $(".fixlayer").first();
// 二重生成防止のため、既存のモーダルがあれば削除
$("#result_modal").remove();

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
    classes: {
        "ui-dialog": "dialog-dark"
    },
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
[glink fix="true" color="mybtn_06" text="コードを実行" target="*execute_code" width="400" size="20" x="240" y="650"]
; 実行結果モーダル表示ボタン
[glink fix="true" color="mybtn_01" text="コンソール" target="*open_result_window" width="140" size="20" x="645" y="650"]
; 採点
[if exp="f.is_sandbox == false"]
    [glink fix="true" color="mybtn_07" text="提出" target="*submit" width="200" size="20" x="15" y="655" ]
[endif]
; 課題選択に戻る
[glink color="mybtn_09" text="戻る↩" target="*exit_chat" width="200" size="20" x="20" y="10"]

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
    <p id="task-content" style="white-space: pre-wrap; margin-bottom: 15px;"></p>

    <div id="expected-output-area" style="
        display:none;
        background-color: rgba(255, 255, 255, 0.08);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 8px;
        padding: 10px;
        margin-bottom: 15px;
    ">
        <div style="font-size:12px; color:#aaa; margin-bottom:5px;">▼ 期待される出力</div>
        <div id="expected-output-text" style="
            font-family: monospace;
            font-size: 14px;
            white-space: pre-wrap;
            color: #8edc9d;
        "></div>
    </div>

    <div id="custom-stdin-area" style="
    display:none;
    background-color: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 10px;
    margin-bottom: 15px;
">
    <div style="font-size:12px; color:#aaa; margin-bottom:5px;">▼ 標準入力 (stdin)</div>
        <textarea id="custom-stdin-text" style="
            width: 100%;
            height: 60px;
            background: #222;
            color: #fff;
            border: 1px solid #444;
            border-radius: 4px;
            box-sizing: border-box;
            padding: 5px;
            font-family: monospace;
            font-size: 14px;
            resize: vertical;
        "></textarea>
    </div>

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

    if (TYRANO.kag.stat.f.is_sandbox) {
        $("#expected-output-area").hide(); // 期待される出力を隠す
        $("#custom-stdin-area").show();    // 自由入力欄を表示

        // 入力欄の内容を tasks["sandbox"].stdin に反映させる
        $("#custom-stdin-text").on("input", function() {
            tasks["sandbox"].stdin = $(this).val();
        });
        
        // 初期値をセット（tasks.jsonに記述がある場合）
        $("#custom-stdin-text").val(task_data.stdin || "");
    } else {
        // 通常の課題モード
        $("#custom-stdin-area").hide();
        if (task_data.expected_output && task_data.expected_output !== "") {
            $("#expected-output-area").show();
            $("#expected-output-text").text(task_data.expected_output);
        } else {
            $("#expected-output-area").hide();
        }
    }
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
[mask_off time=1000]

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
    var result_text = f.execution_result || "（出力なし）";
    
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

; コード実行 (silent="true" でAIが実行結果を喋らないように制御)
[execute_cpp code=&f.my_code silent="true"]

[iscript]
    var task = TYRANO.kag.stat.f.all_tasks[TYRANO.kag.stat.f.current_task_id];
    var payload = {
        user_id: TYRANO.kag.stat.f.user_id,
        task_id: TYRANO.kag.stat.f.current_task_id,
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
            var scoreColor = (data.score >= 80) ? "#00ff00" : "#ff4444";
            html += "<strong style='font-size:18px; color:" + scoreColor + ";'>" + data.score + "点</strong><br>";
            html += "<strong>理由:</strong> " + data.reason + "<br>";
            html += "<strong style='color:#ffffaa;'>アドバイス:</strong> " + data.improvement;      
            $("#grade-content").html(html);

            // --- AIチャットへの通知 ---
            if (window.ai_chat_trigger) {
                var msg = "採点結果: " + data.score + "点。\n評価コメント: " + data.reason;
                window.ai_chat_trigger(msg);
            }
            
            // 合否通知
            if(data.score >= 80){
                //alertify.success("合格!");
                TYRANO.kag.ftag.startTag("image", {
                    storage: "clear.svg",
                    layer: "fix",
                    name: "clear_obj",
                    zindex: "20000000",
                    x: "0",
                    y: "0",
                    width: "1280",
                    height: "720",
                    visible: "true"
                });
                setTimeout(function() {
                    TYRANO.kag.ftag.startTag("free", {
                        layer: "fix",
                        name: "clear_obj"
                    });
                }, 1500);
                if (!TYRANO.kag.stat.f.cleared_tasks) TYRANO.kag.stat.f.cleared_tasks = {};
                TYRANO.kag.stat.f.cleared_tasks[TYRANO.kag.stat.f.current_task_id] = true;

                // クリア演出
                
            } else {
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

if (window.ai_chat_save) {
    window.ai_chat_save(function() {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*back"});
    });
} else {
    // 関数がない場合のフォールバック
    tyrano.plugin.kag.ftag.startTag("jump", {target: "*back"});
}
[endscript]
[s]

*back
; 元の画面に戻る
[if exp="f.is_sandbox == true"]
    [jump storage="home.ks" target="*start"]
[else]
    [jump storage="select.ks" target="*start"]
[endif]