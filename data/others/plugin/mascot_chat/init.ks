; mascot_chat プラグイン 本体 (ai_chat 改)

; [macro] AIチャットUIを表示するマクロ
[macro name="mascot_chat_show"]

    [loadcss file="./data/others/plugin/mascot_chat/mascot_chat.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    [html]
    <div class="mascot-chat-container" style="display:none;">
        
        <img src="./data/fgimage/chara/akane/normal.png" class="mascot-chat-sprite">

        <div class="mascot-chat-right-panel">
            
            <div class="mascot-chat-bubble-wrapper">
                <div class="mascot-chat-nav">
                    <button class="mascot-chat-prev">◀</button>
                    <button class="mascot-chat-next">▶</button>
                </div>
                <div class="mascot-chat-messages">
                </div>
            </div>

            <div class="mascot-chat-form">
                <textarea class="mascot-chat-input" placeholder="メッセージを入力..." rows="1"></textarea>
                <button class="mascot-chat-send-button">送信</button>
            </div>
        </div>
    </div>
    [endhtml]

    [iscript]
    try {
        var container = $(".mascot-chat-container");
        
        if (container.length > 0) {
            
            if ($(".ui_fix_layer").find(".mascot-chat-container").length > 0) {
                $(".ui_fix_layer").find(".mascot-chat-container").remove();
            }
            
            container.show();
            var target_layer = TYRANO.kag.layer.getLayer("fix");
            target_layer.append(container);
            
            var messagesContainer = container.find(".mascot-chat-messages");
            var inputField = container.find(".mascot-chat-input");
            var sendButton = container.find(".mascot-chat-send-button");
            var navPrev = container.find(".mascot-chat-prev");
            var navNext = container.find(".mascot-chat-next");
            
            function getSfHistory() {
                if (typeof TYRANO.kag.stat.sf === "undefined") {
                    return []; 
                }
                if (!TYRANO.kag.stat.sf.mascot_chat_history) {
                    TYRANO.kag.stat.sf.mascot_chat_history = [];
                }
                return TYRANO.kag.stat.sf.mascot_chat_history;
            }
            
            function getFLogIndex() {
                if (typeof TYRANO.kag.stat.f === "undefined") {
                    return -1; 
                }
                if (typeof TYRANO.kag.stat.f.mascot_chat_log_index === "undefined") {
                    TYRANO.kag.stat.f.mascot_chat_log_index = -1;
                }
                return TYRANO.kag.stat.f.mascot_chat_log_index;
            }

            function addMessage(username, message, is_history_load = false) {
                var messageHtml = DOMPurify.sanitize(marked.parse(message));
                var userNameColor = (username === "あなた") ? "#008800" : "#d9534f";
                
                var messageEl = $(`
                    <div class="mascot-chat-message">
                        <span class="username" style="color: ${userNameColor};">${username}</span>:
                        <div class="message-body">${messageHtml}</div>
                    </div>
                `);
                
                messagesContainer.append(messageEl);
                
                var currentLogIndex = getFLogIndex();
                if (currentLogIndex === -1) {
                    messagesContainer.scrollTop(messagesContainer[0].scrollHeight);
                }
                
                if (!is_history_load && typeof TYRANO.kag.stat.sf !== "undefined") {
                    var history = getSfHistory(); 
                    history.push({ username, message });
                    if (history.length > 50) {
                        history.shift();
                    }
                }
            }

            function showLogMessage(index) {
                var history = getSfHistory(); 
                if (!history[index]) return;
                
                var item = history[index];
                messagesContainer.html(""); 
                addMessage(item.username, item.message, true); 
                
                container.find(".mascot-chat-form").hide(); 
                messagesContainer.scrollTop(0); 
                
                navPrev.prop("disabled", index === 0);
                navNext.prop("disabled", false); 
            }
            
            function restoreLiveChatView() {
                var history = getSfHistory();
                
                if (typeof TYRANO.kag.stat.f !== "undefined") {
                     TYRANO.kag.stat.f.mascot_chat_log_index = -1;
                }
                
                messagesContainer.html(""); 
                
                if (history.length === 0) {
                    addMessage("あかね", "何が聞きたいの？", true);
                } else {
                    history.forEach(item => {
                        addMessage(item.username, item.message, true);
                    });
                }

                container.find(".mascot-chat-form").show(); 
                messagesContainer.scrollTop(messagesContainer[0].scrollHeight); 
                
                navPrev.prop("disabled", history.length === 0);
                navNext.prop("disabled", true); 
            }
            
            function sendMessage() {
                if (typeof TYRANO.kag.stat.sf === "undefined" || typeof TYRANO.kag.stat.f === "undefined") {
                    console.error("TYRANO.kag.stat.sf または .f が undefined です。");
                    addMessage("エラー", "システムが準備中です。少し待ってからもう一度試してください。", true);
                    return;
                }
                var f = TYRANO.kag.stat.f;

                if (getFLogIndex() !== -1) { 
                    restoreLiveChatView();
                }

                var userMessage = inputField.val().trim();
                if (userMessage === "") return;
                
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
                    addMessage("あかね", data.text, false);
                })
                .catch(error => {
                    console.error("AIチャットエラー:", error);
                    addMessage("エラー", "AIとの通信に失敗しました。", false);
                })
                .finally(() => {
                    inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                    sendButton.prop("disabled", false);
                    inputField.css('height', 'auto'); 
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
                
                TYRANO.kag.stat.f.mascot_chat_log_index = currentLogIndex;
                showLogMessage(currentLogIndex);
            });
            
            navNext.on("click", function() {
                if (typeof TYRANO.kag.stat.f === "undefined") return; 
                
                var currentLogIndex = getFLogIndex();
                if (currentLogIndex === -1) return; 
                
                var history = getSfHistory();
                if (currentLogIndex < history.length - 1) {
                    currentLogIndex++;
                    TYRANO.kag.stat.f.mascot_chat_log_index = currentLogIndex;
                    showLogMessage(currentLogIndex);
                } else {
                    restoreLiveChatView();
                }
            });
            
            restoreLiveChatView();

        } else {
            console.error("mascot-chat-container が見つかりません。");
        }
        
    } catch (e) {
        console.error("mascot_chat プラグインの初期化に失敗しました。", e);
    }
    [endscript]
[endmacro]

[return]