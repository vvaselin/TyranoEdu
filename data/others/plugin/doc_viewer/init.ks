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
    var container = $(".doc-viewer-container");
    $(".doc-viewer-container").not(container).remove();

    // fixレイヤーへ移動
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

    // --- ★変更点: 外部JSONからメニューを生成する関数 ---
    var menuJsonPath = "./data/others/plugin/doc_viewer/docs/menu.json";

    function createMenu(items) {
        menuList.empty();
        
        items.forEach(function(item) {
            // カテゴリ（見出し）がある場合
            if (item.category && item.items) {
                // 見出しを追加
                var catEl = $('<li class="doc-menu-category">' + item.category + '</li>');
                menuList.append(catEl);
                
                // 中身のアイテムを追加
                item.items.forEach(function(subItem){
                    addMenuItem(subItem, true); // trueはインデント用フラグ
                });
            } 
            // 普通の項目の場合
            else {
                addMenuItem(item, false);
            }
        });
    }

    function addMenuItem(item, isSubItem) {
        var className = "doc-menu-item";
        if(isSubItem) className += " sub-item"; // インデント用クラス
        
        var li = $('<li class="' + className + '">' + item.title + '</li>');
        li.on("click", function() {
            TYRANO.kag.stat.f.loadDocMarkdown(item.file);
            // モバイル等のためにクリックしたら閉じる（PCなら閉じなくてもいいかも）
            if(window.innerWidth < 800) { 
                toggleSidebar(false);
            }
        });
        menuList.append(li);
    }

    // --- JSON読み込み実行 ---
    $.ajax({
        url: menuJsonPath,
        dataType: 'json',
        cache: false,
        success: function(data) {
            createMenu(data);
        },
        error: function() {
            console.error("menu.json の読み込みに失敗しました");
            menuList.html('<li class="doc-menu-item">メニュー読込エラー</li>');
        }
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
    // (ここは前回と同じ)
    btn.on("click", function() {
        panel.addClass("active");
        btn.fadeOut(200);
    });

    closeBtn.on("click", function() {
        panel.removeClass("active");
        toggleSidebar(false);
        setTimeout(function(){ btn.fadeIn(200); }, 300);
    });

    hamburger.on("click", function() {
        var isActive = sidebar.hasClass("active");
        toggleSidebar(!isActive);
    });

    overlay.on("click", function() {
        toggleSidebar(false);
    });

    contentArea.on("click", "a", function(e) {
        var href = $(this).attr("href");
        if (href && href.indexOf(".md") !== -1) {
            e.preventDefault();
            TYRANO.kag.stat.f.loadDocMarkdown(href);
        } else if (href && (href.indexOf("http") === 0)) {
            e.preventDefault();
            require('electron').shell.openExternal(href);
        }
    });

    // 読み込み関数
    TYRANO.kag.stat.f.loadDocMarkdown = function(file) {
        var filePath = file;
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
    panel.removeClass("active");
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