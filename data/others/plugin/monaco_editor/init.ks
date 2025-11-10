; Monaco Editor プラグイン 本体 (Iframe版)

; [macro] Monaco Editorを表示する
[macro name="monaco_show"]

    ; 以前のIframeが残っていれば削除
    [iscript]
    $("#monaco-iframe-wrapper").remove();
    [endscript]

    ; Iframeを配置する
    @layopt layer=0 visible=true
    [html]
    <iframe id="monaco-iframe" name="monaco-iframe" style="border: none;"></iframe>
    [endhtml]

    ; Iframeのサイズと位置を設定
    [iscript]
    const iframe_wrapper = $("#monaco-iframe").parent();
    iframe_wrapper.attr('id', 'monaco-iframe-wrapper'); // 後で削除するためにIDを付与
    iframe_wrapper.css({
        "position": "absolute",
        "top":    mp.top    || "20px",
        "left":   mp.left   || "20px",
        "width":  mp.width  || "60%",
        "height": mp.height || "80%"
    });
    [endscript]

    ; Iframeを読み込み、エディタを初期化する
    [iscript]
    const iframe = document.getElementById('monaco-iframe');

    // IframeにサンドボックスHTMLを読み込ませる
    iframe.src = "./data/others/plugin/monaco_editor/monaco_sandbox.html";

    // Iframeの読み込み完了を待つ
    iframe.onload = () => {
        // Iframe内のエディタに初期コードを渡して初期化を命令
        const initial_code = eval(mp.storage);
        iframe.contentWindow.postMessage({
            command: 'init',
            data: { initial_code: initial_code }
        }, '*');
    };

    // Iframe内のエディタからコードの変更を受け取る
    window.addEventListener('message', (event) => {
        if (event.data.type === 'monaco_change') {
            const code = event.data.code;
            const storage_name = mp.storage.replace('f.', '');
            TYRANO.kag.stat.f[storage_name] = code;
        }
    });
    [endscript]

[endmacro]

; [macro] Monaco Editorを隠す
[macro name="monaco_hide"]
    [iscript]
    $("#monaco-iframe-wrapper").remove();
    [endscript]
[endmacro]

[macro name="monaco_editor_get_value"]

    ; [iscript] で Iframe に 'get_value' を命令
    [iscript]
        // 1. Iframe要素を取得
        console.log("Monaco Editor: コード取得開始");
        var iframe = document.getElementById('monaco-iframe');
        if (!iframe) {
            console.error("Monaco Editor (Iframe) が見つかりません。");
            TYRANO.kag.ftag.nextOrder();
        }else {
            var listener = function(event) {
                if (event.source !== iframe.contentWindow || !event.data.command) {
                    return;
                }

                if (event.data.command === 'return_value') {
                    // 変数に格納
                    var var_name = TYRANO.kag.stat.mp.variable;
                    if (var_name) {
                        var code = event.data.data.current_code;
                        console.log("Monaco Editor: 取得したコードを変数 '" + var_name + "' に格納します。", code);
                        TYRANO.kag.hbs.eval(var_name + " = " + JSON.stringify(code));
                    }
                    
                    // リスナーを解除
                    window.removeEventListener('message', listener);
                    
                    // [commit]タグ（[s]の代わり）を実行して、次の処理へ進む
                    console.log("Monaco Editor: コード取得完了");
                    TYRANO.kag.ftag.startTag("commit");
                }else {
                    console.warn("Monaco Editor: 不明なメッセージを受信しました。", event.data);
                }
                
            };
            // メッセージリスナーを登録
            window.addEventListener('message', listener);
            // Iframe に 'get_value' コマンドを送信
            iframe.contentWindow.postMessage({
                command: 'get_value'
            }, '*');
        }
        
    [endscript]

    [s]
[endmacro]

[return]