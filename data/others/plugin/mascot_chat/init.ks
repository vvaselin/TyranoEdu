; マスコットチャット プラグイン 本体

; [macro] マスコットチャットUIを表示するマクロ
[macro name="mascot_show"]

    ; 1. 必要なCSS・JSを読み込む
    [loadcss file="./data/others/plugin/mascot_chat/mascot_chat.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    ; 2. [html]タグでUIの骨格を生成する
    [html]
    <div class="ai-chat-container" style="display:none;">
        
        <div class="ai-chat-messages">
            <div class="ai-chat-message">
                <img src="./data/fgimage/chat/akane/egao.png" class="avatar">
                <div class="message-content">
                    <span class="username">あかね</span>
                    <span>何が聞きたいの？</span>
                </div>
            </div>
        </div>
        
        <div class="ai-chat-character">
            <img src="./data/fgimage/chat/akane_f/normal.png" id="ai_chat_character_image">
        </div>

        <div class="ai-chat-form">
            <textarea class="ai-chat-input" placeholder="メッセージを入力..." rows="1"></textarea>
            <button class="ai-chat-send-button">送信</button>
        </div>

    </div>
    [endhtml]

    ; 3. [iscript]でUIをfixレイヤーに移動し、イベントを設定する
    ; (グローバルオブジェクトを使わず、全てこの [iscript] 内で完結させる)
    [iscript]
        // --- UI要素をfixレイヤーに移動 ---
        var $chat_container = $(".ai-chat-container");
        var fix_layer = TYRANO.kag.layer.getLayer("fix");
        fix_layer.append($chat_container);

        // ★ スタイルを調整して表示 (FLEXコンテナ化)
        $chat_container.css({
            "position": "absolute",
            "right": "10px",
            "top": "15px",
            "width": "30%", 
            "height": "calc(100% - 30px)",
            "z-index": "100",
            "display": "flex",        // ★ flex を有効に
            "flex-direction": "column" // ★ 縦積みに変更
        });

        // --- UI要素を取得 ---
        var messagesContainer = $chat_container.find(".ai-chat-messages");
        var inputField = $chat_container.find(".ai-chat-input");
        var sendButton = $chat_container.find(".ai-chat-send-button");
        var $char_image = $("#ai_chat_character_image"); // ★ 立ち絵用の要素を取得

        // --- メッセージ追加関数 (ローカル関数) ---
        function addMessage(username, text, avatar) {
            // marked.js と DOMPurify (流用)
            var unsafe_html = marked.parse(text);
            var safe_html = DOMPurify.sanitize(unsafe_html);

            var messageHtml = `
                <div class="ai-chat-message">
                    <img src="${avatar}" class="avatar">
                    <div class="message-content">
                        <span class="username">${username}</span>
                        <div>${safe_html}</div>
                    </div>
                </div>
            `;
            messagesContainer.append(messageHtml);
            messagesContainer.scrollTop(messagesContainer.prop("scrollHeight"));

            // --- ★ 立ち絵を変更する処理を追加 ---
            if (username !== "ユーザー" && avatar) {
                 var char_path = "./data/fgimage/chat/akane_f/normal.png"; // デフォルト
                 if (avatar.includes("hirameki") || avatar.includes("egao")) {
                     char_path = "./data/fgimage/chat/akane_f/happy.png";
                 } else if (avatar.includes("naki")) {
                     char_path = "./data/fgimage/chat/akane_f/normal.png"; 
                 }
                 $char_image.attr("src", char_path);
            } else if (username === "ユーザー") {
                $char_image.attr("src", "./data/fgimage/chat/akane_f/normal.png");
            }
            // --- ★ 立ち絵変更ここまで ---

            // コードブロックにコピーボタンを追加 (流用)
            $(messagesContainer).find("pre").each(function() {
                if ($(this).find(".copy-code-button").length === 0) {
                    var $button = $('<button class="copy-code-button">コピー</button>');
                    $(this).append($button);
                    $button.on("click", function() {
                        var code = $(this).siblings("code").text();
                        navigator.clipboard.writeText(code);
                        $(this).text("コピー完了!");
                        setTimeout(() => $(this).text("コピー"), 2000);
                    });
                }
            });
        }
        
        // --- 送信処理 (ローカル関数) ---
        // (ご提示いただいた init.ks の sendMessage 関数をそのまま流用)
        function sendMessage() {
            var userMessage = inputField.val().trim();
            if (userMessage === "") return;

            addMessage("ユーザー", userMessage, "./data/fgimage/chat/akane/normal.png"); 
            
            inputField.val("").prop("disabled", true).attr("placeholder", "AIの応答を待っています...").css("height", "auto");
            sendButton.prop("disabled", true);

            // 1. Monaco Editor からコードを取得
            var CodeContent = TYRANO.kag.stat.tf.current_code || "（コードなし）";
            
            // 2. 課題内容を取得
            var tasks = TYRANO.kag.stat.f.all_tasks;
            var current_id = TYRANO.kag.stat.f.current_task_id;
            var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
            var task_description = task_data ? task_data.description : "（課題なし）";

            // 3. サーバーに送信 (fetch)
            fetch('/api/chat', { // 相対パス
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    message: userMessage,
                    code: CodeContent,
                    task: task_description,
                }),
            })
            .then(response => response.ok ? response.json() : response.text().then(text => { throw new Error(text) }))
            .then(data => {
                // 4. 成功時: 応答を addMessage で表示
                addMessage("あかね", data.text, "./data/fgimage/chat/akane/hirameki.png");
            })
            .catch(error => {
                console.error("AIチャットエラー:", error);
                // 5. 失敗時: エラーを addMessage で表示
                addMessage("エラー", "AIとの通信に失敗しました。\n" + error.message, "./data/fgimage/chat/akane/naki.png");
            })
            .finally(() => {
                // 6. 完了時: UIを元に戻す
                inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                sendButton.prop("disabled", false);
            });
        }

        // --- イベントリスナー (ローカル関数を紐付け) ---
        sendButton.on("click", sendMessage); 
        inputField.on("keydown", function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault(); 
                sendMessage();
            }
        });

        // (textarea の自動リサイズ ... 流用)
        inputField.on('input', function() {
            this.style.height = 'auto';
            this.style.height = (this.scrollHeight) + 'px';
        });

    [endscript]
[endmacro]