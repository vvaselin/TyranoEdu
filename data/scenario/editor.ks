*start
[mask time=1000]
[hidemenubutton]
[clearfix]
@layopt layer="message0" visible=false
[bg storage="standard.png" time="0"]
[stop_keyconfig]

; --- JSファイルの読み込み ---
[loadjs storage="./data/others/js/editor_modal.js"]
[loadjs storage="./data/others/js/editor_task.js"]
[loadjs storage="./data/others/js/editor_grading.js"]

[iscript]
    f.prev_params = {joy:0, trust:0, fear:0, anger:0, shy:0, surprise:0};
    f.prev_output = "";
    if (window.clearMascotChatHistory) {
        window.clearMascotChatHistory();
    }
    if (window.logExperimentEvent) {
        window.logExperimentEvent("screen_transition", {
            screen: "editor",
            action: "enter",
            is_sandbox: !!f.is_sandbox
        });
    }
[endscript]

; AIチャットUIを初期化して表示
[mascot_chat_show]

[show_doc_button file="top.md"]

; ■■■ 初期設定（UIをfixレイヤーに一度だけ配置） ■■■

; --- Monaco Editorを生成し、fixレイヤーに移動 ---
@monaco_show storage="f.my_code"
[iscript]
    console.error(f.current_task_id);
    var editor_wrapper = $("#monaco-iframe").parent();
    var fix_layer = $(".fixlayer").first();
    fix_layer.append(editor_wrapper);
    editor_wrapper.css({ 
        "position": "absolute", 
        "left": "18.5%", 
        "top": "2.5%", 
        "width": "50%", 
        "height": "87%", 
        "z-index": "100" 
    });
    $("#monaco-iframe").css({ "width": "100%", "height": "100%" });
[endscript]

; --- 結果表示用モーダル ---
[iscript]
    window.initResultModal();
[endscript]

; 実行ボタン
[glink name="editor_execute_btn editor_action_btn" fix="true" color="mybtn_01" text="コードを実行" target="*execute_code" width="400" size="20" x="240" y="650"]
; 実行結果モーダル表示ボタン
[glink fix="true" color="mybtn_06" text="コンソール" target="*open_result_window" width="130" height="50"  size="18" x="645" y="650"]
; 採点
[if exp="f.is_sandbox == false"]
    [glink name="editor_submit_btn editor_action_btn" fix="true" color="mybtn_07" text="提出" target="*submit" width="200" size="20" x="15" y="655" ]
[endif]
; 課題選択に戻る
[glink name="back_btn" color="mybtn_09" text="戻る↩" target="*exit_chat" width="200" size="20" x="20" y="10"]

[iscript]
    if (window.setEditorActionBusy) window.setEditorActionBusy(false);
    if (window.setEditorBackBusy) window.setEditorBackBusy(false);
[endscript]

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
        <h3 id="task-title" style="margin-bottom: 10px; font-size: 16px;">課題</h3>
        <p id="task-content" style="white-space: pre-wrap; margin-bottom: 15px; font-size: 14px;"></p>

        <div id="hint-area" style="
            display:none;
            background-color: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            padding: 5px 10px;
            margin-bottom: 15px;
        ">
            <div id="hint-header" style="
                font-size: 12px;
                color: #ffcc00;
                margin-bottom: 8px;
                cursor: pointer;
                user-select: none;
                display: flex;
                align-items: center;
                gap: 6px;
            ">
                <span id="hint-toggle">▶</span>
                <span>💡 ヒント</span>
            </div>
            <div id="hint-content" style="
                display: none;
                font-family: monospace;
                font-size: 14px;
                white-space: pre-wrap;
                color: #ddd;
                line-height: 1.6;
                padding-left: 20px;
            "></div>
        </div>

        <div id="stdin-display-area" style="
            display:none;
            background-color: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 8px;
            padding: 10px;
            margin-bottom: 15px;
        ">
            <div style="font-size:12px; color:#aaa; margin-bottom:5px;">▼ 標準入力 (stdin)</div>
            <div id="stdin-display-text" style="
                font-family: monospace;
                font-size: 14px;
                white-space: pre-wrap;
                color: #87ceeb;
            "></div>
        </div>

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
            <div id="grade-content" style="font-size:14px; line-height:1.4;"></div>
        </div>
    </div>
[endhtml]

; --- 課題データをUIに反映 ---
[iscript]
    window.initTaskDisplay();
[endscript]
[mask_off time=1000]

; すべてのUI配置が終わったので、進行を停止してボタンクリックを待つ、待機状態
[s]

; ■■■ 実行処理（サブルーチン） ■■■
*open_result_window
[iscript]
    window.toggleResultModal();
[endscript]
[return]

*execute_code
[iscript]
    if (f.editor_action_busy) {
        tf.editor_action_skip = true;
    } else {
        tf.editor_action_skip = false;
        if (window.setEditorActionBusy) window.setEditorActionBusy(true);
        window.showExecutionStart();
    }
[endscript]

[if exp="tf.editor_action_skip != true"]
; サーバーにコードを送信 (プラグインが完了するまで待機)
[execute_cpp code=&f.my_code]

; 完了後、結果を表示
[iscript]
    window.showExecutionResult();
[endscript]
[endif]
[eval exp="tf.editor_action_skip=false"]
[return]

*submit
; 採点開始表示
[iscript]
    if (f.editor_action_busy) {
        tf.editor_action_skip = true;
    } else {
        tf.editor_action_skip = false;
        if (window.setEditorActionBusy) window.setEditorActionBusy(true);
        window.showGradingStart();
    }
[endscript]
[if exp="tf.editor_action_skip != true"]
; コード実行
[execute_cpp code=&f.my_code silent="true"]
; 採点処理
[iscript]
    window.submitForGrading();
[endscript]
[endif]
[eval exp="tf.editor_action_skip=false"]
[return]

*show_clear_dialog
[dialog type="alert" text="課題クリア！選択画面に戻ろう" ]
[s]

*exit_chat
[clearfix]
[wait time=500]
[iscript]
    if ($("#result_modal").dialog("isOpen")) $("#result_modal").dialog("close");

    $(".ai-chat-container").css("pointer-events", "none");
    if (window.logExperimentEvent) {
        window.logExperimentEvent("screen_transition", {
            screen: "editor",
            action: "exit",
            is_sandbox: !!f.is_sandbox
        });
    }

    // 保存処理
    if (window.mascot_chat_save) {
        window.mascot_chat_save(function() {
            tyrano.plugin.kag.ftag.startTag("jump", {target: "*back"});
        });
    } else {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*back"});
    }
[endscript]

[s]

*back
; 元の画面に戻る
[if exp="f.is_sandbox == true"]
    [jump storage="home.ks"]
[else]
    [jump storage="select/task.ks"]
[endif]
