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
                        <div class="user-chat-messages"></div>
                    </div>
                </div>
                <div class="ai-bubble-area">
                    <div class="ai-chat-bubble">
                        <div class="ai-chat-messages"></div>
                    </div>
                </div>
            </div>

            <div class="log-view-area" style="display:none;">
                <div class="log-chat-bubble"></div>
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

    [iscript]
    try {
        var container = $(".ai-chat-container");
        if (container.length > 0) {
            
            // --- レイアウト初期化処理 ---
            var fix_layer = $(".fixlayer").last();
            if (fix_layer.find(".ai-chat-container").length > 0) {
                 fix_layer.find(".ai-chat-container").remove();
            }
            fix_layer.append(container); 
            
            var scWidth = parseInt(TYRANO.kag.config.scWidth);
            var scHeight = parseInt(TYRANO.kag.config.scHeight);
            const chatWidth = scWidth * 0.37;
            const marginRight = scWidth * 0.02;
            const leftPosition = scWidth - chatWidth - marginRight;
            const chatHeight = scHeight * 0.92;
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

            // --- UI要素 ---
            var liveChatView = container.find(".live-chat-view");
            var logView = container.find(".log-view-area");
            var aiMessagesContainer = container.find(".ai-chat-messages");
            var userMessagesContainer = container.find(".user-chat-messages");
            var inputField = container.find(".ai-chat-input");
            var sendButton = container.find(".ai-chat-send-button");
            var navPrev = container.find(".ai-chat-nav .ai-chat-prev");
            var navNext = container.find(".ai-chat-nav .ai-chat-next");

            // --- 記憶ロード ---
            if (typeof TYRANO.kag.stat.f.ai_memory === "undefined") {
                TYRANO.kag.stat.f.ai_memory = { summary: "", learned_topics: [], weaknesses: [] };
            }
            fetch('/api/memory')
                .then(r => r.ok ? r.json() : null)
                .then(data => {
                    if(data){
                        TYRANO.kag.stat.f.ai_memory = data;
                        // サーバーの好感度とクライアントの好感度を同期（必要に応じて）
                        if(data.love_level && !TYRANO.kag.stat.f.love_level){
                             TYRANO.kag.stat.f.love_level = data.love_level;
                        }
                        console.log("Memory Loaded:", data);
                    }
                });

            // --- 履歴管理 ---
            function getHistory() {
                if (typeof TYRANO.kag.stat.f === "undefined") TYRANO.kag.stat.f = {};
                if (!TYRANO.kag.stat.f.ai_chat_history) TYRANO.kag.stat.f.ai_chat_history = [];
                return TYRANO.kag.stat.f.ai_chat_history;
            }

            function getTfLogIndex() {
                if (typeof TYRANO.kag.stat.tf === "undefined") TYRANO.kag.stat.tf = {};
                if (typeof TYRANO.kag.stat.tf.ai_chat_log_index === "undefined") TYRANO.kag.stat.tf.ai_chat_log_index = -1;
                return TYRANO.kag.stat.tf.ai_chat_log_index;
            }

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
                        addMessage("モカ", "何か質問ある？", true);
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
                var lastAiMsg = null;
                var lastUserMsg = null;
                
                for (var i = history.length - 1; i >= 0; i--) {
                    if (history[i].username !== "あなた") {
                        lastAiMsg = history[i];
                        break;
                    }
                }
                // 後ろから走査して、最後のユーザーメッセージを探す
                for (var i = history.length - 1; i >= 0; i--) {
                    if (history[i].username === "あなた") {
                        lastUserMsg = history[i];
                        break;
                    }
                }
                
                if (lastAiMsg) {
                    addMessage(lastAiMsg.username, lastAiMsg.message, true);
                } else {
                    addMessage("モカ", "何か質問ある？", true);
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

                var historyContext = "";
                var history = getHistory();
                // 最新の5ラリー分くらいを含める（長すぎるとエラーになる場合があるため調整）
                var recentHistory = history.slice(-10); 
                
                if (recentHistory.length > 0) {
                    historyContext = "\n\n[Conversation History]\n";
                    recentHistory.forEach(function(item) {
                        // AIとユーザーの区別がつくように整形
                        var role = (item.username === "あなた") ? "User" : "Character";
                        // メッセージ内の改行を除去したり短縮しても良い
                        historyContext += role + ": " + item.message + "\n";
                    });
                }
                
                var tasks = f.all_tasks;
                var current_id = f.current_task_id;
                var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
                var currentLove = f.love_level || 0;

                // 記憶情報の付与
                var memoryContext = "";
                if (f.ai_memory) {
                    var summary = f.ai_memory.summary || "なし";
                    var weak = f.ai_memory.weaknesses ? f.ai_memory.weaknesses.join(",") : "なし";
                    memoryContext = `\n\n[Long Term Memory Info]\nSummary: ${summary}\nWeaknesses: ${weak}\n`;
                }
                
                var messageToSend = userMessage + historyContext + memoryContext + `\n\n(System Info: Current Love Level is ${currentLove})`;

                fetch('/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        message: messageToSend, 
                        code: f['my_code'],
                        task: task_data ? task_data.description : "タスクがありません",
                    }),
                })
                .then(r => r.json())
                .then(data => {
                    var aiText = data.text;
                    var emotion = data.emotion || "normal";
                    var loveUpVal = parseInt(data.love_up) || 0; 

                    if (loveUpVal !== 0) {
                        var current = parseInt(f.love_level) || 0;
                        f.love_level = current + loveUpVal; 
                        console.error(`好感度が ${loveUpVal} 上がりました！ 現在: ${f.love_level}`);
                        alertify.success("好感度UP! 現在："+f.love_level);
                    }

                    addMessage("モカ", aiText, false);
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

            // グローバル関数として公開 (戻るボタンから呼べるようにする)
            window.mascot_chat_save = function(callback) {
                var history = getHistory();
                
                // 履歴がない、または短い場合は保存せずに即終了
                if (!history || history.length === 0) {
                    if (callback) callback();
                    return;
                }
                alertify.log("学習記録を保存して終了します...");

                // 現在の好感度を取得 (これをサーバーに送ることで上書き保存させる)
                var currentLove = TYRANO.kag.stat.f.love_level || 0;

                // アラートなどで「保存中」を出すと親切
                // alertify.message("学習記録を保存中...");

                fetch('/api/summarize', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        chat_history: history,
                        current_love_level: parseInt(currentLove) // ★現在の総量を送信
                    })
                })
                .then(r => r.json())
                .then(data => {
                    console.log("Save complete:", data);
                    // 履歴クリア
                    TYRANO.kag.stat.f.ai_chat_history = [];
                    // 必要なら最新記憶をロードしておく（次回用）
                    return fetch('/api/memory');
                })
                .then(r => r.json())
                .then(data => {
                    if(data) TYRANO.kag.stat.f.ai_memory = data;
                })
                .catch(e => {
                    console.error("Save Error:", e);
                })
                .finally(() => {
                    // 完了したらコールバックを実行（画面遷移など）
                    if (callback) callback();
                });
            };

            // window.mascot_chat_trigger としてグローバル公開
            window.mascot_chat_trigger = function(systemMessage) {
                // 必須チェック
                if (typeof TYRANO.kag.stat.f === "undefined") return;
                var f = TYRANO.kag.stat.f;

                // ユーザーのチャット履歴には「表示しない」が、AIには送る
                // (履歴配列にだけ追加して、UIには出さない、あるいは履歴にも入れないなどの調整が可能)
                // ここでは「履歴には入れず、コンテキストとして送る」簡易パターンとします。

                var tasks = f.all_tasks;
                var current_id = f.current_task_id;
                var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
                var currentLove = f.love_level || 0;
                
                // システム通知であることを明示するプレフィックスを付ける
                var messageToSend = "[SYSTEM] " + systemMessage + `\n\n(System Info: Current Love Level is ${currentLove})`;

                // AIチャット中状態にする（入力無効化など）
                var container = $(".ai-chat-container");
                var inputField = container.find(".ai-chat-input");
                inputField.attr("placeholder", "反応中...").prop("disabled", true);

                // APIコール
                fetch('/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        message: messageToSend, 
                        code: f['my_code'], // 現在のコードも送る
                        task: task_data ? task_data.description : "タスクなし",
                    }),
                })
                .then(r => r.json())
                .then(data => {
                    var aiText = data.text;
                    var emotion = data.emotion || "normal";
                    
                    // 好感度変動があれば反映
                    var loveUpVal = parseInt(data.love_up) || 0; 
                    if (loveUpVal !== 0) {
                        f.love_level = (parseInt(f.love_level) || 0) + loveUpVal;
                        // 必要なら通知
                    }

                    // AIのメッセージだけを表示（addMessageは既存のものを使用）
                    // ここで第3引数などを調整して「ログに残さない」設定にしても良いですが、
                    // AIの発言は残したほうが自然です。
                    // ※addMessage関数がinit.ks内のスコープにあるため、windowスコープから呼ぶには工夫が必要ですが、
                    // このコードが init.ks 内にあるなら直接呼べます。
                    
                    // init.ks内のローカル関数 addMessage を呼ぶ
                    addMessage("モカ", aiText, false);

                    // 表情変更
                    var imgPath = "./data/fgimage/chara/akane/" + emotion + ".png";
                    $(".ai-chat-sprite-bottom").attr("src", imgPath);
                })
                .catch(error => {
                    console.error("Trigger Error:", error);
                })
                .finally(() => {
                    inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...");
                });
            };
            
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

        restoreLiveChatView();

        } else {
            console.error("ai-chat-container が見つかりません。");
        }
    } catch (e) { console.error("ai_chat init error", e); }
    [endscript]
[endmacro]
[return]