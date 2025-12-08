*start
; 初期化処理
[jump target="*menu_start" cond="f.system_initialized == true" ]

; プラグインを読み込む
[plugin name="monaco_editor"]
[plugin name="cpp_executor"]
[plugin name="glink_ex"]
[plugin name="mascot_chat"]
[plugin name="doc_viewer"]
; css読み込み
[loadcss file="./tyrano/libs/jquery-ui/jquery-ui.css"]
[loadcss file="./data/others/css/modal_dark_theme.css"]
[loadcss file="./data/others/plugin/css/mystyle.css"]

[iscript]
// テスト用IDをグローバル変数に設定
TYRANO.kag.stat.f.user_id = "00000000-0000-0000-0000-000000000001";

var uid = TYRANO.kag.stat.f.user_id;

$.ajax({
    url: '/api/memory?user_id=' + uid,
    type: 'GET',
    dataType: 'json',
    cache: false,
    async: false, // ★重要: 読み込み完了まで待機させる
    
    success: function(data) {
        if (data) {
            // サーバーの値をティラノ変数に適用
            TYRANO.kag.stat.f.love_level = data.love_level || 0;
            
            // 記憶データも変数に入れておく（チャット機能がこれを使う）
            TYRANO.kag.stat.f.ai_memory = data;
            
            console.log("★Profile Loaded:", data);
        }
    },
    error: function() {
        console.error("プロフィールの読み込みに失敗しました。オフラインかエラーです。");
        // 失敗時は初期値にしておく
        TYRANO.kag.stat.f.love_level = 0;
        TYRANO.kag.stat.f.ai_memory = { summary: "", learned_topics: [], weaknesses: [] };
    }
});
[endscript]

; 課題データの読み込み
[eval exp="f.current_task_id = sf.current_task_id || 'task1'"]
[iscript]
// 読み込む JSON ファイルのパス
var json_path = "./data/others/tasks.json";

$.ajax({
    url: json_path,
    type: 'GET',
    dataType: 'json',
    cache: false,
    async: false,
    
    success: function(data) {
        TYRANO.kag.stat.f.all_tasks = data;
        // console.log("tasks.json 読み込み成功:", TYRANO.kag.stat.f.all_tasks);
    },
    
    error: function(xhr, status, error) {
        console.error("tasks.json 読み込み失敗:", json_path, error);
        
        TYRANO.kag.stat.f.all_tasks = { 
            "error_task": { 
                "title": "読込失敗", 
                "description": "tasks.json が見つかりません。\nパスを確認してください。" 
            }
        };
        TYRANO.kag.stat.f.current_task_id = "error_task";
    }
});
[endscript]

[eval exp="f.system_initialized = true"]

*menu_start

; ステージ選択へ
[jump storage="select.ks" target="*start"]