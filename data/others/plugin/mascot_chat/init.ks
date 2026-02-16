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
                        // サーバーの好感度とクライアントの好感度を同期（必要に応じて）
                        if(data.love_level && !TYRANO.kag.stat.f.love_level){
                             TYRANO.kag.stat.f.love_level = data.love_level;
                        }

                        window.updateLoveGaugeUI();
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
                
                var messageToSend = userMessage + historyContext + memoryContext;

                fetch('/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        character_id: "mocha",
                        message: messageToSend, 
                        code: f['my_code'],
                        task: task_data ? task_data.description : "タスクがありません",
                        love_level:parseInt(currentLove),
                        user_id: TYRANO.kag.stat.f.user_id,
                        prev_params: TYRANO.kag.stat.f.prev_params,
                        prev_output: TYRANO.kag.stat.f.prev_output
                    }),
                })
                .then(r => r.json())
                .then(data => {
                    var aiText = data.text;
                    var emotion = data.emotion || "normal";
                    var loveUpVal = parseInt(data.love_up) || 0; 

                    // 前回の感情パラメータと出力を保存
                    if (data.parameters) {
                        TYRANO.kag.stat.f.prev_params = data.parameters;
                    }

                    // 前回クリア済みかどうか
                    var AlreadyCleared = TYRANO.kag.stat.f.cleared_tasks[TYRANO.kag.stat.f.current_task_id];

                    // サンドボックスモードでは好感度変動を無効化
                    if (!TYRANO.kag.stat.f.is_sandbox&&loveUpVal !== 0) {
                        var current = parseInt(f.love_level) || 0;
                        f.love_level = current + loveUpVal; 
                        if(f.love_level < 0) f.love_level = 0;
                        if(f.love_level > 100) f.love_level = 100;
                        
                        console.error(`好感度 ${loveUpVal} 、 現在: ${f.love_level}`);
                        if(loveUpVal > 0){
                            alertify.success("好感度UP! 現在："+f.love_level);
                        } else {
                            alertify.error("好感度DOWN... 現在："+f.love_level);
                        }

                        if (window.saveLoveLevelToSupabase) {
                            window.saveLoveLevelToSupabase(f.love_level);
                        }

                        window.updateLoveGaugeUI();
                    }
                    
                    addMessage("モカ", aiText, false);
                    var emotion = data.emotion || "normal";
                    tyrano.plugin.kag.ftag.startTag("chara_mod", {name:"mocha", face:emotion, time:200});
                })
                .catch(error => {
                    console.error("AIチャットエラー:", error);
                    addMessage("エラー", "上手くお話出来ませんでした。", false);
                    tyrano.plugin.kag.ftag.startTag("chara_mod", {name:"mocha", face:"sad", time:200});
                })
                .finally(() => {
                    inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                    sendButton.prop("disabled", false);
                    inputField.css('height', '45px');
                });
            }

            window.updateLoveGaugeUI = function() {
                if (typeof TYRANO.kag.stat.f === "undefined") return;
                
                // 現在の総親密度
                var totalLove = parseInt(TYRANO.kag.stat.f.love_level) || 0;
                
                // レベル境界値（サーバー側の判定ロジックと同期）
                var thresholds = [0, 11, 26, 41, 71, 100]; 
                var currentLv = 1;
                var minLove = 0;
                var maxLove = 16;

                // 現在のレベルを判定
                for (var i = 0; i < thresholds.length - 1; i++) {
                    if (totalLove >= thresholds[i]) {
                        currentLv = i + 1;
                        minLove = thresholds[i];
                        maxLove = thresholds[i+1]-1;
                    }
                }

                // レベル内での進捗率計算
                var percent = 0;
                var displayStr = "";
                
                // Lv.5 (71以上) の場合も同様に 71~100 の間で計算
                if (currentLv <= 5) {
                    // 分母が0にならないようチェック（100-100など）
                    var range = maxLove - minLove;
                    if (range > 0) {
                        percent = ((totalLove - minLove) / range) * 100;
                    } else {
                        percent = 100;
                    }

                    displayStr = totalLove + " / " + maxLove;
                    
                    if (totalLove >= 100) {
                        displayStr = totalLove + " (MAX)";
                        percent = 100;
                    }
                }

                // UIへの反映（コンテナ内から確実に探す）
                var $container = $(".ai-chat-container");
                $container.find(".love-level-num").text(currentLv);
                $container.find(".love-gauge-fill").css("width", Math.min(100, Math.max(0, percent)) + "%");
                $container.find(".love-text").text(displayStr);
                
                // アイコンの色演出
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
                
                // ▼▼▼ ローディング表示 ▼▼▼
                if ($("#loading_overlay").length === 0) {
                    $('body').append('<div id="loading_overlay" class="loading-overlay" style="display:none;"><div class="loader">Loading...</div></div>');
                }
                $("#loading_overlay").fadeIn(200);

                if (!history || history.length === 0) {
                    $("#loading_overlay").fadeOut(200); // 履歴なしなら即消す
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
                    // 必要なら最新記憶をロード
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

            // window.mascot_chat_trigger としてグローバル公開
            window.mascot_chat_trigger = function(systemMessage, is_new_record=false) {
                // 必須チェック
                if (typeof TYRANO.kag.stat.f === "undefined") return;
                var f = TYRANO.kag.stat.f;

                var tasks = f.all_tasks;
                var current_id = f.current_task_id;
                var task_data = (tasks && tasks[current_id]) ? tasks[current_id] : null;
                var currentLove = f.love_level || 0;
                
                // システム通知であることを明示するプレフィックスを付ける
                var messageToSend = "[SYSTEM] " + systemMessage;

                // AIチャット中状態にする（入力無効化など）
                var container = $(".ai-chat-container");
                var inputField = container.find(".ai-chat-input");
                inputField.attr("placeholder", "考え中...").prop("disabled", true);

                var lastEmotionParams = { joy: 0, anger: 0, fear: 0, trust: 0, shy: 0, surprise: 0 };
                var lastExecOutput = "";

                // APIコール
                fetch('/api/chat', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ 
                        character_id: "mocha",
                        message: messageToSend, 
                        code: f['my_code'],
                        task: task_data ? task_data.description : "タスクがありません",
                        love_level:parseInt(currentLove),
                        user_id: TYRANO.kag.stat.f.user_id,
                        prev_params: lastEmotionParams,
                        prev_output: lastExecOutput
                    }),
                })
                .then(r => r.json())
                .then(data => {
                    var aiText = data.text;
                    var emotion = data.emotion || "normal";
                    var loveUpVal = parseInt(data.love_up) || 0; 

                    // 前回の感情パラメータと出力を保存
                    if (data.parameters) {
                        TYRANO.kag.stat.f.prev_params = data.parameters;
                    }

                    // サンドボックスモードでは好感度変動を無効化
                    if (!TYRANO.kag.stat.f.is_sandbox&&loveUpVal !== 0) {
                        var current = parseInt(f.love_level) || 0;
                        f.love_level = current + loveUpVal; 
                        if(f.love_level < 0) f.love_level = 0;
                        if(f.love_level > 100) f.love_level = 100;
                        
                        console.error(`好感度 ${loveUpVal} 、 現在: ${f.love_level}`);
                        if(loveUpVal > 0){
                            alertify.success("好感度UP! 現在："+f.love_level);
                        } else {
                            alertify.error("好感度DOWN... 現在："+f.love_level);
                        }

                        if (window.saveLoveLevelToSupabase) {
                            window.saveLoveLevelToSupabase(f.love_level);
                        }

                        window.updateLoveGaugeUI();
                    }

                    // メッセージ表示
                    addMessage("モカ", aiText, false);

                    // 表情変更
                    var emotion = data.emotion || "normal";
                    tyrano.plugin.kag.ftag.startTag("chara_mod", {name:"mocha", face:emotion, time:200});
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

    // --- 好感度保存関数 ---
    window.saveLoveLevelToSupabase = async function(newLevel) {
        // ユーザーIDがない、またはSupabaseが初期化されていない場合は何もしない
        if (!TYRANO.kag.stat.f.user_id || !window.sb) return;

        try {
            const { error } = await window.sb
                .from('profiles')
                .update({ love_level: newLevel, last_updated: new Date().toISOString() })
                .eq('id', TYRANO.kag.stat.f.user_id);

            if (error) {
                console.error("好感度の保存に失敗:", error);
            } else {
                //console.error("好感度を保存しました:", newLevel);
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