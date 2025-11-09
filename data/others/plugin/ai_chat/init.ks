; AIチャットプラグイン 本体

; [macro] AIチャットUIを表示するマクロ
[macro name="ai_chat_show"]

    ; 1. 必要なCSSを読み込む
    [loadcss file="./data/others/plugin/ai_chat/ai_chat.css"]
    [loadjs storage="./data/others/js/marked.min.js"] 
    [loadjs storage="./data/others/js/purify.min.js"] 

    ; 2. [html]タグでUIの骨格を生成する
    ; この時点では通常レイヤーに一時的に配置される
    [html]
    <div class="ai-chat-container" style="display:none;">
        <div class="ai-chat-messages">
            <div class="ai-chat-message">
                <img src="./data/fgimage/chat/akane/egao.png" class="avatar">
                <div class="message-content">
                    <span class="username">あかね</span>
                    <span>何が聞きたいの？</span>
                </div>
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
        var chat_container = $(".ai-chat-container");
        var fix_layer = $(".fixlayer").first();
        fix_layer.append(chat_container); 

        // JavaScriptでUIの位置とサイズを「ピクセル単位」で明示的に設定する

        const scWidth = parseInt(TYRANO.kag.config.scWidth);
        const scHeight = parseInt(TYRANO.kag.config.scHeight); 

        const chatWidth = scWidth * 0.35;
        const marginRight = scWidth * 0.01;
        const leftPosition = scWidth - chatWidth - marginRight;
        
        const chatHeight = scHeight * 0.90; 

        chat_container.css({
            "position": "absolute",
            "top": "2%",
            "left": leftPosition + "px",
            "width": chatWidth + "px",
            "height": chatHeight + "px",
            "z-index": "200"
        });

        const formHeight = 75;
        const messagesHeight = chatHeight - formHeight;

        const messagesArea = $(".ai-chat-messages");
        const formArea = $(".ai-chat-form");
        
        messagesArea.css("height", messagesHeight + "px");
        formArea.css("height", formHeight + "px");

        chat_container.show();

        const inputField = $(".ai-chat-input");
        const sendButton = $(".ai-chat-send-button"); // ボタン要素を取得
        const messagesContainer = $(".ai-chat-messages");
        
        function addMessage(sender, text, avatar) {
            const cleanHtml = DOMPurify.sanitize(marked.parse(text));
            const messageHTML = `
                <div class="ai-chat-message">
                    <img src="${avatar}" class="avatar">
                    <div class="message-content">
                        <span class="username">${sender}</span>
                        <span>${cleanHtml}</span>
                    </div>
                </div>`;
                
            const messageElement = $(messageHTML);

            messageElement.find("pre").each(function () {
                const preBlock = $(this);
                
                // コピーボタンのHTML要素を作成します
                const copyButton = $('<button class="copy-code-button">コピー</button>');
                
                // ボタンを<pre>タグの「中」に追加します
                preBlock.append(copyButton);

                // 作成したボタンにだけ、クリックイベントを設定します
                copyButton.on("click", function (e) {
                    // ティラノスクリプトへのクリックイベント伝播を、必ず止めます
                    e.stopPropagation();
                    
                    // コピー処理：ボタン自身のテキストを含めないように、
                    // pre要素を複製して、そこからボタンを削除したもののテキストを取得します。
                    const preClone = preBlock.clone();
                    preClone.find('.copy-code-button').remove();
                    const codeText = preClone.text();
                    
                    navigator.clipboard.writeText(codeText).then(
                        () => {
                            alertify.success("チャットのコードをコピー");
                        },
                        (err) => {
                            alertify.error("コピーに失敗しました");
                        }
                    );
                });
            });
            
            messagesContainer.append(messageElement);
            messagesContainer.scrollTop(messagesContainer[0].scrollHeight);
        }

        // メッセージ送信処理を関数にまとめる
        function sendMessage() {
            const userMessage = inputField.val().trim();
            if (userMessage === "") {
                return; // 空の場合は何もしない
            }

            // ユーザーのメッセージを表示
            addMessage("あなた", userMessage, "./data/fgimage/chat/akane/normal.png");
            inputField.val("");
            inputField.prop("disabled", true).attr("placeholder", "AIの応答を待っています...");
            sendButton.prop("disabled", true);

            // AIサーバーとの通信処理
            fetch('/api/chat', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: userMessage }),
            })
            .then(response => response.ok ? response.json() : response.text().then(text => { throw new Error(text) }))
            .then(data => {
                addMessage("あかね", data.text, "./data/fgimage/chat/akane/hirameki.png");
            })
            .catch(error => {
                console.error("AIチャットエラー:", error);
                addMessage("エラー", "AIとの通信に失敗しました。", "./data/fgimage/chat/akane/naki.png");
            })
            .finally(() => {
                // 入力欄とボタンを元に戻す
                inputField.prop("disabled", false).attr("placeholder", "メッセージを入力...").focus();
                sendButton.prop("disabled", false);
            });
        }

        // イベントリスナーを設定
        sendButton.on("click", sendMessage); 
        inputField.on("keydown", function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault(); 
                sendMessage();
            }
        });

        inputField.on('input', function() {
            this.style.height = 'auto'; // 高さを一旦リセット
            this.style.height = (this.scrollHeight) + 'px'; // 内容の高さに合わせて自身の高さを変更
        });
    [endscript]

[endmacro]

[return]