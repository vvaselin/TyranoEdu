; AIチャットプラグイン 本体 (マスコットUI版)

; [macro] AIチャットUIを表示するマクロ
[macro name="ai_chat_show"]

    ; 1. 必要なCSSを読み込む
    [loadcss file="./data/others/plugin/ai_chat/ai_chat.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    ; 2. [html]タグでUIの骨格を生成する (マスコットUIに変更)
    [html]
    <div class="ai-chat-container" style="display:none;">
        
        <img src="./data/fgimage/chara/akane/normal.png" class="ai-chat-sprite">

        <div class="ai-chat-right-panel">
            
            <div class="ai-chat-bubble-wrapper">
                <div class="ai-chat-nav">
                    <button class="ai-chat-prev">◀</button>
                    <button class="ai-chat-next">▶</button>
                </div>
                <div class="ai-chat-messages">
                </div>
            </div>

            <div class="ai-chat-form">
                <textarea class="ai-chat-input" placeholder="メッセージを入力..." rows="1"></textarea>
                <button class="ai-chat-send-button">送信</button>
            </div>
        </div>
    </div>
    [endhtml]

    ; 3. [iscript]でUIをfixレイヤーに移動し、イベントを設定する
    [iscript]
    try {
        // ---------------------------------------------------------------
        //  初期設定
        // ---------------------------------------------------------------
        var container = $(".ai-chat-container");
        
        if (container.length > 0) {
            
            if ($(".fixlayer").find(".ai-chat-container").length > 0) {
                 $(".fixlayer").find(".ai-chat-container").remove();
            }
            
            container.show();
            // ★修正: ユーザーご指定のレイヤー挿入方法
            var fix_layer = $(".fixlayer").first();
            fix_layer.append(container);
            
            var messagesContainer = container.find(".ai-chat-messages");
            var inputField = container.find(".ai-chat-input");
            var sendButton = container.find(".ai-chat-send-button");
            var navPrev = container.find(".ai-chat-nav .ai-chat-prev");
            var navNext = container.find(".ai-chat-nav .ai-chat-next");
            
            // ---------------------------------------------------------------
            //  会話履歴・ログ表示 管理 (sf/fの安全な初期化)
            // ---------------------------------------------------------------
            
            function getSfHistory() {
                if (typeof TYRANO.kag.stat.sf === "undefined") {
                    return []; 
                }
                if (!TYRANO.kag.stat.sf.ai_chat_history) {
                    TYRANO.kag.stat.sf.ai_chat_history = [];
                }
                return TYRANO.kag.stat.sf.ai_chat_history;
            }
            
            function getFLogIndex() {
                if (typeof TYRANO.kag.stat.f === "undefined") {
                    return -1; 
                }
                if (typeof TYRANO.kag.stat.f.ai_chat_log_index === "undefined") {
                    TYRANO.kag.stat.f.ai_chat_log_index = -1;
                }
                return TYRANO.kag.stat.f.ai_chat_log_index;
            }

            // ---------------------------------------------------------------
            //  関数定義
            // ---------------------------------------------------------------
            
            // ★修正: addMessage をシンプルな形式に変更
            function addMessage(username, message, is_history_load = false) {
                var messageHtml = DOMPurify.sanitize(marked.parse(message));
                var userNameColor = (username === "あなた") ? "#008800" : "#d9534f";
                
                // 元の .ai-chat-message ではなく、新しいシンプルなクラス名を使用
                var messageEl = $(`
                    <div class="ai-chat-message-simple"> 
                        <span class="username" style="color: ${userNameColor};">${username}</span>:
                        <div class="message-body">${messageHtml}</div>
                    </div>
                `);
                
                messagesContainer.append(messageEl);
                
                var currentLogIndex = getFLogIndex();
                if (currentLogIndex === -1) {
                    messagesContainer.scrollTop(messagesContainer[0].scrollHeight);
                }
                
                // 履歴保存
                if (!is_history_load && typeof TYRANO.kag.stat.sf !== "undefined") {
                    var history = getSfHistory(); 
                    history.push({ username, message });
                    if (history.length > 50) {
                        history.shift();
                    }
                    navPrev.prop("disabled", false);
                }
            }

            // ログ表示用関数
            function showLogMessage(index) {
                var history = getSfHistory(); 
                if (!history[index]) return;
                
                var item = history[index];
                messagesContainer.html(""); 
                addMessage(item.username, item.message, true); 
                
                container.find(".ai-chat-form").hide(); 
                messagesContainer.scrollTop(0); 
                
                navPrev.prop("disabled", index === 0);
                navNext.prop("disabled", false); 
            }
            
            // ライブチャット復帰用関数
            function restoreLiveChatView() {
                var history = getSfHistory();
                
                if (typeof TYRANO.kag.stat.f !== "undefined") {
                     TYRANO.kag.stat.f.ai_chat_log_index = -1;
                }
                
                messagesContainer.html(""); 
                
                if (history.length === 0) {
                    addMessage("あかね", "何が聞きたいの？", true);
                } else {
                    history.forEach(item => {
                        addMessage(item.username, item.message, true);
                    });
                }

                container.find(".ai-chat-form").show(); 
                messagesContainer.scrollTop(messagesContainer[0].scrollHeight); 
                
                navPrev.prop("disabled", history.length === 0);
                navNext.prop("disabled", true); 
            }
            
            // ★修正: sendMessage が新しい addMessage を呼ぶように
            function sendMessage() {
                if (typeof TYRANO.kag.stat.f === "undefined") {
                    console.error("TYRANO.kag.stat.f が undefined です。");
                    addMessage("エラー", "システムが準備中です。少し待ってからもう一度試してください。", true);
                    return;
                }
                var f = TYRANO.kag.stat.f;

                if (getFLogIndex() !== -1) { 
                    restoreLiveChatView();
                }

                var userMessage = inputField.val().trim();
                if (userMessage === "") return;
                
                // ユーザーのメッセージを追加
                addMessage("あなた", userMessage, false); 
                
                inputField.val("").attr("placeholder", "AIが応答中...").prop("disabled", true);
                sendButton.prop("disabled", true);
                
                var CodeContent = "";
                var editor_iframe = document.getElementById('monaco_editor_iframe');
                if (editor_iframe) {
                    try {
                        CodeContent = editor_iframe.contentWindow.monaco.editor.getModels()[0].getValue();
                    } catch(e) {
                        console.warn("Monaco Editorからのコード取得に失敗しました: ", e);
                    }
                }
                
                var task_id = f.current_task_id || "default";
                var task_data = f.task_data[task_id];
                if (!task_data) {
                    console.warn("タスクデータが見つかりません。");
                    task_data = { description: "タスクが設定されていません。" };
                }
                
                fetch('http://localhost:8080/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        message: userMessage,
                        code: CodeContent,
                        task: task_data.description,
                    }),
                })
                .then(response => response.ok ? response.json() : response.text().then(text => { throw new Error(text) }))
                .then(data => {
                    // AIの応答を追加 (アバターURLを渡さない)
                    addMessage("あかね", data.text, false);
                })
                .catch(error => {
                    console.error("AIチャットエラー:", error);
                    // エラーメッセージを追加 (アバターURLを渡さない)
                    addMessage("エラー", "AIとの通信に失敗しました。", false);
                })
                .finally(() => {
                    inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                    sendButton.prop("disabled", false);
                    inputField.css('height', 'auto'); 
                });
            }

            // ---------------------------------------------------------------
            //  イベントリスナー設定 (ai_chatから流用)
            // ---------------------------------------------------------------
            
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
            
            // ログ「前へ」
            navPrev.on("click", function() {
                if (typeof TYRANO.kag.stat.f === "undefined") return; 
                
                var history = getSfHistory();
                if (history.length === 0) return;
                
                var currentLogIndex = getFLogIndex();
                
                if (currentLogIndex === -1) {
                    currentLogIndex = history.length - 1;
                } else if (currentLogIndex > 0) {
                    currentLogIndex--;
                }
                
                TYRANO.kag.stat.f.ai_chat_log_index = currentLogIndex;
                showLogMessage(currentLogIndex);
            });
            
            // ログ「次へ」
            navNext.on("click", function() {
                if (typeof TYRANO.kag.stat.f === "undefined") return; 
                
                var currentLogIndex = getFLogIndex();
                if (currentLogIndex === -1) return; 
                
                var history = getSfHistory();
                if (currentLogIndex < history.length - 1) {
                    currentLogIndex++;
                    TYRANO.kag.stat.f.ai_chat_log_index = currentLogIndex;
                    showLogMessage(currentLogIndex);
                } else {
                    restoreLiveChatView();
                }
            });
            
            // ---------------------------------------------------------------
            //  初期表示 (ai_chatと同様、sfを参照しない)
            // ---------------------------------------------------------------
            
            // 最初のメッセージをハードコードで追加
            addMessage("あかね", "何が聞きたいの？", true);
            
            // 履歴がまだ無いので、ログボタンは無効にしておく
            navPrev.prop("disabled", true);
            navNext.prop("disabled", true); 

        } else {
            console.error("ai-chat-container が見つかりません。");
        }
        
    } catch (e) {
        console.error("ai_chat プラグインの初期化に失敗しました。", e);
    }
    [endscript]
[endmacro]

[return]