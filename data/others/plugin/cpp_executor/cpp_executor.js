(function($) {
    // 新しいカスタムタグ [execute_cpp] を定義
    TYRANO.kag.ftag.master_tag.execute_cpp = {
        
        vital: ["code"], // 必須パラメータ
        
        pm: {
            code: "",         // 実行するC++コード（文字列）
            url: "/api/execute",   // GoサーバーのAPIエンドポイント
            silent: "false" // デフォルトは喋る
        },
        
        start: function(pm) {
            
            const f = TYRANO.kag.stat.f; // ティラノスクリプトの変数 (f)
            
            // codeパラメータが変数の場合は、その値を取得
            let code_to_execute = "";
            if (pm.code.startsWith("&")) {
                code_to_execute = TYRANO.kag.emb(pm.code);
            } else {
                code_to_execute = pm.code;
            }

            let input_stdin = "";
            if (f.all_tasks && f.current_task_id) {
                const current_task = f.all_tasks[f.current_task_id];
                // タスクデータがあり、stdinが定義されていれば使用する
                if (current_task && current_task.stdin) {
                    input_stdin = current_task.stdin;
                }
            }
            
            // 先に結果変数をクリアしておく
            f.execution_result = "";
            
            // GoサーバーのAPIを叩く
            fetch(pm.url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    code: code_to_execute, 
                    stdin: input_stdin
                }),
            })
            .then(response => {
                if (!response.ok) {
                    return response.text().then(text => { 
                        throw new Error(text || 'サーバーエラー'); 
                    });
                }
                return response.json();
            })
            .then(data => {
                // 成功した結果を変数に格納
                f.execution_result = data.result;

                if (pm.silent !== "true") {
                    var shortResult = data.result.substring(0, 100); 
                    if(window.mascot_chat_trigger){
                        window.mascot_chat_trigger("ユーザーがコードを実行しました。実行結果: " + shortResult, false);
                    }else{
                        window.ai_chat_trigger("ユーザーがコードを実行しました。実行結果: " + shortResult);
                    }
                }
                TYRANO.kag.stat.f.prev_output = data.result;
            })
            .catch(error => {
                // 失敗した結果を変数に格納
                f.execution_result = "エラー:\n" + error.message;

                if (pm.silent !== "true") {
                    if(window.mascot_chat_trigger){
                        window.mascot_chat_trigger("コード実行時にエラーが発生しました: " + error.message, false);
                    }
                    else{
                        window.ai_chat_trigger("コード実行時にエラーが発生しました: " + error.message);
                    }
                }
                TYRANO.kag.stat.f.prev_output = "エラー:\n" + error.message;
            })
            .finally(() => {
                // API通信が完了したら、ティラノスクリプトの次のタグに進ませる
                TYRANO.kag.ftag.nextOrder();
            });
            
            // nextOrder()は .finally() で呼ばれるため、ここでは何もしない
        }
    };
})(jQuery);