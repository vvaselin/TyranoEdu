; ライブラリの読み込み（他で読み込んでいる場合は省略可ですが、念のため記述）
[loadjs storage="./data/others/js/marked.min.js"]
[loadjs storage="./data/others/js/purify.min.js"]
[loadcss file="./data/others/plugin/doc_viewer/style.css"]

; UI構築マクロ
[macro name="show_doc_button"]

    ; UIパーツをHTMLで定義
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
    // 変数定義
    var btn = $(".doc-viewer-btn");
    var panel = $(".doc-panel");
    var closeBtn = $(".doc-close-btn");
    var contentArea = $("#doc_content_area");
    
    // fixレイヤーへ移動（画面上に常駐させるため）
    var fix_layer = $(".fixlayer").last();
    $(".doc-viewer-container").appendTo(fix_layer);

    // イベント設定: 開く
    btn.on("click", function() {
        panel.addClass("active");
        btn.hide(); // 開いている間はボタンを隠す
    });

    // イベント設定: 閉じる
    closeBtn.on("click", function() {
        panel.removeClass("active");
        btn.fadeIn();
    });

    // Markdownファイルの読み込み関数
    // 引数 file: docsフォルダ内のファイル名
    TYRANO.kag.stat.f.loadDocMarkdown = function(file) {
        var filePath = "./data/others/plugin/doc_viewer/docs/" + file;
        
        $.get(filePath, function(data) {
            // Marked.jsでパースし、Purifyでサニタイズ
            var html = DOMPurify.sanitize(marked.parse(data));
            contentArea.html(html);
        })
        .fail(function() {
            contentArea.html("<p>資料の読み込みに失敗しました。</p>");
        });
    };

    // 初期表示ファイルの指定（mp.fileがあればそれを、なければデフォルト）
    var initialFile = mp.file || "sample.md";
    TYRANO.kag.stat.f.loadDocMarkdown(initialFile);

    [endscript]

[endmacro]

; ボタンなどを消去するマクロ
[macro name="hide_doc_button"]
    [iscript]
    $(".doc-viewer-container").remove();
    [endscript]
[endmacro]

[return]