[loadjs storage="./data/others/js/marked.min.js"]
[loadjs storage="./data/others/js/purify.min.js"]
[loadcss file="./data/others/plugin/doc_viewer/style.css"]

[macro name="show_doc_button"]

    [html]
    <div class="doc-viewer-container">
        <div class="doc-viewer-btn" id="open_doc_btn">
            <span class="doc-btn-text">資料</span>
        </div>

        <div class="doc-panel" id="doc_panel">
            <div class="doc-header">
                <span class="doc-title">学習資料</span>
                <button class="doc-close-btn" id="close_doc_btn">×</button>
            </div>
            <div class="doc-content" id="doc_content_area">
                <p>読み込み中...</p>
            </div>
        </div>
    </div>
    [endhtml]

    [iscript]
    var container = $(".doc-viewer-container");
    
    // 既存のコンテナがあれば削除（重複防止）
    $(".doc-viewer-container").not(container).remove();

    var btn = container.find("#open_doc_btn");
    var panel = container.find("#doc_panel");
    var closeBtn = container.find("#close_doc_btn");
    var contentArea = container.find("#doc_content_area");
    
    // fixレイヤーへ移動
    var fix_layer = $(".fixlayer").last();
    container.appendTo(fix_layer);

    // 初期化
    panel.removeClass("active");
    btn.show();

    // --- イベント設定 ---

    // 開く
    btn.on("click", function() {
        panel.addClass("active");
        btn.fadeOut(200);
    });

    // 閉じる
    closeBtn.on("click", function() {
        panel.removeClass("active");
        setTimeout(function(){
            btn.fadeIn(200);
        }, 300);
    });

    // ★追加：Markdown内のリンクをクリックした時の処理
    contentArea.on("click", "a", function(e) {
        var href = $(this).attr("href");

        // ".md" で終わるリンクの場合だけ、内部移動として処理する
        if (href && href.indexOf(".md") !== -1) {
            e.preventDefault(); // 通常のリンク動作（画面遷移）をキャンセル
            TYRANO.kag.stat.f.loadDocMarkdown(href); // 指定されたmdファイルを読み込む
        }
        // httpなどで始まる外部リンクは、そのまま（別窓などで）開く
        else if (href && (href.indexOf("http") === 0)) {
            e.preventDefault();
            require('electron').shell.openExternal(href); // PCアプリ版の場合
            // ブラウザ版なら window.open(href, '_blank');
        }
    });

    // 読み込み関数
    TYRANO.kag.stat.f.loadDocMarkdown = function(file) {
        // パスが "http" 等で始まらない場合、フォルダパスを補完
        var filePath = file;
        if (file.indexOf("http") === -1 && file.indexOf("./") === -1) {
             filePath = "./data/others/plugin/doc_viewer/docs/" + file;
        }

        $.ajax({
            url: filePath,
            cache: false, // ★重要：これでキャッシュを無効化（URL末尾に自動でタイムスタンプが付与されます）
            success: function(data) {
                var html = DOMPurify.sanitize(marked.parse(data));
                contentArea.html(html);
                contentArea.scrollTop(0);
            },
            error: function() {
                contentArea.html("<p>読み込みエラー：<br>" + filePath + "</p>");
            }
        });
    };

    // 初期ファイル読み込み
    var initialFile = mp.file || "sample.md";
    TYRANO.kag.stat.f.loadDocMarkdown(initialFile);

    [endscript]

[endmacro]

[macro name="hide_doc_button"]
    [iscript]
    $(".doc-viewer-container").remove();
    [endscript]
[endmacro]

[return]