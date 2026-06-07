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
    iframe.src = "./data/others/plugin/monaco_editor/monaco_sandbox.html?t=" + Date.now();

    // Iframeの読み込み完了を待つ
    iframe.onload = () => {
        // Iframe内のエディタに初期コードを渡して初期化を命令
        const initial_code = eval(mp.storage);
        iframe.contentWindow.postMessage({
            command: 'init',
            data: {
                initial_code: initial_code,
                language: mp.language || 'cpp'
            }
        }, '*');
    };

    // Iframe内のエディタからコードの変更を受け取る
    if (window._monacoExperimentLogTimer) {
        clearTimeout(window._monacoExperimentLogTimer);
        window._monacoExperimentLogTimer = null;
    }
    window._monacoLastLoggedCode = null;
    if (window._monacoMessageHandler) {
        window.removeEventListener('message', window._monacoMessageHandler);
    }

    window._monacoMessageHandler = (event) => {
        if (event.data.type === 'monaco_change') {
            const code = event.data.code;
            const storage_name = mp.storage.replace('f.', '');
            TYRANO.kag.stat.f[storage_name] = code;
            if (window.logExperimentEvent) {
                clearTimeout(window._monacoExperimentLogTimer);
                window._monacoExperimentLogTimer = setTimeout(function() {
                    if (window._monacoLastLoggedCode === code) return;
                    window._monacoLastLoggedCode = code;
                    window.logExperimentEvent("code_snapshot", {
                        reason: "idle_snapshot",
                        code: code,
                        length: code.length
                    });
                }, 3000);
            }
        }
    };
    window.addEventListener('message', window._monacoMessageHandler);
    [endscript]

[endmacro]

; [macro] Monaco Editorを隠す
[macro name="monaco_hide"]
    [iscript]
    $("#monaco-iframe-wrapper").remove();
    [endscript]
[endmacro]

[return]
