[macro name="ai_chat_show"]

    ; 必要なCSSを読み込む
    [loadcss file="./data/others/plugin/mascot_chat/mascot.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    ; [html]タグでUIの骨格を生成する
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
                <button class="ai-chat-save" style="font-size:12px; margin-left:10px;">記録して終了</button>
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
            // --- UI要素の参照 ---
            var liveChatView = container.find(".live-chat-view");
            var logView = container.find(".log-view-area");
            
            var aiMessagesContainer = container.find(".ai-chat-messages");
            var userMessagesContainer = container.find(".user-chat-messages");
            var logMessagesContainer = container.find(".log-chat-bubble");

            var inputField = container.find(".ai-chat-input");
            var sendButton = container.find(".ai-chat-send-button");
            var navPrev = container.find(".ai-chat-nav .ai-chat-prev");
            var navNext = container.find(".ai-chat-nav .ai-chat-next");
            var saveButton = container.find(".ai-chat-save"); 

            // --- 記憶管理 ---
            
            // サーバーから長期記憶をロード
            if (typeof TYRANO.kag.stat.f.ai_memory === "undefined") {
                TYRANO.kag.stat.f.ai_memory = { summary: "", learned_topics: [], weaknesses: [] };
            }
            
            fetch('/api/memory')
                .then(r => r.ok ? r.json() : null)
                .then(data => {
                    if(data){
                        TYRANO.kag.stat.f.ai_memory = data;
                        console.log("Memory Loaded:", data);
                    }
                })
                .catch(e => console.error("Memory Load Error:", e));


            function getHistory() {
                if (typeof TYRANO.kag.stat.f === "undefined") {
                    TYRANO.kag.stat.f = {};
                }
                if (!TYRANO.kag.stat.f.ai_chat_history) {
                    TYRANO.kag.stat.f.ai_chat_history = [];
                }
                return TYRANO.kag.stat.f.ai_chat_history;
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
                if (message) {
                    message = message.replace(/\\n/g, '\n');
                }

                var messageHtml = DOMPurify.sanitize(marked.parse(message, { breaks: true }));
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

                if (username === "あなた") {
                    userMessagesContainer.html(messageEl);
                    userMessagesContainer.scrollTop(0);
                } else {
                    aiMessagesContainer.html(messageEl);
                    aiMessagesContainer.scrollTop(0);
                }
                
                // 履歴保存とボタン有効化ロジック
                if (!is_history_load) {
                    navPrev.prop("disabled", false);
                    var history = getHistory(); 
                    
                    history.push({ username, message }); 
                    if (history.length > 50) {
                        history.shift();
                    }
                }
            }

            function showLogMessage(index) {
                var history = getHistory();
                if (!history[index]) return;
                
                var item = history[index];
                
                liveChatView.show();
                logView.hide();
                container.find(".ai-chat-form").hide(); 
                
                var messageHtml = DOMPurify.sanitize(marked.parse(item.message));
                var messageEl = $(`
                    <div class="ai-chat-message-simple"> 
                        <div class="message-body">${messageHtml}</div>
                    </div>
                `);
                
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

                if (item.username === "あなた") {
                    userMessagesContainer.html(messageEl);
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
                        addMessage("あかね", "何が聞きたいの？", true);
                    }
                    
                } else {
                    aiMessagesContainer.html(messageEl); 
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
                        userMessagesContainer.html("");
                    }
                }
                
                navPrev.prop("disabled", index === 0);
                navNext.prop("disabled", false); 
            }
            
            function restoreLiveChatView() {
                if (typeof TYRANO.kag.stat.tf !== "undefined") {
                     TYRANO.kag.stat.tf.ai_chat_log_index = -1;
                } else {
                    getTfLogIndex();
                }
                
                logView.hide();
                liveChatView.show();
                container.find(".ai-chat-form").show();
                
                var history = getHistory(); 
                var lastAiMsg = history.findLast(item => item.username !== "あなた");
                var lastUserMsg = history.findLast(item => item.username === "あなた");
                
                if (lastAiMsg) {
                    addMessage(lastAiMsg.username, lastAiMsg.message, true);
                } else {
                    addMessage("あかね", "何か質問ある？", true);
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
                    addMessage("エラー", "システムが準備中です。", true);
                    return;
                }
                
                var f = TYRANO.kag.stat.f;
                var userMessage = inputField.val().trim();
                if (userMessage === "") return;
                
                addMessage("あなた", userMessage, false);
                inputField.val("").attr("placeholder", "考え中...").prop("disabled", true);
                sendButton.prop("disabled", true);
                
                const CodeContent = f['my_code'];
                var tasks = f.all_tasks;
                var current_id = f.current_task_id;
                var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
                var currentLove = f.love_level || 0;

                // 記憶情報をシステムプロンプト指示として付与
                var memoryContext = "";
                if (f.ai_memory) {
                    var summary = f.ai_memory.summary || "なし";
                    var weak = f.ai_memory.weaknesses ? f.ai_memory.weaknesses.join(",") : "なし";
                    memoryContext = `\n\n[Long Term Memory Info]\nSummary: ${summary}\nWeaknesses: ${weak}\n`;
                }
                
                var messageToSend = userMessage + memoryContext + `\n\n(System Info: Current Love Level is ${currentLove})`;

                fetch('/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        message: messageToSend, 
                        code: CodeContent,
                        task: task_data ? task_data.description : "タスクがありません",
                    }),
                })
                .then(response => response.ok ? response.json() : response.text().then(text => { throw new Error(text) }))
                .then(data => {
                    var aiText = data.text;
                    var emotion = data.emotion || "normal";
                    var loveUpVal = parseInt(data.love_up) || 0; 

                    if (loveUpVal > 0) {
                        var current = parseInt(f.love_level) || 0;
                        f.love_level = current + loveUpVal;
                        console.error(`好感度が ${loveUpVal} 上がりました！ 現在: ${f.love_level}`);
                        alertify.success("好感度UP! 現在："+f.love_level);
                    }

                    addMessage("あかね", aiText, false);
                    var imgPath = "./data/fgimage/chara/akane/" + emotion + ".png";
                    $(".ai-chat-sprite-bottom").attr("src", imgPath);
                })
                .catch(error => {
                    console.error("AIチャットエラー:", error);
                    addMessage("エラー", "上手くお話出来ませんでした。", false);
                    $(".ai-chat-sprite-bottom").attr("src", "./data/fgimage/chara/akane/sad.png");
                })
                .finally(() => {
                    inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                    sendButton.prop("disabled", false);
                    inputField.css('height', 'auto'); 
                });
            }

            // セッション保存(要約)処理
            function saveSessionAndClear() {
                var history = getHistory();
                if (!history || history.length === 0) {
                    alertify.message("記録する会話履歴がありません");
                    return;
                }

                saveButton.prop("disabled", true).text("記録中...");

                fetch('/api/summarize', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ chat_history: history })
                })
                .then(r => r.ok ? r.json() : Promise.reject(r))
                .then(data => {
                    alertify.success("学習記録を保存しました");
                    // セッション履歴をクリア
                    TYRANO.kag.stat.f.ai_chat_history = [];
                    // UIリセット
                    userMessagesContainer.html("");
                    aiMessagesContainer.html("");
                    restoreLiveChatView();
                    
                    // 最新の記憶を再ロード
                    return fetch('/api/memory');
                })
                .then(r => r.json())
                .then(data => {
                    if(data) TYRANO.kag.stat.f.ai_memory = data;
                })
                .catch(e => {
                    console.error("Save Error:", e);
                    alertify.error("記録の保存に失敗しました");
                })
                .finally(() => {
                    saveButton.prop("disabled", false).text("記録して終了");
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
            
            // 履歴ナビゲーション
            navPrev.on("click", function() {
                var history = getHistory(); 
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
            
            navNext.on("click", function() {
                var currentLogIndex = getTfLogIndex();
                if (currentLogIndex === -1) return; 
                
                var history = getHistory(); 
                var nextLogIndex = currentLogIndex + 2;
                
                if (nextLogIndex < history.length - 1) {
                    TYRANO.kag.stat.tf.ai_chat_log_index = nextLogIndex;
                    showLogMessage(nextLogIndex);
                } else {
                    restoreLiveChatView();
                }
            });

            // 保存ボタンイベント
            saveButton.on("click", function(){
                saveSessionAndClear();
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