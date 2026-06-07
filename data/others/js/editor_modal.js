// editor_modal.js
// コンソールモーダルの生成・開閉・実行結果の表示

/**
 * コンソールモーダルを初期化して fixレイヤーに配置する
 */
window.initResultModal = function() {
    var f = TYRANO.kag.stat.f;
    var fix_layer = $(".fixlayer").first();

    // 明示的にCSSを読み込む
    tyrano.plugin.kag.ftag.startTag("loadcss", {file: "./data/others/css/modal_dark_theme.css"});

    // 二重生成防止
    $("#result_modal").remove();

    var modal_html = 
        '<div id="result_modal" title="コンソール">' +
        '    <pre id="result_modal_content">実行ボタンを押してね</pre>' +
        '</div>';

    var $modal = $(modal_html);
    fix_layer.append($modal);

    // jQuery UI Dialog として初期化
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
        classes: { "ui-dialog": "dialog-dark" },
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
                        function() {
                            $button.text("コピー完了!");
                            setTimeout(function() { $button.text("コピー"); }, 2000);
                        },
                        function() {
                            $button.text("失敗");
                            setTimeout(function() { $button.text("コピー"); }, 2000);
                        }
                    );
                }
            }
        ],
        open: function(event, ui) {
            $(this).css('font-size', '14px');
            $(this).parent().css('z-index', '10002');
        },
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
};

window.setEditorActionBusy = function(isBusy) {
    TYRANO.kag.stat.f.editor_action_busy = !!isBusy;
    var $buttons = $(".editor_action_btn,[data-event-pm*='editor_execute_btn'],[data-event-pm*='editor_submit_btn']");
    $buttons.css({
        "opacity": isBusy ? "0.45" : "1",
        "pointer-events": isBusy ? "none" : "auto"
    });
};

window.setEditorBackBusy = function(isBusy) {
    var $button = $(".back_btn,[data-event-pm*='back_btn']");
    $button.css({
        "opacity": isBusy ? "0.45" : "1",
        "pointer-events": isBusy ? "none" : "auto"
    });
};

/**
 * コンソールモーダルの開閉トグル
 */
window.toggleResultModal = function() {
    var $dialog = $("#result_modal");
    if (!$dialog.dialog("isOpen")) {
        $dialog.dialog("open");
    } else {
        $dialog.dialog("close");
    }
};

/**
 * コード実行開始時のUI更新（「実行中...」表示）
 */
window.showExecutionStart = function() {
    var f = TYRANO.kag.stat.f;
    var $dialog = $("#result_modal");
    
    $("#modal_copy_button_id").button("disable");
    $("#result_modal_content").text("実行中...");
    
    if (!$dialog.dialog("isOpen")) {
        $dialog.dialog("open");
    }
    
    f.starttime = performance.now();
};

/**
 * コード実行完了後のUI更新（結果表示）
 */
window.showExecutionResult = function() {
    var f = TYRANO.kag.stat.f;
    var result_text = f.execution_result || "（何も出力されなかったよ）";
    
    $("#result_modal_content").text(result_text);
    $("#modal_copy_button_id").button("enable");
    if (window.setEditorActionBusy) {
        window.setEditorActionBusy(false);
    }
    
    console.error("実行時間：", (performance.now() - f.starttime), "ms");
};
