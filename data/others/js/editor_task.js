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

window.buildEditorTaskContext = function(taskData) {
    if (!taskData) return "タスクがありません";

    var lines = [];
    if (taskData.title) lines.push("[Title]\n" + taskData.title);
    if (taskData.description) lines.push("[Description]\n" + taskData.description);
    if (taskData.stdin) lines.push("[Fixed stdin]\n" + taskData.stdin);
    if (taskData.expected_output) lines.push("[Expected Output]\n" + taskData.expected_output);
    if (taskData.hints && taskData.hints.length > 0) {
        lines.push("[Hints]\n" + taskData.hints.join("\n"));
    }
    return lines.join("\n\n");
};

window.triggerMascotTaskIntro = function() {
    if (typeof TYRANO === "undefined" || !TYRANO.kag || !TYRANO.kag.stat) return;

    var f = TYRANO.kag.stat.f || {};
    if (f.is_sandbox) return;

    var tasks = f.all_tasks;
    var currentId = f.current_task_id;
    var taskData = (tasks && currentId && tasks[currentId]) ? tasks[currentId] : null;
    if (!taskData || !currentId) return;

    if (!f._mascot_intro_task_ids) {
        f._mascot_intro_task_ids = {};
    }
    if (f._mascot_intro_task_ids[currentId]) return;

    var attempts = 0;
    var maxAttempts = 10;
    var retryMs = 300;

    function tryTrigger() {
        attempts++;
        if (typeof window.mascot_chat_trigger !== "function") {
            if (attempts < maxAttempts) {
                setTimeout(tryTrigger, retryMs);
            } else {
                console.warn("[EditorTask] mascot_chat_trigger is not ready.");
            }
            return;
        }

        f._mascot_intro_task_ids[currentId] = true;

        var learnedTopics = [];
        if (f.ai_memory && Array.isArray(f.ai_memory.learned_topics)) {
            learnedTopics = f.ai_memory.learned_topics;
        }

        var stdinNote = "";
        if (taskData.stdin && taskData.stdin !== "") {
            stdinNote = "\n- このシステムでは cin で入る入力内容は課題側で固定されています。今回の固定stdin: " + taskData.stdin;
        }

        var systemMessage =
            "課題に取り組み始めた直後の自動説明です。\n" +
            "現在の課題に必要なC++の書き方を、正解コード全文なしで2〜3個だけ簡潔に教えてください。\n" +
            "- 例: `cout << \"こんにちは\" << endl;` で文字を出力できる、`cin >> a;` でaに入力できる、`for (int i = 0; i < 5; i++)`で繰り返せる、のような短い構文説明にしてください。\n" +
            "- 課題の答えそのもの、完成コード、複数行の解答コードは出さないでください。" +
            stdinNote + "\n" +
            "- learned_topicsにある内容と重なる説明は、可能なら省いてください。\n\n" +
            "[learned_topics]\n" + (learnedTopics.length ? learnedTopics.join(", ") : "なし") + "\n\n" +
            "[Task Context]\n" + window.buildEditorTaskContext(taskData);

        window.mascot_chat_trigger(systemMessage, false, function(err, data, requestId) {
            if (!window.logExperimentEvent) return;

            var eventData = {
                request_id: requestId || "",
                task_id: currentId,
                task_title: taskData.title || "",
                learned_topics: learnedTopics,
                fixed_stdin: taskData.stdin || "",
                system_message: systemMessage,
                ai_text: data && data.text ? data.text : "",
                emotion: data && data.emotion ? data.emotion : ""
            };

            if (err) {
                eventData.error = true;
                eventData.error_message = err.message || String(err);
            }

            window.logExperimentEvent("task_intro_knowledge", eventData);
        });
    }

    tryTrigger();
};
