console.log("ai_chat.js が読み込まれました！");

(function($) {

    TYRANO.kag.ftag.master_tag.ai_chat_init = {
        
        vital: [],
        
        pm: {
            user_name: "User",
            user_avatar: "./data/fgimage/chat/akane/normal.png", // ユーザーアバター画像
            ai_name: "C++アシスタント",
            ai_avatar: "./data/fgimage/chat/akane/egao.png"      // AIアバター画像
        },
        
        start: function(pm) {
            var kag = TYRANO.kag;

            // --- 1. [html]タグでUIの骨格を生成 ---
            var chat_html = `
                <div class="ai-chat-container">
                    <div class="ai-chat-messages"></div>
                    <div class="ai-chat-form">
                        <input type="text" class="ai-chat-input" placeholder="メッセージを入力...">
                    </div>
                </div>
            `;
            
            // [html]タグを使って、一度前景レイヤーに要素を追加する
            kag.ftag.startTag("html", {
                "html": chat_html
            });
            
            // --- 2. [iscript]を使ってUIをfixレイヤーに移動し、イベントを設定 ---
            kag.ftag.startTag("iscript", {});
            
            // iscript内では'kag'が使えないので'TYRANO.kag'を使う
            var fix_layer = $(".fixlayer").first();
            var chat_container = $(".ai-chat-container");
            
            // 前景レイヤーからfixレイヤーに移動
            fix_layer.append(chat_container);
            
            // CSSで絶対配置にしているので、移動後も表示位置は変わらない
            
            // --- 3. メッセージ追加用の関数を定義 ---
            function addMessage(sender, text, avatar) {
                const messagesContainer = $(".ai-chat-messages");
                // HTMLエンティティをエスケープして安全に表示
                const escapedText = $('<div>').text(text).html();
                const messageHTML = `
                    <div class="ai-chat-message">
                        <img src="${avatar}" class="avatar">
                        <div class="message-content">
                            <span class="username">${sender}</span>
                            <span>${escapedText.replace(/\n/g, '<br>')}</span>
                        </div>
                    </div>
                `;
                messagesContainer.append(messageHTML);
                messagesContainer.scrollTop(messagesContainer[0].scrollHeight);
            }

            // --- 4. サーバー通信とイベントハンドラの設定 ---
            const inputField = $(".ai-chat-input");
            
            // 以前のイベントハンドラが残っている可能性を考慮して一旦offにする
            inputField.off("keydown").on("keydown", function(e) {
                if (e.key === "Enter" && inputField.val().trim() !== "") {
                    const userMessage = inputField.val();
                    
                    addMessage(pm.user_name, userMessage, pm.user_avatar);
                    
                    inputField.val("").prop("disabled", true).attr("placeholder", "AIの応答を待っています...");

                    fetch('http://localhost:8080/api/chat', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ message: userMessage }),
                    })
                    .then(response => response.ok ? response.json() : response.text().then(text => { throw new Error(text) }))
                    .then(data => {
                        addMessage(pm.ai_name, data.text, pm.ai_avatar);
                    })
                    .catch(error => {
                        console.error("AIチャットエラー:", error);
                        addMessage("エラー", "AIとの通信に失敗しました。", pm.ai_avatar);
                    })
                    .finally(() => {
                        inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                    });
                }
            });

            // iscriptの終了と、次のタグへの遷移
            TYRANO.kag.ftag.endTag("iscript");
        }
    };

})(jQuery);