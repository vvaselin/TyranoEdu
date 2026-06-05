[macro name="mascot_chat_show"]

    ; --- 依存ファイルの読み込み ---
    [loadcss file="./data/others/plugin/mascot_chat/mascot.css?v=2"]
    [loadjs storage="./data/others/js/marked.min.js"]
    [loadjs storage="./data/others/js/purify.min.js"]
    [loadjs storage="./data/others/plugin/mascot_chat/mascot_chat.js"]

    [chara_show name="mocha" left=960  width=430 top =420]

    ; --- UI骨格の生成 ---
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

    ; --- 初期化実行 ---
    [iscript]
    window.initMascotChat();
    [endscript]

[endmacro]
[return]
