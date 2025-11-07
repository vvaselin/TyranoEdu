(function($) {
    // 新しいカスタムタグ [execute_cpp] を定義
    TYRANO.kag.ftag.master_tag.execute_cpp = {
        
        vital: ["code"], // 必須パラメータ
        
        pm: {
            code: "",         // 実行するC++コード（文字列）
            url: "/execute"   // GoサーバーのAPIエンドポイント
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
            
            // 先に結果変数をクリアしておく
            f.execution_result = "";
            
            // GoサーバーのAPIを叩く
            fetch(pm.url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ code: code_to_execute }),
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
            })
            .catch(error => {
                // 失敗した結果を変数に格納
                f.execution_result = "エラー:\n" + error.message;
            })
            .finally(() => {
                // API通信が完了したら、ティラノスクリプトの次のタグに進ませる
                TYRANO.kag.ftag.nextOrder();
            });
            
            // nextOrder()は .finally() で呼ばれるため、ここでは何もしない
        }
    };
})(jQuery);