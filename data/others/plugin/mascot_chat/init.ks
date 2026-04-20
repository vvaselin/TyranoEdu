[macro name="mascot_chat_show"]

    ; 必要なCSSを読み込む
    [loadcss file="./data/others/plugin/mascot_chat/mascot.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    [chara_show name="mocha" left=950  width=430 top =420]

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


        <div class="love-gauge-box">
            <div class="love-level-display">Lv.<span class="love-level-num">1</span></div>
            <div class="love-icon">♥</div>
            <div class="love-gauge-track">
                <div class="love-gauge-fill"></div>
            </div>
            <div class="love-text">0 / 16</div>
        </div>

        <div class="ai-chat-form">
            <textarea class="ai-chat-input" placeholder="メッセージを入力..." rows="1"></textarea>
            <button class="ai-chat-send-button">送信</button>
        </div>
    </div>
    [endhtml]

    [iscript]
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
        var uid = TYRANO.kag.stat.f.user_id;    
        // --- 記憶ロード ---
        if (typeof TYRANO.kag.stat.f.ai_memory === "undefined") {
            TYRANO.kag.stat.f.ai_memory = { summary: "", learned_topics: [], weaknesses: [] };
        }
        fetch('/api/memory?user_id=' + uid)
            .then(r => r.ok ? r.json() : null)
            .then(data => {
                if(data){
                    TYRANO.kag.stat.f.ai_memory = data;
                    if(data.love_level && !TYRANO.kag.stat.f.love_level){
                         TYRANO.kag.stat.f.love_level = data.love_level;
                    }
                    window.updateLoveGaugeUI();
                }
            }); 
        // ================================================================
        // WebSocket 接続管理
        // ================================================================
        //
        // 設計方針:
        //   - WS接続はここで一度だけ確立し、window.mascotChatWS に保持する
        //   - 送信時は ws.send(JSON文字列) を呼ぶだけ
        //   - レスポンスは ws.onmessage で受け取り、pendingCallback を実行する
        //   - pendingCallback は「一度に1リクエスト」の前提で1つだけ保持する
        //     (sendButton/inputField を disabled にしているため同時送信は起きない)
        //   - 切断時は自動再接続する (最大3回、指数バックオフ)
        // ================================================================ 
        var WS_URL = "ws://" + location.host + "/api/chat/ws";
        var ws = null;
        var pendingCallback = null;  // 現在のリクエストに対するレスポンスハンドラ
        var reconnectAttempts = 0;
        var MAX_RECONNECT = 3;  
        function connectWS() {
            if (ws && (ws.readyState === WebSocket.CONNECTING || ws.readyState === WebSocket.OPEN)) {
                return; // 既に接続中 or 接続済み
            }   
            ws = new WebSocket(WS_URL); 
            ws.onopen = function() {
                console.log("[MascotChat] WebSocket接続完了");
                reconnectAttempts = 0;
            };  
            ws.onmessage = function(event) {
                try {
                    var data = JSON.parse(event.data);
                    if (pendingCallback) {
                        var cb = pendingCallback;
                        pendingCallback = null;
                        cb(null, data);
                    }
                } catch(e) {
                    console.error("[MascotChat] WS onmessage JSONパース失敗:", e);
                    if (pendingCallback) {
                        var cb = pendingCallback;
                        pendingCallback = null;
                        cb(e, null);
                    }
                }
            };  
            ws.onerror = function(e) {
                console.error("[MascotChat] WSエラー:", e);
                if (pendingCallback) {
                    var cb = pendingCallback;
                    pendingCallback = null;
                    cb(new Error("WebSocket通信エラー"), null);
                }
            };  
            ws.onclose = function(event) {
                console.warn("[MascotChat] WS切断 (code=" + event.code + ")");
                ws = null;  
                // ペンディング中のコールバックがあればエラーを通知
                if (pendingCallback) {
                    var cb = pendingCallback;
                    pendingCallback = null;
                    cb(new Error("WebSocket切断"), null);
                }   
                // 通常クローズ (1000, 1001) 以外なら自動再接続
                if (event.code !== 1000 && event.code !== 1001 && reconnectAttempts < MAX_RECONNECT) {
                    var delay = Math.pow(2, reconnectAttempts) * 1000; // 1s, 2s, 4s
                    reconnectAttempts++;
                    console.log("[MascotChat] " + delay + "ms後に再接続試行 (" + reconnectAttempts + "/" + MAX_RECONNECT + ")");
                    setTimeout(connectWS, delay);
                }
            };
        }   
        // 接続開始
        connectWS();    
        // WS経由でAIにリクエストを送信し、コールバックでレスポンスを受け取るヘルパー
        // callback(error, data) 形式
        function sendChatRequest(payload, callback) {
            // WSが開いていなければHTTP fallbackまたは再接続
            if (!ws || ws.readyState !== WebSocket.OPEN) {
                console.warn("[MascotChat] WS未接続。再接続してからリトライします");
                connectWS();
                // 接続完了を少し待ってリトライ (簡易版: 500ms後に1回だけ)
                setTimeout(function() {
                    if (ws && ws.readyState === WebSocket.OPEN) {
                        pendingCallback = callback;
                        ws.send(JSON.stringify(payload));
                    } else {
                        // それでも繋がらなければHTTP fallbackへ
                        console.warn("[MascotChat] WSリトライ失敗。HTTP fallbackを使用");
                        fetch('/api/chat', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(payload)
                        })
                        .then(r => r.json())
                        .then(data => callback(null, data))
                        .catch(err => callback(err, null));
                    }
                }, 500);
                return;
            }   
            pendingCallback = callback;
            ws.send(JSON.stringify(payload));
        }   
        // ================================================================
        // 履歴管理
        // ================================================================
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
        // ================================================================
        // AIレスポンス受信後の共通処理
        // ================================================================
        function applyAIResponse(data, isSystemTrigger) {
            var aiText = data.text || "";
            var emotion = data.emotion || "normal";
            var loveUpVal = parseInt(data.love_up) || 0;
            var f = TYRANO.kag.stat.f;  
            // 感情パラメータを保存
            if (data.parameters) {
                f.prev_params = data.parameters;
            }   
            // 好感度変動（サンドボックスモードでは無効）
            if (!f.is_sandbox && loveUpVal !== 0) {
                var current = parseInt(f.love_level) || 0;
                f.love_level = Math.min(100, Math.max(0, current + loveUpVal));

                console.log("[MascotChat] 好感度変動:", loveUpVal);
                if (loveUpVal > 0) {
                    alertify.success("好感度UP!");
                } else {
                    alertify.error("好感度DOWN...");
                }   
                if (window.saveLoveLevelToSupabase) {
                    window.saveLoveLevelToSupabase(f.love_level);
                }
                window.updateLoveGaugeUI();
            }   
            addMessage("モカ", aiText, false);
            tyrano.plugin.kag.ftag.startTag("chara_mod", {name:"mocha", face:emotion, time:200});
        }   
        // ================================================================
        // 送信処理 (ユーザー入力)
        // ================================================================
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
            // 会話履歴コンテキスト構築
            var historyContext = "";
            var history = getHistory();
            var recentHistory = history.slice(-10); 
            if (recentHistory.length > 0) {
                historyContext = "\n\n[Conversation History]\n";
                recentHistory.forEach(function(item) {
                    var role = (item.username === "あなた") ? "User" : "Character";
                    historyContext += role + ": " + item.message + "\n";
                });
            }

            // 長期記憶コンテキスト構築
            var memoryContext = "";
            if (f.ai_memory) {
                var summary = f.ai_memory.summary || "なし";
                var weak = f.ai_memory.weaknesses ? f.ai_memory.weaknesses.join(",") : "なし";
                memoryContext = `\n\n[Long Term Memory Info]\nSummary: ${summary}\nWeaknesses: ${weak}\n`;
            }

            var tasks = f.all_tasks;
            var current_id = f.current_task_id;
            var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
            var currentLove = f.love_level || 0;
            var messageToSend = userMessage + historyContext + memoryContext;   
            var payload = {
                character_id: "mocha",
                message: messageToSend, 
                code: f['my_code'],
                task: task_data ? task_data.description : "タスクがありません",
                love_level: parseInt(currentLove),
                user_id: f.user_id,
                prev_params: f.prev_params,
                prev_output: f.prev_output
            };  
            // WebSocket経由で送信
            sendChatRequest(payload, function(err, data) {
                if (err) {
                    console.error("[MascotChat] 送信エラー:", err);
                    addMessage("エラー", "上手くお話出来ませんでした。", false);
                    tyrano.plugin.kag.ftag.startTag("chara_mod", {name:"mocha", face:"sad", time:200});
                } else {
                    applyAIResponse(data, false);
                }
                inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                sendButton.prop("disabled", false);
                inputField.css('height', '45px');
            });
        }   
        window.updateLoveGaugeUI = function() {
            if (typeof TYRANO.kag.stat.f === "undefined") return;

            var totalLove = parseInt(f.love_level) || 0;
            var thresholds = [1, 11, 26, 41, 71, 101]; 
            var currentLv = 1;
            var minLove = 0;
            var maxLove = 0;    
            for (var i = 0; i < thresholds.length - 1; i++) {
                if (totalLove >= thresholds[i]-1) {
                    currentLv = i + 1;
                    minLove = thresholds[i]-1;
                    maxLove = thresholds[i+1];
                }
            }   
            var percent = 0;
            var displayStr = "";

            if (currentLv <= 5) {
                var range = maxLove - minLove;
                var currentProgress = totalLove - minLove;  
                if (range > 0) {
                    percent = (currentProgress / range) * 100;
                } else {
                    percent = 100;
                }   
                displayStr = currentProgress + " / " + range;

                if (totalLove >= 100) {
                    displayStr = currentProgress + " (MAX)";
                    percent = 100;
                    $(".love-gauge-fill").css(
                        'background',
                        'linear-gradient(90deg, #fff197 0%, #fff12c 100%)'
                    );
                }
            }   
            var $container = $(".ai-chat-container");
            $container.find(".love-level-num").text(currentLv);
            $container.find(".love-gauge-fill").css("width", Math.min(100, Math.max(0, percent)) + "%");
            $container.find(".love-text").text(displayStr);

            if(currentLv >= 4) {
                $container.find(".love-icon").css("color", "#ff4757").css("text-shadow", "0 0 10px #ff4757");
            } else {
                $container.find(".love-icon").css("color", "#ff6b81").css("text-shadow", "none");
            }
        };  
        // グローバル関数として公開
        window.mascot_chat_save = function(callback) {
            var history = getHistory();
            tyrano.plugin.kag.ftag.startTag("chara_hide", {name:"mocha", time:200});

            if ($("#loading_overlay").length === 0) {
                $('body').append('<div id="loading_overlay" class="loading-overlay" style="display:none;"><div class="loader">Loading...</div></div>');
            }
            $("#loading_overlay").fadeIn(200);  
            if (!history || history.length === 0) {
                $("#loading_overlay").fadeOut(200);
                if (callback) callback();
                return;
            }

            alertify.log("学習記録を保存...");  
            var currentLove = TYRANO.kag.stat.f.love_level || 0;    
            fetch('/api/summarize', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    user_id: TYRANO.kag.stat.f.user_id,
                    chat_history: history,
                    current_love_level: parseInt(currentLove)
                })
            })
            .then(r => r.json())
            .then(data => {
                console.log("Save complete:", data);
                TYRANO.kag.stat.f.ai_chat_history = [];
                return fetch('/api/memory?user_id=' + TYRANO.kag.stat.f.user_id);
            })
            .then(r => r.json())
            .then(data => {
                if(data) TYRANO.kag.stat.f.ai_memory = data;
            })
            .catch(e => {
                console.error("Save Error:", e);
                alertify.error("保存に失敗しました");
            })
            .finally(() => {
                $("#loading_overlay").fadeOut(300, function() {
                    if (callback) callback();
                });
            });
        };  
        // ================================================================
        // mascot_chat_trigger: cpp_executorなど外部プラグインから呼び出される
        // WebSocket経由でAIに通知し、フィードバックを表示する
        // ================================================================
        window.mascot_chat_trigger = function(systemMessage, is_new_record=false) {
            if (typeof TYRANO.kag.stat.f === "undefined") return;
            var f = TYRANO.kag.stat.f;  
            var tasks = f.all_tasks;
            var current_id = f.current_task_id;
            var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
            var currentLove = f.love_level || 0;

            var messageToSend = "[SYSTEM] " + systemMessage;    
            // 入力UI を無効化
            var $input = $(".ai-chat-container").find(".ai-chat-input");
            $input.attr("placeholder", "考え中...").prop("disabled", true); 
            var payload = {
                character_id: "mocha",
                message: messageToSend, 
                code: f['my_code'],
                task: task_data ? task_data.description : "タスクがありません",
                love_level: parseInt(currentLove),
                user_id: f.user_id,
                prev_params: f.prev_params || { joy:0, anger:0, fear:0, trust:0, shy:0, surprise:0 },
                prev_output: f.prev_output || ""
            };  
            // WebSocket経由で送信
            sendChatRequest(payload, function(err, data) {
                if (err) {
                    console.error("[MascotChat] Triggerエラー:", err);
                } else {
                    applyAIResponse(data, true);
                }
                $input.prop("disabled", false).attr("placeholder", "メッセージを入力...");
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

    // --- 好感度保存関数 ---
    window.saveLoveLevelToSupabase = async function(newLevel) {
        if (!TYRANO.kag.stat.f.user_id || !window.sb) return;

        try {
            const { error } = await window.sb
                .from('profiles')
                .update({ love_level: newLevel, last_updated: new Date().toISOString() })
                .eq('id', TYRANO.kag.stat.f.user_id);

            if (error) {
                console.error("好感度の保存に失敗:", error);
            }
        } catch (e) {
            console.error("Supabase Error:", e);
        }
    };

    window.clearMascotChatHistory = function() {
        TYRANO.kag.stat.f.ai_chat_history = [];
    };
    [endscript]
[endmacro]
[return]
