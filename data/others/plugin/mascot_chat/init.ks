; AIチャットプラグイン 本体 (マスコットUI版)

; [macro] AIチャットUIを表示するマクロ
[macro name="ai_chat_show"]

    ; 1. 必要なCSSを読み込む
    [loadcss file="./data/others/plugin/mascot_chat/mascot.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    ; 2. [html]タグでUIの骨格を生成する (新レイアウト)
    [html]
    <div class="ai-chat-container" style="display:none;">
        
        <div class="mascot-ui-wrapper">
            
            <div class="live-chat-view">
                <div class="ai-bubble-area">
                    <div class="ai-chat-bubble">
                        <div class="ai-chat-messages">
                            </div>
                    </div>
                    <img src="./data/fgimage/chara/akane/normal.png" class="ai-chat-sprite-small">
                </div>
                
                <div class="user-bubble-area">
                    <div class="user-chat-bubble">
                        <div class="user-chat-messages">
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

        <div class="ai-chat-form">
            <textarea class="ai-chat-input" placeholder="メッセージを入力..." rows="1"></textarea>
            <button class="ai-chat-send-button">送信</button>
        </div>
    </div>
    [endhtml]

    ; 3. [iscript]でUIをfixレイヤーに移動し、イベントを設定する
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

            const chatWidth = scWidth * 0.35;
            const marginRight = scWidth * 0.01;
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
            
            // --- 履歴管理 (変更なし) ---
            function getSfHistory() {
                if (typeof TYRANO.kag.stat.sf === "undefined") {
                    return []; 
                }
                if (!TYRANO.kag.stat.sf.ai_chat_history) {
                    TYRANO.kag.stat.sf.ai_chat_history = [];
                }
                return TYRANO.kag.stat.sf.ai_chat_history;
                console.error(TYRANO.kag.stat.sf.ai_chat_history);
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
            
            // --- 関数定義 (★ 2点修正) ---
            
            function addMessage(username, message, is_history_load = false) {
                var messageHtml = DOMPurify.sanitize(marked.parse(message));
                var userNameColor = (username === "あなた") ? "#008800" : "#d9534f";
                
                var messageEl = $(`
                    <div class="ai-chat-message-simple"> 
                        <span class="username" style="color: ${userNameColor};">${username}</span>:
                        <div class="message-body">${messageHtml}</div>
                    </div>
                `);

                // ★修正点2: コピーボタン機能を復活 (ai_chat より移植)
                messageEl.find("pre code").each(function(i, block) {
                    var $block = $(block);
                    var $pre = $block.parent("pre");
                    
                    if ($pre.find('.copy-code-button').length > 0) {
                        return; 
                    }

                    $pre.css("position", "relative"); 
                    var copyButton = $('<button class="copy-code-button">コピー</button>');
                    
                    copyButton.on("click", function() {
                        var codeText = $block.text();
                        navigator.clipboard.writeText(codeText).then(() => {
                            copyButton.text("コピー完了!");
                            setTimeout(() => {
                                copyButton.text("コピー");
                            }, 2000);
                        }, (err) => {
                            console.error('クリップボードへのコピーに失敗しました', err);
                            copyButton.text("失敗");
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
                
                // ★修正点1: 履歴保存とボタン有効化ロジック
                if (!is_history_load) {
                    var history = getSfHistory(); 
                    // sf が undefined でも history は [] になる
                    
                    if (typeof TYRANO.kag.stat.sf !== "undefined") {
                        // sf が定義済みの場合のみ履歴に push
                        history.push({ username, message });
                        if (history.length > 50) {
                            history.shift();
                        }
                    }
                    
                    // 履歴が 1 件以上あれば（=今プッシュした）、「前へ」ボタンを有効化
                    if (history.length > 0) {
                         navPrev.prop("disabled", false);
                    }
                }
            }

            function showLogMessage(index) {
                var history = getSfHistory(); 
                if (!history[index]) return;
                
                var item = history[index];
                var messageHtml = DOMPurify.sanitize(marked.parse(item.message));
                var userNameColor = (item.username === "あなた") ? "#008800" : "#d9534f";
                
                var messageEl = $(`
                    <div class="ai-chat-message-simple"> 
                        <span class="username" style="color: ${userNameColor};">${item.username}</span>:
                        <div class="message-body">${messageHtml}</div>
                    </div>
                `);
                
                // ログにもコピーボタン機能を追加
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
                        });
                    });
                    $pre.append(copyButton);
                });

                logMessagesContainer.html(messageEl); 
                
                liveChatView.hide(); 
                logView.show();      
                container.find(".ai-chat-form").hide(); 
                
                navPrev.prop("disabled", index === 0);
                navNext.prop("disabled", false); 
            }
            
            function restoreLiveChatView() {
                if (typeof TYRANO.kag.stat.f !== "undefined") {
                     TYRANO.kag.stat.f.ai_chat_log_index = -1;
                }
                
                logView.hide();         
                liveChatView.show();    
                container.find(".ai-chat-form").show(); 
                
                var history = getSfHistory();
                
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
            
            // --- 送信処理 (変更なし) ---
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
            
            // --- イベントリスナー (変更なし) ---
            
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
                
                TYRANO.kag.stat.f.ai_chat_log_index = currentLogIndex;
                showLogMessage(currentLogIndex);
            });
            
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