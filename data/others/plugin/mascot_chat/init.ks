; マスコットチャット プラグイン 本体

; [macro] マスコットチャットUIを表示するマクロ
[macro name="mascot_show"]

    ; 1. 必要なCSS・JSを読み込む
    [loadcss file="./data/others/plugin/mascot_chat/mascot_chat.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    ; 2. [html]タグでUIの骨格を生成する
    [html]
    <div class="mascot-chat-container" style="display:none;">
        
        <div class="mascot-bubble-area">
            
            <div class="mascot-nav">
                <button class="mascot-nav-button" id="mascot_prev" disabled>◀</button>
                <button class="mascot-nav-button" id="mascot_next" disabled>▶</button>
            </div>

            <div class="mascot-bubble">
                <div class="mascot-message-content">
                    何が聞きたいの？
                </div>
            </div>
        </div>
        
        <div class="mascot-character">
            <img src="./data/fgimage/chat/akane_f/normal.png" id="mascot_character_image">
        </div>

        <div class="mascot-chat-form">
            <textarea class="ai-chat-input" placeholder="メッセージを入力..." rows="1"></textarea>
            <button class="ai-chat-send-button">送信</button>
        </div>

    </div>
    [endhtml]

    ; 3. [iscript]でUIをfixレイヤーに移動し、イベントを設定する
    ; (ai_chat のロジックをそのまま流用)
    [iscript]
        // --- UI要素をfixレイヤーに移動 ---
        var $chat_container = $(".mascot-chat-container");
        var fix_layer = TYRANO.kag.layer.getLayer("fix");
        fix_layer.append($chat_container);

        // ★ スタイルを適用 (FLEXコンテナ化)
        $chat_container.css({
            "position": "absolute",
            "right": "10px",
            "top": "15px",
            "width": "30%", 
            "height": "calc(100% - 30px)",
            "z-index": "100",
            "display": "flex",
            "flex-direction": "column"
        });

        // --- UI要素を取得 (★ ai_chat と同じ変数名を使用) ---
        var inputField = $chat_container.find(".ai-chat-input");
        var sendButton = $chat_container.find(".ai-chat-send-button");
        
        // --- ★ マスコット用の追加UI要素 ---
        var $char_image = $("#mascot_character_image");
        var $bubbleContent = $chat_container.find(".mascot-message-content");
        var $prevButton = $("#mascot_prev"); // ★ $ を付けてjQueryオブジェクトとして宣言
        var $nextButton = $("#mascot_next"); // ★ $ を付けてjQueryオブジェクトとして宣言

        // --- ★ 会話履歴を管理する配列 ★ ---
        var messageHistory = [];
        var currentIndex = -1;

        // --- ★ 履歴を描画する関数 (新規) ★ ---
        function renderCurrentMessage() {
            if (currentIndex < 0 || currentIndex >= messageHistory.length) return;
            
            var msg = messageHistory[currentIndex];
            
            // 1. 吹き出しの中身を上書き
            var unsafe_html = marked.parse(msg.text);
            var safe_html = DOMPurify.sanitize(unsafe_html);
            $bubbleContent.html(safe_html);

            // 2. コードブロックにコピーボタンを追加 (ai_chatから流用)
            $bubbleContent.find("pre").each(function() {
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

            // 3. 立ち絵を変更
            if (msg.username !== "ユーザー" && msg.avatar) {
                 var char_path = "./data/fgimage/chat/akane_f/normal.png"; 
                 if (msg.avatar.includes("hirameki") || msg.avatar.includes("egao")) {
                     char_path = "./data/fgimage/chat/akane_f/happy.png";
                 } else if (msg.avatar.includes("naki")) {
                     char_path = "./data/fgimage/chat/akane_f/normal.png"; 
                 }
                 $char_image.attr("src", char_path);
            } else if (msg.username === "ユーザー") {
                $char_image.attr("src", "./data/fgimage/chat/akane_f/normal.png");
            }
            
            // 4. ナビゲーションボタンの状態を更新
            $prevButton.prop("disabled", currentIndex === 0);
            $nextButton.prop("disabled", currentIndex === messageHistory.length - 1);
        }

        // --- ★ メッセージ追加関数 (改造) ★ ---
        // (addMessage は「履歴に追加して描画」の役割)
        function addMessage(username, text, avatar) {
            messageHistory.push({ username, text, avatar });
            currentIndex = messageHistory.length - 1;
            renderCurrentMessage();
        }
        
        // --- ★★★ 送信処理 (init(ai_chat).ks のロジックをそのまま流用) ★★★ ---
        function sendMessage() {
            var userMessage = inputField.val().trim();
            if (userMessage === "") return;

            addMessage("ユーザー", userMessage, "./data/fgimage/chat/akane/normal.png"); 
            
            inputField.val("").prop("disabled", true).attr("placeholder", "AIの応答を待っています...").css("height", "auto");
            sendButton.prop("disabled", true);
            $prevButton.prop("disabled", true);
            $nextButton.prop("disabled", true);

            // 2. Monaco Editor のコードを「直接」参照 (ai_chat と同じ)
            var CodeContent = TYRANO.kag.stat.tf.current_code || "（コードなし）";
            
            // 3. 課題内容を「直接」参照 (ai_chat と同じ)
            var tasks = TYRANO.kag.stat.f.all_tasks;
            var current_id = TYRANO.kag.stat.f.current_task_id;
            var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
            var task_description = task_data ? task_data.description : "（課題なし）";

            // 4. サーバーに送信 (fetch) (ai_chat と同じ)
            fetch('/api/chat', { 
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
                addMessage("あかね", data.text, "./data/fgimage/chat/akane/hirameki.png");
            })
            .catch(error => {
                console.error("AIチャットエラー:", error);
                addMessage("エラー", "AIとの通信に失敗しました。\n" + error.message, "./data/fgimage/chat/akane/naki.png");
            })
            .finally(() => {
                inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                sendButton.prop("disabled", false);
                renderCurrentMessage(); // ナビボタンの状態も更新
            });
        }
        // ★★★ 送信処理ここまで ★★★

        // --- イベントリスナー (★ 変数名を ai_chat と合わせる) ---
        sendButton.on("click", sendMessage); 
        inputField.on("keydown", function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault(); 
                sendMessage();
            }
        });
        inputField.on('input', function() {
            this.style.height = 'auto'; 
            this.style.height = (this.scrollHeight) + 'px';
        });
        
        // ★ ナビゲーションボタンのイベント (★ $ を付けた変数で呼び出す) ★
        $prevButton.on("click", function() {
            if (currentIndex > 0) {
                currentIndex--;
                renderCurrentMessage();
            }
        });
        $nextButton.on("click", function() {
            if (currentIndex < messageHistory.length - 1) {
                currentIndex++;
                renderCurrentMessage();
            }
        });
        
        // --- ★ 初期メッセージを履歴に追加 ★ ---
        addMessage("あかね", "何が聞きたいの？", "./data/fgimage/chat/akane/egao.png");

    [endscript]
[endmacro]