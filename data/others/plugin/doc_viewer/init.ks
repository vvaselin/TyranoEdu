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

    // --- 外部JSONからメニューを生成する関数 ---
    var menuJsonPath = "./data/others/plugin/doc_viewer/docs/menu.json";

    function createMenu(items) {
        menuList.empty();
        
        items.forEach(function(item) {
            // カテゴリ（見出し）がある場合
            if (item.category && item.items) {
                // カテゴリのコンテナ(li)を作成
                var catLi = $('<li class="doc-category-container"></li>');
                
                // 見出し部分（クリック可能）を作成
                // 矢印アイコン(▼)を含める
                var catTitle = $('<div class="doc-menu-category"><span class="cat-arrow">▼</span> ' + item.category + '</div>');
                
                // サブメニューのコンテナ(ul)を作成
                var subUl = $('<ul class="doc-sub-menu"></ul>');
                
                // 中身のアイテムを追加
                item.items.forEach(function(subItem){
                    var subLi = createMenuItem(subItem);
                    subUl.append(subLi);
                });
                
                // 組み立て
                catLi.append(catTitle);
                catLi.append(subUl);
                menuList.append(catLi);
                
                // アコーディオン開閉
                catTitle.on("click", function() {
                    var $ul = $(this).next(".doc-sub-menu");
                    var $arrow = $(this).find(".cat-arrow");
                    
                    // アニメーションで開閉
                    $ul.slideToggle(200);
                    
                    // 矢印の切り替え
                    if ($arrow.text() === "▼") {
                        $arrow.text("▶");
                    } else {
                        $arrow.text("▼");
                    }
                });
            } 
            // カテゴリなしの項目の場合
            else {
                var li = createMenuItem(item);
                menuList.append(li);
            }
        });
    }

    // アイテム生成の共通関数
    function createMenuItem(item) {
        var li = $('<li class="doc-menu-item">' + item.title + '</li>');
        li.on("click", function() {
            TYRANO.kag.stat.f.loadDocMarkdown(item.file);
            
            // 選択状態の見た目を変える（ハイライト）
            $(".doc-menu-item").removeClass("current");
            $(this).addClass("current");

            if(window.innerWidth < 800) { 
                toggleSidebar(false);
            }
        });
        return li;
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
            dataType: 'text', // 明示的にtextとして取得
            cache: false,
            success: function(data) {
                var html = DOMPurify.sanitize(marked.parse(data));
                contentArea.html(html);
                contentArea.scrollTop(0);

                // コピーボタン
                contentArea.find("pre code").each(function(i, block) {
                    var $block = $(block);
                    var $pre = $block.parent("pre");
                    
                    // ボタンの配置基準にするため relative を設定
                    $pre.css("position", "relative"); 

                    // ボタン生成
                    var copyButton = $('<button class="copy-code-button">コピー</button>');
                    
                    // クリックイベント
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

                    // preタグの中にボタンを追加
                    $pre.append(copyButton);
                });

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

[macro name="show_doc_full"]

    [html]
    <div class="doc-viewer-container full-mode">
        <div class="doc-viewer-btn" id="open_doc_btn" style="display:none;"></div>

        <div class="doc-panel active" id="doc_panel">
            <div class="doc-header">
                <span class="doc-title">学習資料</span>
                <button class="doc-close-btn" id="close_doc_btn">戻る</button>
            </div>

            <div class="doc-panel-body">
                <div class="doc-sidebar active" id="doc_sidebar">
                    <ul class="doc-menu-list"></ul>
                </div>

                <div class="doc-content" id="doc_content_area">
                    <p>読み込み中...</p>
                </div>
            </div>
        </div>
    </div>
    [endhtml]

    [iscript]
    var container = $(".doc-viewer-container.full-mode");
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

    // --- 外部JSONからメニューを生成する関数 ---
    var menuJsonPath = "./data/others/plugin/doc_viewer/docs/menu.json";

    function createMenu(items) {
        menuList.empty();
        
        items.forEach(function(item) {
            // カテゴリ（見出し）がある場合
            if (item.category && item.items) {
                // カテゴリのコンテナ(li)を作成
                var catLi = $('<li class="doc-category-container"></li>');
                
                // 見出し部分（クリック可能）を作成
                // 矢印アイコン(▼)を含める
                var catTitle = $('<div class="doc-menu-category"><span class="cat-arrow">▼</span> ' + item.category + '</div>');
                
                // サブメニューのコンテナ(ul)を作成
                var subUl = $('<ul class="doc-sub-menu"></ul>');
                
                // 中身のアイテムを追加
                item.items.forEach(function(subItem){
                    var subLi = createMenuItem(subItem);
                    subUl.append(subLi);
                });
                
                // 組み立て
                catLi.append(catTitle);
                catLi.append(subUl);
                menuList.append(catLi);
                
                // アコーディオン開閉
                catTitle.on("click", function() {
                    // フルスクリーンモード（.full-mode）なら何もしない
                    if (container.hasClass("full-mode")) {
                        return false;
                    }

                    var $ul = $(this).next(".doc-sub-menu");
                    var $arrow = $(this).find(".cat-arrow");
                    
                    $ul.slideToggle(200);
                    if ($arrow.text() === "▼") {
                        $arrow.text("▶");
                    } else {
                        $arrow.text("▼");
                    }
                });
            } 
            // カテゴリなしの項目の場合
            else {
                var li = createMenuItem(item);
                menuList.append(li);
            }
        });
    }

    // アイテム生成の共通関数
    function createMenuItem(item) {
        var li = $('<li class="doc-menu-item">' + item.title + '</li>');
        li.on("click", function() {
            TYRANO.kag.stat.f.loadDocMarkdown(item.file);
            
            // 選択状態の見た目を変える（ハイライト）
            $(".doc-menu-item").removeClass("current");
            $(this).addClass("current");

            if(window.innerWidth < 800) { 
                toggleSidebar(false);
            }
        });
        return li;
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
    btn.on("click", function() {
        panel.addClass("active");
        btn.fadeOut(200);
    });

    closeBtn.on("click", function() {
        TYRANO.kag.ftag.startTag("jump", {storage:"home.ks", target:"*start"});
        container.remove();
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
            dataType: 'text', // 明示的にtextとして取得
            cache: false,
            success: function(data) {
                var html = DOMPurify.sanitize(marked.parse(data));
                contentArea.html(html);
                contentArea.scrollTop(0);

                // コピーボタン
                contentArea.find("pre code").each(function(i, block) {
                    var $block = $(block);
                    var $pre = $block.parent("pre");
                    
                    // ボタンの配置基準にするため relative を設定
                    $pre.css("position", "relative"); 

                    // ボタン生成
                    var copyButton = $('<button class="copy-code-button">コピー</button>');
                    
                    // クリックイベント
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

                    // preタグの中にボタンを追加
                    $pre.append(copyButton);
                });

            },
            error: function() {
                contentArea.html("<p>準備中</p>");
            }
        });
    };

    // 初期表示
    var initialFile = mp.file || "sample.md";
    TYRANO.kag.stat.f.loadDocMarkdown(initialFile);

    [endscript]

[endmacro]

[return]