// mascot_chat.js
// init.ks の [iscript] から分離したロジック
// [loadjs] で読み込んだ後、[iscript] から initMascotChat() を呼び出す

window.initMascotChat = function() {
    // [iscript]内で自動注入されるティラノスクリプトのショートハンド変数を明示的に宣言
    var f  = TYRANO.kag.stat.f;
    var tf = TYRANO.kag.stat.tf;
    var sf = TYRANO.kag.stat.sf;
    if (window.AppProgressConfig) {
        window.AppProgressConfig.applyControlLoveLevel(f);
    }

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
        const chatWidth = scWidth * 0.30;
        const marginRight = scWidth * 0.02;
        const leftPosition = scWidth - chatWidth - marginRight;
        const chatHeight = scHeight * 0.95;
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

        // --- フォント・可読性設定 (TyranoScriptのCSS管理を迂回して直接注入) ---
        // <style>タグで !important 付きのルールを動的追加。
        // これなら動的に生成されるメッセージ要素にも自動適用される。
        var chatFontCSS = 
            '.ai-chat-container, ' +
            '.ai-chat-container *, ' +
            '.ai-chat-container textarea, ' +
            '.ai-chat-container button, ' +
            '.ai-chat-container input { ' +
            '  font-family: "BIZ UDPGothic", "MS PGothic", "Hiragino Kaku Gothic ProN", sans-serif !important; ' +
            '  font-weight: bold !important; ' +
            '  letter-spacing: 0.06em !important; ' +
            '  -webkit-font-smoothing: antialiased !important; ' +     /* Chrome/Safari/Edge */
            '  -moz-osx-font-smoothing: grayscale !important; ' +      /* macOS Firefox */
            '  text-rendering: optimizeLegibility !important; ' +      /* 全ブラウザ共通 */
            '} ' +
            '.ai-chat-container .ai-chat-message-simple { ' +
            '  line-height: 1.9 !important; ' +          /* 行間 */
            '  color: #1a1a1a !important; ' +            /* 文字色 */
            '  font-feature-settings: "palt" 1 !important; ' +  /* 日本語プロポーショナル */
            '} ' +
            '.ai-chat-container .ai-chat-message-simple pre, ' +
            '.ai-chat-container .ai-chat-message-simple pre code, ' +
            '.ai-chat-container .ai-chat-message-simple code { ' +
            '  font-family: Consolas, "Courier New", monospace !important; ' +
            '  font-weight: normal !important; ' +       /* コードはbold解除 */
            '  letter-spacing: 0 !important; ' +
            '}';
        if ($("#mascot-chat-font-override").length === 0) {
            $("head").append('<style id="mascot-chat-font-override">' + chatFontCSS + '</style>');
        }

        // --- UI要素 ---
        var liveChatView = container.find(".live-chat-view");
        var logView = container.find(".log-view-area");
        var aiMessagesContainer = container.find(".ai-chat-messages");
        var userMessagesContainer = container.find(".user-chat-messages");
        var inputField = container.find(".ai-chat-input");
        var sendButton = container.find(".ai-chat-send-button");
        var navPrev = container.find(".ai-chat-nav .ai-chat-prev");
        var navNext = container.find(".ai-chat-nav .ai-chat-next");
        var uid = f.user_id;    
        // --- 記憶ロード ---
        if (typeof f.ai_memory === "undefined") {
            f.ai_memory = { summary: "", learned_topics: [], weaknesses: [] };
        }
        fetch('/api/memory?user_id=' + uid)
            .then(r => r.ok ? r.json() : null)
            .then(data => {
                if(data){
                    TYRANO.kag.stat.f.ai_memory = data;
                    if(f.user_role=='experimental'&&data.love_level && !f.love_level){
                        f.love_level = data.love_level;
                    }
                    else if(f.user_role=='experimental'&&!f.love_level){
                        f.love_level = 0;
                    }

                    if(f.user_role=='control'){
                        if (window.AppProgressConfig && typeof window.AppProgressConfig.applyControlLoveLevel === "function") {
                            window.AppProgressConfig.applyControlLoveLevel(f);
                        } else {
                            f.love_level = 50;
                        }
                        var loveGaugeBox = container.find(".love-gauge-box");
                        loveGaugeBox.hide();
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
        var WS_URL = (location.protocol === "https:" ? "wss://" : "ws://") + location.host + "/api/chat/ws";
        var ws = null;
        var pendingCallback = null;  // 現在のリクエストに対するレスポンスハンドラ
        var pendingTimeout = null;   // タイムアウト用タイマー
        var requestQueue = [];       // リクエストキュー（競合防止）
        var isProcessing = false;    // 現在リクエスト処理中かどうか
        var reconnectAttempts = 0;
        var MAX_RECONNECT = 3;
        var WS_TIMEOUT_MS = 60000;   // 60秒タイムアウト（ストリーミング対応で延長）
        var pendingSystemTriggerCount = 0;
        var SAVE_TRIGGER_WAIT_MS = 3000;
        var streamAccumulated = "";  // ストリーミング中の蓄積テキスト
        var isStreaming = false;     // ストリーミング受信中フラグ

        function formatAiMessageForDisplay(message) {
            if (!message) return "";

            var normalized = message.replace(/\\n/g, '\n');
            var parts = normalized.split(/(```[\s\S]*?```)/g);

            return parts.map(function(part) {
                if (part.indexOf("```") === 0) {
                    return part;
                }
                return part.replace(/。(?!(\r?\n|$))/g, "。\n");
            }).join("");
        }

        // ストリーミングチャンク受信時の処理
        function handleStreamChunk(delta) {
            streamAccumulated += delta;

            // タイムアウトをリセット（データが来ているので延長）
            if (pendingTimeout) {
                clearTimeout(pendingTimeout);
                pendingTimeout = setTimeout(function() {
                    console.error("[MascotChat] ストリーミングタイムアウト");
                    pendingTimeout = null;
                    clearPending(new Error("タイムアウト: AIからの応答がありません"), null);
                }, WS_TIMEOUT_MS);
            }

            // 「考え中...」を消してストリーミングテキストを表示
            var displayText = formatAiMessageForDisplay(streamAccumulated);
            var messageHtml = DOMPurify.sanitize(marked.parse(displayText, { breaks: true }));
            aiMessagesContainer.html(
                '<div class="ai-chat-message-simple"><div class="message-body">' + messageHtml + '</div></div>'
            );
            aiMessagesContainer.scrollTop(0);

            if (!isStreaming) {
                isStreaming = true;
            }
        }

        // ペンディング状態をクリアするヘルパー
        function clearPending(err, data) {
            if (pendingTimeout) {
                clearTimeout(pendingTimeout);
                pendingTimeout = null;
            }
            // ストリーミングで蓄積したテキストを退避（doneのtextが空の時のフォールバック用）
            var fallbackText = streamAccumulated;
            // ストリーミング状態をリセット
            streamAccumulated = "";
            isStreaming = false;

            // done の text が空でストリーミングテキストがあればフォールバック
            if (data && !data.text && fallbackText) {
                data.text = fallbackText;
                console.warn("[MascotChat] done.text が空。ストリーミングテキストをフォールバック使用");
            }

            if (pendingCallback) {
                var cb = pendingCallback;
                pendingCallback = null;
                isProcessing = false;
                cb(err, data);
            } else {
                isProcessing = false;
            }
            // キューに次のリクエストがあれば処理
            processQueue();
        }

        // キューの次のリクエストを処理
        function processQueue() {
            if (isProcessing || requestQueue.length === 0) return;
            var next = requestQueue.shift();
            // キューから取り出した時点でUIを「考え中...」に戻す
            thinking();
            sendChatRequestInternal(next.payload, next.callback);
        }

        function connectWS() {
            if (ws && (ws.readyState === WebSocket.CONNECTING || ws.readyState === WebSocket.OPEN)) {
                return; // 既に接続中 or 接続済み
            }   
            ws = new WebSocket(WS_URL); 
            ws.onopen = function() {
                console.log("[MascotChat] WebSocket接続完了");
                reconnectAttempts = 0;
                // 接続完了後、キューに溜まったリクエストを処理
                processQueue();
            };  
            ws.onmessage = function(event) {
                try {
                    var data = JSON.parse(event.data);
                    if (data.type === "chunk") {
                        // ストリーミングチャンク: テキストを逐次表示
                        handleStreamChunk(data.delta || "");
                    } else if (data.type === "done") {
                        // ストリーミング完了: メタデータ込みの最終レスポンス
                        clearPending(null, data);
                    } else {
                        // レガシー形式 (HTTP fallback等): 一括レスポンス
                        clearPending(null, data);
                    }
                } catch(e) {
                    console.error("[MascotChat] WS onmessage JSONパース失敗:", e);
                    clearPending(e, null);
                }
            };  
            ws.onerror = function(e) {
                console.error("[MascotChat] WSエラー:", e);
                // oncloseも発火するので、ここではclearPendingしない
                // （二重コールバック防止）
            };  
            ws.onclose = function(event) {
                console.warn("[MascotChat] WS切断 (code=" + event.code + ")");
                ws = null;  
                // ペンディング中のコールバックがあればエラーを通知
                clearPending(new Error("WebSocket切断"), null);

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

        // 内部送信処理（直接呼ばない。sendChatRequest経由で使う）
        function sendChatRequestInternal(payload, callback) {
            isProcessing = true;

            // タイムアウト設定
            pendingTimeout = setTimeout(function() {
                console.error("[MascotChat] リクエストタイムアウト (" + WS_TIMEOUT_MS + "ms)");
                pendingTimeout = null;
                clearPending(new Error("タイムアウト: AIからの応答がありません"), null);
            }, WS_TIMEOUT_MS);

            // WSが開いていなければHTTP fallbackまたは再接続
            if (!ws || ws.readyState !== WebSocket.OPEN) {
                console.warn("[MascotChat] WS未接続。再接続してからリトライします");
                connectWS();
                // 接続完了を少し待ってリトライ (簡易版: 500ms後に1回だけ)
                setTimeout(function() {
                    if (ws && ws.readyState === WebSocket.OPEN) {
                        pendingCallback = callback;
                        try {
                            ws.send(JSON.stringify(payload));
                        } catch(e) {
                            console.error("[MascotChat] ws.send例外(リトライ):", e);
                            pendingCallback = null;
                            clearPending(new Error("WebSocket送信失敗: " + e.message), null);
                        }
                    } else {
                        // それでも繋がらなければHTTP fallbackへ
                        console.warn("[MascotChat] WSリトライ失敗。HTTP fallbackを使用");
                        fetch('/api/chat', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(payload)
                        })
                        .then(function(r) { return r.json(); })
                        .then(function(data) { clearPending(null, data); })
                        .catch(function(err) { clearPending(err, null); });
                    }
                }, 500);
                return;
            }   
            pendingCallback = callback;
            try {
                ws.send(JSON.stringify(payload));
            } catch(e) {
                console.error("[MascotChat] ws.send例外:", e);
                pendingCallback = null;
                clearPending(new Error("WebSocket送信失敗: " + e.message), null);
            }
        }

        // WS経由でAIにリクエストを送信し、コールバックでレスポンスを受け取るヘルパー
        // callback(error, data) 形式
        // 競合時はキューに入れて順番に処理する
        function sendChatRequest(payload, callback) {
            if (isProcessing) {
                console.log("[MascotChat] リクエスト処理中。キューに追加します");
                requestQueue.push({ payload: payload, callback: callback });
                return;
            }
            sendChatRequestInternal(payload, callback);
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
        function isUserHistoryItem(item) {
            return item && item.username === "あなた";
        }
        function buildHistoryTurns() {
            var history = getHistory();
            var turns = [];
            var pendingUser = null;

            history.forEach(function(item) {
                if (!item) return;
                if (isUserHistoryItem(item)) {
                    if (pendingUser) {
                        turns.push({ user: pendingUser, ai: null });
                    }
                    pendingUser = item;
                } else {
                    if (pendingUser) {
                        turns.push({ user: pendingUser, ai: item });
                        pendingUser = null;
                    } else {
                        turns.push({ user: null, ai: item });
                    }
                }
            });

            if (pendingUser) {
                turns.push({ user: pendingUser, ai: null });
            }
            return turns;
        }
        function showHistoryTurn(turn) {
            if (turn && turn.ai) {
                addMessage(turn.ai.username, turn.ai.message, true);
            } else {
                aiMessagesContainer.html("");
            }

            if (turn && turn.user) {
                addMessage(turn.user.username, turn.user.message, true);
            } else {
                userMessagesContainer.html("");
            }
        }
        function addMessage(username, message, is_history_load = false) {
            if (message) {
                message = message.replace(/\\n/g, '\n');
            }
            if (username !== "あなた") {
                message = formatAiMessageForDisplay(message);
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
            var turns = buildHistoryTurns();
            if (!turns[index]) return;

            liveChatView.show();
            logView.hide();
            container.find(".ai-chat-form").hide();
            showHistoryTurn(turns[index]);

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

            var turns = buildHistoryTurns();
            if (turns.length > 0) {
                showHistoryTurn(turns[turns.length - 1]);
            } else {
                addMessage("モカ", "何か質問……かな？", true);
                userMessagesContainer.html("");
            }
            navPrev.prop("disabled", turns.length === 0);
            navNext.prop("disabled", true); 
        }
        // ================================================================
        // AIレスポンス受信後の共通処理
        // ================================================================
        function createRequestId(prefix) {
            return prefix + "-" + Date.now() + "-" + Math.random().toString(36).slice(2);
        }

        function getCurrentLoveLevel(f) {
            if (f.user_role === "control") {
                if (window.AppProgressConfig && typeof window.AppProgressConfig.applyControlLoveLevel === "function") {
                    return window.AppProgressConfig.applyControlLoveLevel(f);
                }
                f.love_level = 50;
                return f.love_level;
            }
            return f.love_level || 0;
        }

        function applyAIResponse(data, isSystemTrigger, requestId, responseOptions) {
            responseOptions = responseOptions || {};
            var aiText = data.text || "";
            var emotion = data.emotion || "normal";
            var loveUpVal = parseInt(data.love_up) || 0;
            var f = TYRANO.kag.stat.f;
            var currentTaskId = f.current_task_id;
            var isClearedTask = !f.is_sandbox && currentTaskId && f.cleared_tasks && f.cleared_tasks[currentTaskId] === true;
            if (isClearedTask && loveUpVal !== 0) {
                console.log("[MascotChat] Cleared task love_up suppressed:", currentTaskId, loveUpVal);
                loveUpVal = 0;
            } else if (responseOptions.suppressPositiveLove === true && loveUpVal > 0) {
                console.log("[MascotChat] Positive love_up suppressed:", responseOptions.source || "system_trigger", loveUpVal);
                loveUpVal = 0;
            }

            var currentLove = Math.min(100, Math.max(0, parseInt(f.love_level) || 0));
            var nextLove = Math.min(100, Math.max(0, currentLove + loveUpVal));
            loveUpVal = nextLove - currentLove;
            f.love_level = currentLove;
            
            // 感情パラメータを保存
            if (data.parameters) {
                f.prev_params = data.parameters;
            }
            if (window.logExperimentEvent) {
                window.logExperimentEvent("chat_ai_response", {
                    request_id: requestId || "",
                    is_system_trigger: !!isSystemTrigger,
                    source: responseOptions.source || (isSystemTrigger ? "system_trigger" : "user_chat"),
                    text: aiText,
                    emotion: emotion,
                    love_up: loveUpVal,
                    parameters: data.parameters || null,
                    thought: data.thought || ""
                });
            }
            
            // 親密度変動（サンドボックスモードでは無効）
            if (f.user_role=='experimental'&&!f.is_sandbox && loveUpVal !== 0) {
                f.love_level = nextLove;
                if (window.logExperimentEvent) {
                    window.logExperimentEvent("love_change", {
                        request_id: requestId || "",
                        source: "ai_response",
                        delta: loveUpVal,
                        before: currentLove,
                        after: f.love_level
                    });
                }

                console.log("[MascotChat] 親密度変動:", loveUpVal);
                if (loveUpVal > 0) {
                    alertify.success("親密度UP!");
                } else {
                    alertify.error("親密度DOWN...");
                }
                if (window.saveLoveLevelToSupabase) {
                    window.saveLoveLevelToSupabase(f.love_level);
                }
                window.updateLoveGaugeUI();
            }
            
            addMessage("モカ", aiText, false);
            
            // emotion バリデーション: 存在しない表情IDは normal にフォールバック
            var validEmotions = [
                "normal", "happy", "sad", "surprise", "oko", "komari",
                "tere", "terekomari", "aseri", "doya", "huhun", "melt",
                "akire", "iya", "doubt", "nico", "hokkori", "thinking",
                "kowai", "donbiki", "frustration", "magao", "sorashi"
            ];
            if (validEmotions.indexOf(emotion) === -1) {
                console.warn("[MascotChat] 不正な emotion:", emotion, "→ normal にフォールバック");
                emotion = "normal";
            }
            
            tyrano.plugin.kag.ftag.startTag("chara_mod", {name:"mocha", face:emotion, time:200});
        }

        // AIレスポンス待ちUI
        function thinking() {
            var $input = $(".ai-chat-container").find(".ai-chat-input");
            $input.attr("placeholder", "考え中...").prop("disabled", true);
            sendButton.prop("disabled", true);
            aiMessagesContainer.html('<div class="thinking-indicator">...</div>');
            aiMessagesContainer.scrollTop(0);
            tyrano.plugin.kag.ftag.startTag("chara_mod", {name:"mocha", face:"thinking", time:200});
        }
        // ================================================================
        // 送信処理 (ユーザー入力)
        // ================================================================
        function sendMessage() {
            var $input = $(".ai-chat-container").find(".ai-chat-input");
            if (getTfLogIndex() !== -1) { 
                restoreLiveChatView();
            }   
            if (typeof TYRANO.kag.stat.f === "undefined") {
                console.error("TYRANO.kag.stat.f が undefined です。");
                addMessage("エラー", "システムが準備中です。", true);
                return;
            }

            var f = TYRANO.kag.stat.f;
            var userMessage = $input.val().trim();
            if (userMessage === "") return;

            addMessage("あなた", userMessage, false);
            
            $input.val("").css('height', '45px');
            // 考え中
            thinking();
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
            var currentLove = getCurrentLoveLevel(f);
            var messageToSend = userMessage + historyContext + memoryContext;   
            var requestId = createRequestId("chat");
            var payload = {
                character_id: "mocha",
                message: messageToSend, 
                code: f['my_code'],
                task: window.buildEditorTaskContext ? window.buildEditorTaskContext(task_data) : (task_data ? task_data.description : "タスクがありません"),
                love_level: parseInt(currentLove),
                user_id: f.user_id,
                prev_params: f.prev_params,
                prev_output: f.prev_output,
                request_id: requestId
            };  
            if (window.logExperimentEvent) {
                window.logExperimentEvent("chat_user_payload", {
                    request_id: requestId,
                    source: "user_chat",
                    payload: payload
                });
            }
            // WebSocket経由で送信
            sendChatRequest(payload, function(err, data) {
                if (err) {
                    console.error("[MascotChat] 送信エラー:", err);
                    if (window.logExperimentEvent) {
                        window.logExperimentEvent("chat_ai_response", {
                            request_id: requestId,
                            source: "user_chat",
                            error: true,
                            message: err.message || String(err)
                        });
                    }
                    addMessage("エラー", "上手くお話出来ませんでした。", false);
                    tyrano.plugin.kag.ftag.startTag("chara_mod", {name:"mocha", face:"sad", time:200});
                } else {
                    applyAIResponse(data, false, requestId);
                }
                var $input = $(".ai-chat-container").find(".ai-chat-input");
                $input.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                sendButton.prop("disabled", false);
                $input.css('height', '45px');
            });
        }   
        window.updateLoveGaugeUI = function() {
            if (typeof TYRANO.kag.stat.f === "undefined") return;

            var totalLove = parseInt(f.love_level) || 0;
            var gaugeState = window.AppProgressConfig && typeof window.AppProgressConfig.getLoveGaugeState === "function"
                ? window.AppProgressConfig.getLoveGaugeState(totalLove)
                : { level: 1, percent: 0, displayStr: totalLove + " / 100" };
            var currentLv = gaugeState.level;
            
           var prevLv = window._mascot_prev_lv || 1;
            if (currentLv > prevLv) {
                var $gauge = $(".love-gauge-box");
                $gauge.removeClass("lv-up-glow");
                void $gauge[0].offsetWidth;
                $gauge.addClass("lv-up-glow");
            }
            window._mascot_prev_lv = currentLv;

            if (totalLove >= 100) {
                $(".love-gauge-fill").css(
                    'background',
                    'linear-gradient(90deg, #fff197 0%, #fff12c 100%)'
                );
            }   
            var $container = $(".ai-chat-container");
            $container.find(".love-level-num").text(currentLv);
            $container.find(".love-gauge-fill").css("width", gaugeState.percent + "%");
            $container.find(".love-text").text(gaugeState.displayStr);

            if(currentLv >= 4) {
                $container.find(".love-icon").css("color", "#ff4757").css("text-shadow", "0 0 10px #ff4757");
            } else {
                $container.find(".love-icon").css("color", "#ff6b81").css("text-shadow", "none");
            }
        };  
        function waitForSystemTriggers(done) {
            var startedAt = Date.now();
            function check() {
                if (pendingSystemTriggerCount <= 0 || Date.now() - startedAt >= SAVE_TRIGGER_WAIT_MS) {
                    if (pendingSystemTriggerCount > 0) {
                        console.warn("[MascotChat] Save continued with pending system triggers:", pendingSystemTriggerCount);
                    }
                    done();
                    return;
                }
                setTimeout(check, 100);
            }
            check();
        }

        // グローバル関数として公開
        window.mascot_chat_save = function(callback) {
            tyrano.plugin.kag.ftag.startTag("chara_hide", {name:"mocha", time:200});

            if ($("#loading_overlay").length === 0) {
                $('body').append('<div id="loading_overlay" class="loading-overlay" style="display:none;"><div class="loader">Loading...</div></div>');
            }
            $("#loading_overlay").fadeIn(200);  

            waitForSystemTriggers(function() {
                var history = getHistory();
                if (!history || history.length === 0) {
                    $("#loading_overlay").fadeOut(200);
                    if (callback) callback();
                    return;
                }

                alertify.log("学習記録を保存...");  
                var currentLove = f.love_level || 0;    
                function parseJsonResponse(response) {
                    return response.text().then(function(text) {
                        var contentType = response.headers.get("content-type") || "";
                        if (!response.ok) {
                            throw new Error("HTTP " + response.status + ": " + (text || response.statusText));
                        }
                        if (!text) {
                            return {};
                        }
                        var trimmed = text.trim();
                        var looksLikeJson = trimmed.charAt(0) === "{" || trimmed.charAt(0) === "[";
                        if (contentType.indexOf("application/json") === -1 && !looksLikeJson) {
                            throw new Error("Unexpected response: " + text.slice(0, 120));
                        }
                        return JSON.parse(trimmed);
                    });
                }
                fetch('/api/summarize', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        user_id: f.user_id,
                        chat_history: history,
                        current_love_level: parseInt(currentLove)
                    })
                })
                .then(parseJsonResponse)
                .then(data => {
                    console.log("Save complete:", data);
                    f.ai_chat_history = [];
                    return fetch('/api/memory?user_id=' + f.user_id);
                })
                .then(function(response) {
                    if (!response.ok) {
                        console.warn("Memory reload after save failed:", response.status, response.statusText);
                        return null;
                    }
                    return parseJsonResponse(response);
                })
                .then(data => {
                    if(data) f.ai_memory = data;
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
            });
        };  
        // ================================================================
        // mascot_chat_trigger: cpp_executorなど外部プラグインから呼び出される
        // WebSocket経由でAIに通知し、フィードバックを表示する
        // ================================================================
        window.mascot_chat_trigger = function(systemMessage, is_new_record=false, callback, responseOptions) {
            responseOptions = responseOptions || {};
            if (typeof TYRANO.kag.stat.f === "undefined") return;
            var f = TYRANO.kag.stat.f;  
            var tasks = f.all_tasks;
            var current_id = f.current_task_id;
            var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
            var currentLove = getCurrentLoveLevel(f);

            var messageToSend = "[SYSTEM] " + systemMessage;    
            var requestId = createRequestId("system");
            pendingSystemTriggerCount++;
            // 入力UI を無効化
            var $input = $(".ai-chat-container").find(".ai-chat-input");
            
            thinking();
            
            var payload = {
                character_id: "mocha",
                message: messageToSend, 
                code: f['my_code'],
                task: window.buildEditorTaskContext ? window.buildEditorTaskContext(task_data) : (task_data ? task_data.description : "タスクがありません"),
                love_level: parseInt(currentLove),
                user_id: f.user_id,
                prev_params: f.prev_params || { joy:0, anger:0, fear:0, trust:0, shy:0, surprise:0 },
                prev_output: f.prev_output || "",
                request_id: requestId
            };  
            if (window.logExperimentEvent) {
                window.logExperimentEvent("chat_user_payload", {
                    request_id: requestId,
                    source: "system_trigger",
                    system_message: systemMessage,
                    payload: payload
                });
            }
            // WebSocket経由で送信
            sendChatRequest(payload, function(err, data) {
                try {
                    if (err) {
                        console.error("[MascotChat] Triggerエラー:", err);
                        if (window.logExperimentEvent) {
                            window.logExperimentEvent("chat_ai_response", {
                                request_id: requestId,
                                source: "system_trigger",
                                error: true,
                                message: err.message || String(err)
                            });
                        }
                        // エラー時もUIを更新して「考え中...」のまま止まるのを防ぐ
                        addMessage("モカ", "ごめんね、うまく応答できなかったみたい…もう一度試してみてね。", false);
                        tyrano.plugin.kag.ftag.startTag("chara_mod", {name:"mocha", face:"sad", time:200});
                    } else {
                        applyAIResponse(data, true, requestId, responseOptions);
                    }
                    
                    $input.prop("disabled", false).attr("placeholder", "メッセージを入力...");
                    sendButton.prop("disabled", false);
                } finally {
                    pendingSystemTriggerCount = Math.max(0, pendingSystemTriggerCount - 1);
                    if (typeof callback === "function") callback(err, data, requestId);
                }
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
            var turns = buildHistoryTurns(); 
            if (turns.length === 0) return;
            var currentLogIndex = getTfLogIndex();

            if (currentLogIndex === -1) {
                currentLogIndex = turns.length - 1;
            } else if (currentLogIndex >= 0) {
                currentLogIndex -= 1;
            }
            if (currentLogIndex < 0) currentLogIndex = 0;
            TYRANO.kag.stat.tf.ai_chat_log_index = currentLogIndex;
            showLogMessage(currentLogIndex);
        });

        navNext.on("click", function() {
            var currentLogIndex = getTfLogIndex();
            if (currentLogIndex === -1) return; 

            var turns = buildHistoryTurns(); 
            var nextLogIndex = currentLogIndex + 1;

            if (nextLogIndex < turns.length) {
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

    // --- 親密度保存関数 ---
    window.saveLoveLevelToSupabase = async function(newLevel) {
        if (!TYRANO.kag.stat.f.user_id || !window.sb) return;

        try {
            const { error } = await window.sb
                .from('profiles')
                .update({ love_level: newLevel, last_updated: new Date().toISOString() })
                .eq('id', TYRANO.kag.stat.f.user_id);

            if (error) {
                console.error("親密度の保存に失敗:", error);
            }
        } catch (e) {
            console.error("Supabase Error:", e);
        }
    };

    window.clearMascotChatHistory = function() {
        TYRANO.kag.stat.f.ai_chat_history = [];
    };
};
