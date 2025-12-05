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

    // 初期化：確実にクラスを外して隠す
    panel.removeClass("active");
    btn.show();

    // イベント設定: 開く
    btn.on("click", function() {
        panel.addClass("active");
        // ボタンを隠す（右へスライドアウトさせるようなアニメーションも可）
        // ここではシンプルにフェードアウトさせます
        btn.fadeOut(200);
    });

    // イベント設定: 閉じる
    closeBtn.on("click", function() {
        panel.removeClass("active");
        // 閉じた少し後にボタンを再表示
        setTimeout(function(){
            btn.fadeIn(200);
        }, 300);
    });

    // 読み込み関数
    TYRANO.kag.stat.f.loadDocMarkdown = function(file) {
        var filePath = "./data/others/plugin/doc_viewer/docs/" + file;
        $.get(filePath, function(data) {
            var html = DOMPurify.sanitize(marked.parse(data));
            contentArea.html(html);
        })
        .fail(function() {
            contentArea.html("<p>資料の読み込みに失敗しました。<br>" + filePath + "</p>");
        });
    };

    // 引数で指定されたファイルを読み込む
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