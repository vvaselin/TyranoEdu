; AIチャットプラグイン 本体

; [macro] AIチャットUIを表示するマクロ
[macro name="ai_chat_show"]

    ; 1. 必要なCSSを読み込む
    [loadcss file="./data/others/plugin/ai_chat/ai_chat.css"]

    ; 2. [html]タグでUIの骨格を生成する
    ; この時点では通常レイヤーに一時的に配置される
    [html]
    <div class="ai-chat-container" style="display:none;">
        <div class="ai-chat-messages">
            <div class="ai-chat-message">
                <img src="./data/fgimage/chat/akane/egao.png" class="avatar">
                <div class="message-content">
                    <span class="username">C++アシスタント</span>
                    <span>こんにちは！ 何かお手伝いできることはありますか？</span>
                </div>
            </div>
        </div>
        <div class="ai-chat-form">
            <input type="text" class="ai-chat-input" placeholder="メッセージを入力...">
            <button class="ai-chat-send-button">送信</button>
        </div>
    </div>
    [endhtml]

    ; 3. [iscript]でUIをfixレイヤーに移動し、イベントを設定する
    [iscript]
        var chat_container = $(".ai-chat-container");
        var fix_layer = $(".fixlayer").first();
        fix_layer.append(chat_container); 

        // JavaScriptでUIの位置とサイズを「ピクセル単位」で明示的に設定する

        const scWidth = parseInt(TYRANO.kag.config.scWidth);
        const scHeight = parseInt(TYRANO.kag.config.scHeight); 

        const chatWidth = scWidth * 0.45;
        const marginRight = scWidth * 0.01;
        const leftPosition = scWidth - chatWidth - marginRight;
        
        const chatHeight = scHeight * 0.96; 

        chat_container.css({
            "position": "absolute",
            "top": "2%",
            "left": leftPosition + "px",
            "width": chatWidth + "px",
            "height": chatHeight + "px", // ← ★★★ 3. "96%" から `chatHeight + "px"` に修正 ★★★
            "z-index": "200"
        });

        const formHeight = 75;
        const messagesHeight = chatHeight - formHeight;

        const messagesArea = $(".ai-chat-messages");
        const formArea = $(".ai-chat-form");
        
        messagesArea.css("height", messagesHeight + "px");
        formArea.css("height", formHeight + "px");

        chat_container.show();

        const inputField = $(".ai-chat-input");
        const sendButton = $(".ai-chat-send-button"); // ボタン要素を取得
        const messagesContainer = $(".ai-chat-messages");
        
        // (addMessage関数は変更なし)
        function addMessage(sender, text, avatar) {
            const escapedText = $('<div>').text(text).html().replace(/\n/g, '<br>');
            const messageHTML = `
                <div class="ai-chat-message">
                    <img src="${avatar}" class="avatar">
                    <div class="message-content">
                        <span class="username">${sender}</span>
                        <span>${escapedText}</span>
                    </div>
                </div>`;
            messagesContainer.append(messageHTML);
            messagesContainer.scrollTop(messagesContainer[0].scrollHeight);
        }

        // メッセージ送信処理を関数にまとめる
        function sendMessage() {
            const userMessage = inputField.val().trim();
            if (userMessage === "") {
                return; // 空の場合は何もしない
            }

            // ユーザーのメッセージを表示
            addMessage("あなた", userMessage, "./data/fgimage/chat/akane/normal.png");
            inputField.val("");
            inputField.prop("disabled", true).attr("placeholder", "AIの応答を待っています...");
            sendButton.prop("disabled", true);

            // AIサーバーとの通信処理
            fetch('http://localhost:8080/api/chat', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: userMessage }),
            })
            .then(response => response.ok ? response.json() : response.text().then(text => { throw new Error(text) }))
            .then(data => {
                addMessage("C++アシスタント", data.text, "./data/fgimage/chat/akane/hirameki.png");
            })
            .catch(error => {
                console.error("AIチャットエラー:", error);
                addMessage("エラー", "AIとの通信に失敗しました。", "./data/fgimage/chat/akane/naki.png");
            })
            .finally(() => {
                // 入力欄とボタンを元に戻す
                inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                sendButton.prop("disabled", false);
            });
        }

        // イベントリスナーを設定
        sendButton.on("click", sendMessage); // ボタンクリックで送信
        inputField.on("keydown", function(e) {
            if (e.key === "Enter") {
                sendMessage(); // Enterキーで送信
            }
        });

    [endscript]

[endmacro]

[return]