; AIチャットプラグイン 本体

; [macro] AIチャットUIを表示するマクロ
[macro name="ai_chat_show"]

    ; 1. 必要なCSSを読み込む
    [loadcss file="./data/others/plugin/ai_chat/ai_chat.css"]
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
    try{
        var chat_container = $(".ai-chat-container");
        var fix_layer = $(".fixlayer").first();
        fix_layer.append(chat_container); 

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
        const sendButton = $(".ai-chat-send-button");
        const messagesContainer = $(".ai-chat-messages");

        function getHistory() {
            if (typeof TYRANO.kag.stat.f === "undefined") TYRANO.kag.stat.f = {};
            if (!TYRANO.kag.stat.f.ai_chat_history) TYRANO.kag.stat.f.ai_chat_history = [];
            return TYRANO.kag.stat.f.ai_chat_history;
        }

        window.ai_chat_set_busy = function(isBusy) {
            const inputField = $(".ai-chat-input");
            if (isBusy) {
                inputField.attr("placeholder", "考え中...").prop("disabled", true);
            } else {
                inputField.attr("placeholder", "メッセージを入力...");
            }
        };

        function sendMessage() {
            const inputField = $(".ai-chat-input");
            const userMessage = inputField.val().trim();
            if (userMessage === "") return;

            var history = getHistory();
            var recentHistory = history.slice(-10);
            var historyContext = "";
            if (recentHistory.length > 0) {
                historyContext = "\n\n[Conversation History]\n";
                recentHistory.forEach(function(item) {
                    var role = (item.username === "あなた") ? "User" : "Advisor";
                    historyContext += role + ": " + item.message + "\n";
                });
            }

            const CodeContent = TYRANO.kag.stat.f['my_code'] || "";
            const task_data = (TYRANO.kag.stat.f.all_tasks && TYRANO.kag.stat.f.current_task_id) ? 
                            TYRANO.kag.stat.f.all_tasks[TYRANO.kag.stat.f.current_task_id] : { description: "課題情報なし" };

            ai_chat_add_message("あなた", userMessage, "./data/fgimage/chat/akane/normal.png");
            window.ai_chat_set_busy(true);
            inputField.val("");

            fetch('/api/advisor', { 
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    message: userMessage + historyContext,
                    code: CodeContent, 
                    task: task_data.description,
                }),
            })
            .then(response => response.json())
            .then(data => {
                ai_chat_add_message("あかね", data.text, "./data/fgimage/chat/akane/normal.png");
            })
            .catch(error => {
                ai_chat_add_message("エラー", "通信に失敗しました。", "./data/fgimage/chat/akane/naki.png");
            })
            .finally(() => {
                window.ai_chat_set_busy(false);
            });
        }

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

        function ai_chat_add_message(sender, text, avatar, is_history_load = false) {
            if (text) {
                text = text.replace(/\\n/g, '\n');
            }
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

            if (!is_history_load) {
                var history = getHistory();
                history.push({ username: sender, message: text });
                if (history.length > 50) history.shift();
            }
        };

        window.ai_chat_trigger = function(systemMessage) {
            if (typeof TYRANO.kag.stat.f === "undefined") return;
            var f = TYRANO.kag.stat.f;

            var container = $(".ai-chat-container");
            window.ai_chat_set_busy(true);
            inputField.val("");

            var tasks = f.all_tasks;
            var current_id = f.current_task_id;
            var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
            var messageToSend = "[SYSTEM] " + systemMessage;

            window.ai_chat_set_busy(true);

            fetch('/api/advisor', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    message: messageToSend, 
                    code: f['my_code'] || "",
                    task: task_data ? task_data.description : "タスクがありません"
                }),
            })
            .then(res => res.json())
            .then(data => {
                if (ai_chat_add_message) {
                    ai_chat_add_message("あかね", data.text, "./data/fgimage/chat/akane/normal.png");
                }
            })
            .finally(() => {
                window.ai_chat_set_busy(false);
            });
        };

        window.ai_chat_save = function(callback) {
            var history = getHistory();
            if (!history || history.length === 0) {
                if (callback) callback();
                return;
            }
            
            alertify.log("学習記録を保存...");
            fetch('/api/summarize', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    user_id: TYRANO.kag.stat.f.user_id,
                    chat_history: history
                })
            })
            .then(r => r.json())
            .then(data => {
                TYRANO.kag.stat.f.ai_chat_history = [];
                if (callback) callback();
            })
            .catch(e => {
                console.error("Save Error:", e);
                if (callback) callback();
            });
        };
    } catch (e) { console.error("ai_chat init error", e); }
    [endscript]

[endmacro]

[macro name="ai_chat_talk"]
    [iscript]
        ai_chat_add_message(mp.name, mp.text, mp.avatar);
    [endscript]
[endmacro]

[return]