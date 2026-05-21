// editor_task.js
// 課題表示・ヒント折り畳み・標準入力・期待出力の管理

/**
 * 課題ボックスの内容を初期化する
 * f.all_tasks と f.current_task_id を参照してUIに反映
 */
window.initTaskDisplay = function() {
    var f = TYRANO.kag.stat.f;
    var tasks = f.all_tasks;
    var current_id = f.current_task_id;

    var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;

    if (task_data) {
        // 成功: データをUIにセット
        $("#task-title").text(task_data.title);
        $("#task-content").text(task_data.description);

        if (f.is_sandbox) {
            $("#expected-output-area").hide();
            $("#custom-stdin-area").show();

            // 入力欄の内容を tasks["sandbox"].stdin に反映させる
            $("#custom-stdin-text").on("input", function() {
                tasks["sandbox"].stdin = $(this).val();
            });
            
            // 初期値をセット
            $("#custom-stdin-text").val(task_data.stdin || "");
        } else {
            // 通常の課題モード
            $("#custom-stdin-area").hide();
            
            // 期待される出力
            if (task_data.expected_output && task_data.expected_output !== "") {
                $("#expected-output-area").show();
                $("#expected-output-text").text(task_data.expected_output);
            } else {
                $("#expected-output-area").hide();
            }
            
            // 標準入力の表示
            if (task_data.stdin && task_data.stdin !== "") {
                $("#stdin-display-area").show();
                $("#stdin-display-text").text(task_data.stdin);
            } else {
                $("#stdin-display-area").hide();
            }
            
            // ヒント表示
            if (task_data.hints && task_data.hints.length > 0) {
                $("#hint-area").show();
                $("#hint-content").text(task_data.hints.join("\n"));
            } else {
                $("#hint-area").hide();
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

    // ヒントの折り畳み機能（イベントハンドラ）
    $("#hint-header").off("click").on("click", function() {
        var content = $("#hint-content");
        var toggle = $("#hint-toggle");
        
        if (content.is(":visible")) {
            content.slideUp(200);
            toggle.text("▶");
        } else {
            content.slideDown(200);
            toggle.text("▼");
        }
    });
};