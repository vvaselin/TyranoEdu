// editor_grading.js
// 採点処理・クリア演出・ハイスコアボーナス

/**
 * 採点開始時のUI更新（「採点中...」表示、戻るボタン非表示）
 * [execute_cpp] の前に呼び出すこと
 */
window.showGradingStart = function() {
    if (window.setEditorBackBusy) {
        window.setEditorBackBusy(true);
    }
    $("#grade-result-area").show();
    $("#grade-content").html("<span style='color:gray;'>採点中...</span>");
};

/**
 * 採点リクエストを送信し、結果を表示する
 * [execute_cpp] 完了後に呼び出すこと
 */
window.submitForGrading = function() {
    var f = TYRANO.kag.stat.f;

    // 課題データ
    var task = f.all_tasks[f.current_task_id];
    var payload = {
        user_id: f.user_id,
        task_id: f.current_task_id,
        code: f['my_code'],
        output: f.execution_result,
        task_desc: task.description,
        expected_output: task.expected_output || ""
    };
    if (window.logExperimentEvent) {
        window.logExperimentEvent("grade_start", payload);
    }

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
            if (window.logExperimentEvent) {
                window.logExperimentEvent("grade_result", {
                    score: data.score,
                    reason: data.reason,
                    improvement: data.improvement,
                    bonus_love: data.bonus_love,
                    is_new_record: data.is_new_record
                });
            }
            
            // 採点結果をキャラに話させる
            if (window.mascot_chat_trigger) {
                var msg = "[SYSTEM] 採点結果: " + data.score + "点。\n評価コメント: " + data.reason;
                
                window.mascot_chat_trigger(msg, false, function() {
                    handleGradeResult(data);
                    if (window.setEditorBackBusy) {
                        window.setEditorBackBusy(false);
                    }
                    if (window.setEditorActionBusy) {
                        window.setEditorActionBusy(false);
                    }
                });
            } else {
                if (window.setEditorBackBusy) {
                    window.setEditorBackBusy(false);
                }
                if (window.setEditorActionBusy) {
                    window.setEditorActionBusy(false);
                }
            }
        },
        error: function() {
            $("#grade-content").text("採点サーバーとの通信に失敗しました。");
            if (window.logExperimentEvent) {
                window.logExperimentEvent("grade_result", {
                    error: true,
                    message: "採点サーバーとの通信に失敗しました。"
                });
            }
            if (window.setEditorBackBusy) {
                window.setEditorBackBusy(false);
            }
            if (window.setEditorActionBusy) {
                window.setEditorActionBusy(false);
            }
        }
    });
};

/**
 * 採点結果に基づくクリア演出・ボーナス処理
 * @param {Object} data - サーバーからの採点レスポンス
 */
function handleGradeResult(data) {
    var f = TYRANO.kag.stat.f;

    if (data.score >= 80) {
        // クリア演出
        TYRANO.kag.ftag.startTag("image", {
            storage: "clear.svg",
            layer: "fix",
            name: "clear_obj",
            zindex: "20000000",
            x: "0", y: "0",
            width: "1280", height: "720",
            visible: "true"
        });
        setTimeout(function() {
            TYRANO.kag.ftag.startTag("free", {
                layer: "fix",
                name: "clear_obj"
            });
        }, 2000);

        if (!f.cleared_tasks) {
            f.cleared_tasks = {};
        }
        f.cleared_tasks[f.current_task_id] = true;
    } else {
        alertify.error("不合格...");
    }

    // ハイスコアボーナス
    if (data.is_new_record) {
        if (f.user_role == 'experimental' && data.bonus_love > 0) {
            var current = parseInt(f.love_level) || 0;
            f.love_level = current + data.bonus_love;
            if (window.logExperimentEvent) {
                window.logExperimentEvent("love_change", {
                    source: "high_score_bonus",
                    delta: data.bonus_love,
                    before: current,
                    after: f.love_level,
                    score: data.score,
                    is_new_record: data.is_new_record
                });
            }
            alertify.success("ハイスコアボーナス! 好感度+" + data.bonus_love);
            if (window.saveLoveLevelToSupabase) {
                window.saveLoveLevelToSupabase(f.love_level);
            }
        }
    }

    // クリア済みなら遷移ダイアログ
    if (f.cleared_tasks[f.current_task_id] === true) {
        setTimeout(function() {
            TYRANO.kag.ftag.startTag("jump", {target: "*show_clear_dialog"});
        }, 2500);
    }
}
