; AIチャットプラグイン 本体

; [macro] AIチャットUIを表示するマクロ
[macro name="ai_chat_show"]

    ; 1. 必要なCSSを読み込む
    [loadcss file="./data/others/plugin/ai_chat/ai_chat.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    ; 2. [html]タグでUIの骨格を生成する
    ; この時点では通常レイヤーに一時的に配置される
    [html]
    <div class="ai-chat-container" style="display:none;">
        <div class="ai-chat-messages">
            <div class="ai-chat-message">
                <img src="./data/fgimage/chat/akane/egao.png" class="avatar">
                <div class="message-content">
                    <span class="username">あかね</span>
                    <span>何か質問はありますか？</span>
                </div>
            </div>
        </div>
        <div class="ai-chat-form">
            <textarea class="ai-chat-input" placeholder="メッセージを入力..." rows="1"></textarea>
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

        const chatWidth = scWidth * 0.37;
        const marginRight = scWidth * 0.01;
        const leftPosition = scWidth - chatWidth - marginRight;
        
        const chatHeight = scHeight * 0.95; 

        chat_container.css({
            "position": "absolute",
            "top": "2%",
            "left": leftPosition + "px",
            "width": chatWidth + "px",
            "height": chatHeight + "px",
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
        
        function addMessage(sender, text, avatar) {
            const cleanHtml = DOMPurify.sanitize(marked.parse(text));
            const messageHTML = `
                <div class="ai-chat-message">
                    <img src="${avatar}" class="avatar">
                    <div class="message-content">
                        <span class="username">${sender}</span>
                        <span>${cleanHtml}</span>
                    </div>
                </div>`;
                
            const messageElement = $(messageHTML);

            messageElement.find("pre").each(function () {
                const preBlock = $(this);
                
                // コピーボタンのHTML要素を作成します
                const copyButton = $('<button class="copy-code-button">コピー</button>');
                
                // ボタンを<pre>タグの「中」に追加します
                preBlock.append(copyButton);

                messageElement.find("pre code").each(function(i, block) {
                    var $block = $(block);
                    var $pre = $block.parent("pre");
                    if ($pre.find('.copy-code-button').length > 0) return; 
                    $pre.css("position", "relative"); 
                    var copyButton = $('<button class="copy-code-button">コピー</button>');
                    copyButton.on("click", function() {
                        var codeText = $block.text();
                        navigator.clipboard.writeText(codeText).then(() => {
                            copyButton.text("コピー完了!");
                            setTimeout(() => { copyButton.text("コピー"); }, 2000);
                        }, (err) => {
                            copyButton.text("失敗");
                            setTimeout(() => { copyButton.text("コピー"); }, 2000);
                        });
                    });
                    $pre.append(copyButton);
                });
            });
            
            messagesContainer.append(messageElement);
            messagesContainer.scrollTop(messagesContainer[0].scrollHeight);
        }

        window.ai_chat_set_busy = function(isBusy) {
            const inputField = $(".ai-chat-input");
            const sendButton = $(".ai-chat-send-button");
            if (isBusy) {
                inputField.prop("disabled", true).attr("placeholder", "処理中です...");
                sendButton.prop("disabled", true);
            } else {
                inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...");
                sendButton.prop("disabled", false);
            }
        };

        // メッセージ送信処理を関数にまとめる
        function sendMessage() {
            const inputField = $(".ai-chat-input");
            const userMessage = inputField.val().trim();
            if (userMessage === "") return;

            // --- 追加: 必要なデータをティラノの変数から取得 ---
            const CodeContent = TYRANO.kag.stat.f['my_code'] || "";
            const current_id = TYRANO.kag.stat.f.current_task_id || "";
            const tasks = TYRANO.kag.stat.f.all_tasks || {};
            const task_data = tasks[current_id] || { description: "課題情報なし" };
            // ----------------------------------------------

            window.ai_chat_add_message("あなた", userMessage, "./data/fgimage/chat/akane/normal.png");
            window.ai_chat_set_busy(true);
            
            fetch('/api/advisor', { 
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    message: userMessage,
                    code: CodeContent, 
                    task: task_data.description,
                }),
            })
            .then(response => {
                if (!response.ok) {
                    return response.text().then(text => { throw new Error(text) });
                }
                return response.json();
            })
            .then(data => {
                addMessage("あかね", data.text, "./data/fgimage/chat/akane/normal.png");
            })
            .catch(error => {
                console.error("AIチャットエラー:", error);
                addMessage("エラー", "AIとの通信に失敗しました。", "./data/fgimage/chat/akane/naki.png");
            })
            .finally(() => {
                window.ai_chat_set_busy(false);
            });
        }

        // イベントリスナーを設定
        sendButton.on("click", sendMessage); 
        inputField.on("keydown", function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault(); 
                sendMessage();
            }
        });

        inputField.on('input', function() {
            this.style.height = 'auto'; // 高さを一旦リセット
            this.style.height = (this.scrollHeight) + 'px'; // 内容の高さに合わせて自身の高さを変更
        });

        window.ai_chat_add_message = function(sender, text, avatar) {
        const messagesContainer = $(".ai-chat-messages");
        const cleanHtml = DOMPurify.sanitize(marked.parse(text));
        const messageHTML = `
            <div class="ai-chat-message">
                <img src="${avatar}" class="avatar">
                <div class="message-content">
                    <span class="username">${sender}</span>
                    <span>${cleanHtml}</span>
                </div>
            </div>`;
        const $msg = $(messageHTML);
        
        // コードコピーボタンの付与 (既存のロジックをここに集約)
        $msg.find("pre code").each(function(i, block) {
            var $block = $(block);
            var $pre = $block.parent("pre");
            $pre.css("position", "relative");
            var $btn = $('<button class="copy-code-button">コピー</button>');
            $btn.on("click", function() {
                navigator.clipboard.writeText($block.text()).then(() => {
                    $btn.text("完了!");
                    setTimeout(() => $btn.text("コピー"), 2000);
                });
            });
            $pre.append($btn);
        });

        messagesContainer.append($msg);
        messagesContainer.scrollTop(messagesContainer[0].scrollHeight);
    };

    // --- AI通信の本体 (mascot_chat_triggerに相当する仕組み) ---
    window.ai_chat_send = function(text, isSystem = false) {
        if (!text) return;

        // システムメッセージでない場合は、ユーザーの入力として表示
        if (!isSystem) {
            window.ai_chat_add_message("あなた", text, "./data/fgimage/chat/akane/normal.png");
            $(".ai-chat-input").val("");
        }

        window.ai_chat_set_busy(true);

        const f = TYRANO.kag.stat.f;
        const task = (f.all_tasks && f.current_task_id) ? f.all_tasks[f.current_task_id].description : "";

        fetch('/api/advisor', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                message: text,
                code: f['my_code'] || "",
                task: task
            }),
        })
        .then(res => res.json())
        .then(data => {
            window.ai_chat_add_message("アドバイザー", data.text, "./data/fgimage/chat/akane/normal.png");
        })
        .catch(err => {
            window.ai_chat_add_message("エラー", "通信に失敗しました。", "./data/fgimage/chat/akane/naki.png");
        })
        .finally(() => {
            window.ai_chat_set_busy(false);
        });
    };

    $(".ai-chat-send-button").off("click").on("click", () => {
        window.ai_chat_send($(".ai-chat-input").val());
    });
    [endscript]

[endmacro]

[macro name="ai_chat_talk"]
    [iscript]
        window.ai_chat_add_message(mp.name, mp.text, mp.avatar);
    [endscript]
[endmacro]

[return]