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
                <div class="doc-hamburger" id="doc_hamburger">≡</div>
                <span class="doc-title">学習資料</span>
                <button class="doc-close-btn" id="close_doc_btn">×</button>
            </div>

            <div class="doc-sidebar" id="doc_sidebar">
                <ul class="doc-menu-list"></ul>
            </div>

            <div class="doc-overlay" id="doc_overlay"></div>

            <div class="doc-content" id="doc_content_area">
                <p>読み込み中...</p>
            </div>
        </div>
    </div>
    [endhtml]

    [iscript]
    // --- 設定：メニュー項目 ---
    var menuItems = [
        { title: "トップページ", file: "sample.md" },
        { title: "世界観",      file: "world.md" },
        { title: "キャラクター", file: "chara.md" },
        { title: "操作説明",    file: "help.md" }
    ];

    // コンテナ取得
    var container = $(".doc-viewer-container");
    // 重複削除（ロードし直し対策）
    $(".doc-viewer-container").not(container).remove();

    // fixレイヤーへ移動（最前面へ）
    var fix_layer = $(".fixlayer").last();
    container.appendTo(fix_layer);

    // --- 要素の取得 ---
    var panel = container.find("#doc_panel");
    var btn = container.find("#open_doc_btn");
    var closeBtn = container.find("#close_doc_btn");
    var hamburger = container.find("#doc_hamburger");
    var sidebar = container.find("#doc_sidebar");
    var overlay = container.find("#doc_overlay");
    var menuList = container.find(".doc-menu-list");
    var contentArea = container.find("#doc_content_area");

    // --- メニューリストの生成 ---
    menuList.empty(); // 重複防止のため一度空にする
    menuItems.forEach(function(item) {
        var li = $('<li class="doc-menu-item">' + item.title + '</li>');
        li.on("click", function() {
            TYRANO.kag.stat.f.loadDocMarkdown(item.file);
            toggleSidebar(false); // 選択したらサイドバーを閉じる
        });
        menuList.append(li);
    });

    // --- 関数: サイドバーの開閉 ---
    function toggleSidebar(show) {
        if (show) {
            sidebar.addClass("active");
            overlay.fadeIn(200);
        } else {
            sidebar.removeClass("active");
            overlay.fadeOut(200);
        }
    }

    // --- イベント設定 ---

    // 1. パネルを開く
    btn.on("click", function() {
        panel.addClass("active");
        btn.fadeOut(200);
    });

    // 2. パネルを閉じる
    closeBtn.on("click", function() {
        panel.removeClass("active");
        toggleSidebar(false); // メニューも閉じる
        setTimeout(function(){ btn.fadeIn(200); }, 300);
    });

    // 3. ハンバーガーボタン
    hamburger.on("click", function() {
        var isActive = sidebar.hasClass("active");
        toggleSidebar(!isActive);
    });

    // 4. オーバーレイ（背景）クリックでメニューを閉じる
    overlay.on("click", function() {
        toggleSidebar(false);
    });

    // 5. 本文内のリンク処理
    contentArea.on("click", "a", function(e) {
        var href = $(this).attr("href");
        if (href && href.indexOf(".md") !== -1) {
            // .mdリンクなら内部読み込み
            e.preventDefault();
            TYRANO.kag.stat.f.loadDocMarkdown(href);
        } else if (href && (href.indexOf("http") === 0)) {
            // 外部リンクならブラウザで開く
            e.preventDefault();
            require('electron').shell.openExternal(href);
        }
    });

    // 読み込み関数（前回と同じ：キャッシュ無効化）
    TYRANO.kag.stat.f.loadDocMarkdown = function(file) {
        var filePath = file;
        // URLでない、かつパスが含まれていない場合はデフォルトフォルダを補完
        if (file.indexOf("http") === -1 && file.indexOf("./") === -1) {
                filePath = "./data/others/plugin/doc_viewer/docs/" + file;
        }
        $.ajax({
            url: filePath,
            cache: false,
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

    // 初期表示
    panel.removeClass("active"); // 最初は閉じておく
    btn.show();
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