; [macro] AIチャットUIを表示するマクロ
[macro name="ai_chat_show"]

    ; 必要なCSSを読み込む
    [loadcss file="./data/others/plugin/mascot_chat/mascot.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    ; [html]タグでUIの骨格を生成する (新レイアウト)
    [html]
    <div class="ai-chat-container" style="display:none;">
        
        <div class="mascot-ui-wrapper">
            
            <div class="live-chat-view">
                
                <div class="user-bubble-area">
                    <div class="user-chat-bubble">
                        <div class="user-chat-messages">
                            </div>
                    </div>
                </div>

                <div class="ai-bubble-area">
                    <div class="ai-chat-bubble">
                        <div class="ai-chat-messages">
                            </div>
                    </div>
                </div>
            </div>

            <div class="log-view-area" style="display:none;">
                <div class="log-chat-bubble">
                    </div>
            </div>

            <div class="ai-chat-nav">
                <button class="ai-chat-prev">◀</button>
                <button class="ai-chat-next">▶</button>
            </div>
        </div>

        <img src="./data/fgimage/chara/akane/normal.png" class="ai-chat-sprite-bottom">

        <div class="ai-chat-form">
            <textarea class="ai-chat-input" placeholder="メッセージを入力..." rows="1"></textarea>
            <button class="ai-chat-send-button">送信</button>
        </div>
    </div>
    [endhtml]

    ; [iscript]でUIをfixレイヤーに移動し、イベントを設定する
    [iscript]
    try {
        var container = $(".ai-chat-container");
        
        if (container.length > 0) {
            
            var fix_layer = $(".fixlayer").last(); 
            
            if (fix_layer.find(".ai-chat-container").length > 0) {
                 fix_layer.find(".ai-chat-container").remove();
            }

            fix_layer.append(container); 
            
            var scWidth = parseInt(TYRANO.kag.config.scWidth);
            var scHeight = parseInt(TYRANO.kag.config.scHeight);

            const chatWidth = scWidth * 0.37;
            const marginRight = scWidth * 0.001;
            const leftPosition = scWidth - chatWidth - marginRight;
            const chatHeight = scHeight * 0.90; 

            container.css({
                "position": "absolute",
                "top": "2%",
                "left": leftPosition + "px",
                "width": chatWidth + "px",
                "height": chatHeight + "px",
                "z-index": "20000"
            });
            
            var messagesWrapper = container.find(".mascot-ui-wrapper");
            
            const formHeight = 75; 
            const messagesWrapperHeight = chatHeight - formHeight;
            
            messagesWrapper.css("height", messagesWrapperHeight + "px");

            container.show(); 
            
            // --- UI要素の参照 (新レイアウト) ---
            var liveChatView = container.find(".live-chat-view");
            var logView = container.find(".log-view-area");
            
            var aiMessagesContainer = container.find(".ai-chat-messages");
            var userMessagesContainer = container.find(".user-chat-messages");
            var logMessagesContainer = container.find(".log-chat-bubble");

            var inputField = container.find(".ai-chat-input");
            var sendButton = container.find(".ai-chat-send-button");
            var navPrev = container.find(".ai-chat-nav .ai-chat-prev");
            var navNext = container.find(".ai-chat-nav .ai-chat-next");
            
            // --- 履歴管理 (tf を使用) ---
            
            function getTfHistory() {
                if (typeof TYRANO.kag.stat.tf === "undefined") {
                    TYRANO.kag.stat.tf = {};
                }
                if (!TYRANO.kag.stat.tf.ai_chat_history) {
                    TYRANO.kag.stat.tf.ai_chat_history = [];
                }
                return TYRANO.kag.stat.tf.ai_chat_history;
            }
            
            function getTfLogIndex() {
                if (typeof TYRANO.kag.stat.tf === "undefined") {
                    TYRANO.kag.stat.tf = {};
                }
                if (typeof TYRANO.kag.stat.tf.ai_chat_log_index === "undefined") {
                    TYRANO.kag.stat.tf.ai_chat_log_index = -1;
                }
                return TYRANO.kag.stat.tf.ai_chat_log_index;
            }
            
            // --- 関数定義 ---
            // ログ表示
            function addMessage(username, message, is_history_load = false) {
                var messageHtml = DOMPurify.sanitize(marked.parse(message));
                
                var messageEl = $(`
                    <div class="ai-chat-message-simple"> 
                        <div class="message-body">${messageHtml}</div>
                    </div>
                `);

                // コピーボタン機能
                messageEl.find("pre code").each(function(i, block) {
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


                // ライブ表示の際、AIとユーザーの枠を分けて更新
                if (username === "あなた") {
                    userMessagesContainer.html(messageEl); // 上書き
                    userMessagesContainer.scrollTop(0);
                } else {
                    aiMessagesContainer.html(messageEl); // 上書き
                    aiMessagesContainer.scrollTop(0);
                }
                
                // 履歴保存とボタン有効化ロジック (tf を使用)
                if (!is_history_load) {
                    
                    navPrev.prop("disabled", false); 

                    var history = getTfHistory(); 
                    
                    history.push({ username, message }); 
                    if (history.length > 50) {
                        history.shift();
                    }
                }
            }

            function showLogMessage(index) {
                var history = getTfHistory(); 
                if (!history[index]) return;
                
                var item = history[index];
                
                // ログ表示中はライブビューと入力欄を隠す
                liveChatView.show();
                logView.hide();
                container.find(".ai-chat-form").hide(); 
                
                // 表示するメッセージを作成
                var messageHtml = DOMPurify.sanitize(marked.parse(item.message));
                var messageEl = $(`
                    <div class="ai-chat-message-simple"> 
                        <div class="message-body">${messageHtml}</div>
                    </div>
                `);
                
                // コピーボタンを追加
                messageEl.find("pre code").each(function(i, block) {
                    var $block = $(block); var $pre = $block.parent("pre");
                    if ($pre.find('.copy-code-button').length > 0) return; 
                    $pre.css("position", "relative"); 
                    var copyButton = $('<button class="copy-code-button">コピー</button>');
                    copyButton.on("click", function() {
                        var codeText = $block.text();
                        navigator.clipboard.writeText(codeText).then(() => {
                            copyButton.text("コピー完了!");
                            setTimeout(() => { copyButton.text("コピー"); }, 2000);
                        });
                    });
                    $pre.append(copyButton);
                });

                // メッセージの投入先を決定
                if (item.username === "あなた") {
                    // ユーザーのログの場合
                    userMessagesContainer.html(messageEl); // ユーザー枠に表示
                    
                    // このログの直前のAIの返答を探す
                    var prevAiMsg = null;
                    for (var i = index - 1; i >= 0; i--) {
                        if (history[i].username !== "あなた") {
                            prevAiMsg = history[i];
                            break;
                        }
                    }
                    if (prevAiMsg) {
                        addMessage(prevAiMsg.username, prevAiMsg.message, true);
                    } else {
                        addMessage("あかね", "何が聞きたいの？", true); // 見つからなければデフォルト
                    }
                    
                } else {
                    // AIのログの場合
                    aiMessagesContainer.html(messageEl); // AI枠に表示
                    
                    // このログの直前のユーザーの質問を探す
                    var prevUserMsg = null;
                    for (var i = index - 1; i >= 0; i--) {
                        if (history[i].username === "あなた") {
                            prevUserMsg = history[i];
                            break;
                        }
                    }
                    if (prevUserMsg) {
                        addMessage(prevUserMsg.username, prevUserMsg.message, true);
                    } else {
                        userMessagesContainer.html(""); // 見つからなければ空
                    }
                }
                
                navPrev.prop("disabled", index === 0);
                navNext.prop("disabled", false); 
            }
            
            // ライブ復帰ロジック (入力欄の表示を徹底)
            function restoreLiveChatView() {
                if (typeof TYRANO.kag.stat.tf !== "undefined") {
                     TYRANO.kag.stat.tf.ai_chat_log_index = -1;
                } else {
                    getTfLogIndex(); 
                }
                
                logView.hide();         // ログ専用枠は隠す
                liveChatView.show();    // ライブ枠を表示
                container.find(".ai-chat-form").show();
                
                var history = getTfHistory(); 
                
                var lastAiMsg = history.findLast(item => item.username !== "あなた");
                var lastUserMsg = history.findLast(item => item.username === "あなた");

                if (lastAiMsg) {
                    addMessage(lastAiMsg.username, lastAiMsg.message, true);
                } else {
                    addMessage("あかね", "何が聞きたいの？", true); 
                }
                if (lastUserMsg) {
                    addMessage(lastUserMsg.username, lastUserMsg.message, true);
                } else {
                    userMessagesContainer.html(""); 
                }
                navPrev.prop("disabled", history.length === 0);
                navNext.prop("disabled", true); 
            }
            
            // --- 送信処理 ---
            function sendMessage() {
                if (getTfLogIndex() !== -1) { 
                    restoreLiveChatView();
                }

                if (typeof TYRANO.kag.stat.f === "undefined") {
                    console.error("TYRANO.kag.stat.f が undefined です。");
                    addMessage("エラー", "システムが準備中です。少し待ってからもう一度試してください。", true);
                    return;
                }
                var f = TYRANO.kag.stat.f;

                var userMessage = inputField.val().trim();
                if (userMessage === "") return;
                
                addMessage("あなた", userMessage, false); 
                
                inputField.val("").attr("placeholder", "考え中...").prop("disabled", true);
                sendButton.prop("disabled", true);
                
                const CodeContent = TYRANO.kag.stat.f['my_code'];
                
                var tasks = TYRANO.kag.stat.f.all_tasks;
                var current_id = TYRANO.kag.stat.f.current_task_id;
                var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
                
                fetch('/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        message: userMessage,
                        code: CodeContent,
                        task: task_data ? task_data.description : "タスクがありません", // null回避
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
            
            // --- イベントリスナー ---
            
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
                var history = getTfHistory(); 
                if (history.length === 0) return;
                var currentLogIndex = getTfLogIndex();
                
                if (currentLogIndex === -1) {
                    currentLogIndex = history.length - 1;
                } else if (currentLogIndex >= 0) {
                    currentLogIndex -= 2;
                }
                if (currentLogIndex < 0) currentLogIndex = 0;
                TYRANO.kag.stat.tf.ai_chat_log_index = currentLogIndex;
                showLogMessage(currentLogIndex);
            });
            // ログ「次へ」
            navNext.on("click", function() {
                var currentLogIndex = getTfLogIndex();
                if (currentLogIndex === -1) return; 
                
                var history = getTfHistory(); 
                var nextLogIndex = currentLogIndex + 2;
                
                if (nextLogIndex < history.length - 1) {
                    TYRANO.kag.stat.tf.ai_chat_log_index = nextLogIndex;
                    showLogMessage(nextLogIndex);
                } else {
                    restoreLiveChatView();
                }
            });
            
            restoreLiveChatView();

        } else {
            console.error("ai-chat-container が見つかりません。");
        }
        
    } catch (e) {
        console.error("ai_chat プラグインの初期化に失敗しました。", e);
    }
    [endscript]
[endmacro]

[return]