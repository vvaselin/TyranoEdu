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
            if (window.logExperimentEvent) {
                window.logExperimentEvent("execute_start", {
                    silent: pm.silent === "true",
                    code: code_to_execute,
                    stdin: input_stdin
                });
            }
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
                if (window.logExperimentEvent) {
                    window.logExperimentEvent("execute_result", {
                        silent: pm.silent === "true",
                        result: data.result,
                        is_error: data.result.startsWith("エラー:\n")
                    });
                }

                const isError = data.result.startsWith("エラー:\n");
                console.log('[cpp_executor] data.result:', data.result.substring(0, 200));
                console.log('[cpp_executor] isError:', isError);

                // Monacoにマーカーを送る（エラーならパース、成功ならクリア）
                sendMonacoMarkers(isError ? data.result : null);

                if (!isError && pm.silent !== "true") {
                    var shortResult = data.result.substring(0, 100); 
                    if(window.mascot_chat_trigger){
                        window.mascot_chat_trigger("ユーザーがコードを実行しました。実行結果: " + shortResult, false);
                    }
                }
                if (isError && pm.silent !== "true") {
                    if(window.mascot_chat_trigger){
                        window.mascot_chat_trigger("コード実行時にエラーが発生しました: " + data.result.substring(0, 100), false);
                    }
                }
                TYRANO.kag.stat.f.prev_output = data.result;
            })
            .catch(error => {
                // 通信エラー（fetch自体の失敗）
                f.execution_result = "エラー:\n" + error.message;
                if (window.logExperimentEvent) {
                    window.logExperimentEvent("execute_result", {
                        silent: pm.silent === "true",
                        result: f.execution_result,
                        is_error: true,
                        error_message: error.message
                    });
                }
                sendMonacoMarkers(null); // 通信エラーはマーカー出せないのでクリアだけ

                if (pm.silent !== "true") {
                    if(window.mascot_chat_trigger){
                        window.mascot_chat_trigger("コード実行時にエラーが発生しました: " + error.message, false);
                    }
                }
                f.prev_output = "エラー:\n" + error.message;
            })
            .finally(() => {
                // API通信が完了したら、ティラノスクリプトの次のタグに進ませる
                TYRANO.kag.ftag.nextOrder();
            });
            
            // nextOrder()は .finally() で呼ばれるため、ここでは何もしない
        }
    };
})(jQuery);

/**
 * g++のエラー文字列をパースしてMonaco Editorにマーカーを送る
 * @param {string|null} resultText - "エラー:\n..." の文字列。nullなら全クリア
 */
function sendMonacoMarkers(resultText) {
    const iframe = document.getElementById('monaco-iframe');
    console.log('[sendMonacoMarkers] iframe found:', !!iframe);
    console.log('[sendMonacoMarkers] resultText:', resultText ? resultText.substring(0, 200) : null);

    if (!iframe || !iframe.contentWindow) return;

    // エラーなし or 通信エラー → マーカーをクリアして終了
    if (!resultText) {
        iframe.contentWindow.postMessage({ command: 'set_markers', data: { markers: [] } }, '*');
        return;
    }

    // g++ のエラー行フォーマット:
    //   /usr/src/app/main.cpp:LINE:COL: error: MESSAGE
    //   /usr/src/app/main.cpp:LINE:COL: warning: MESSAGE
    //   fatal error も対応
    const regex = /main\.cpp:(\d+):(\d+):\s+(?:fatal )?(error|warning):\s+(.+)/g;
    const markers = [];
    let match;

    while ((match = regex.exec(resultText)) !== null) {
        const line = parseInt(match[1], 10);
        const col  = parseInt(match[2], 10);
        markers.push({
            startLineNumber: line,
            startColumn:     1,        // 行頭から
            endLineNumber:   line,
            endColumn:       1000,     // 行末まで（Monacoが自動でクランプ）
            message:         match[4].trim(),
            severity:        match[3], // 'error' or 'warning'
        });
    }

    console.log('[sendMonacoMarkers] parsed markers:', JSON.stringify(markers));
    iframe.contentWindow.postMessage({ command: 'set_markers', data: { markers } }, '*');
}
