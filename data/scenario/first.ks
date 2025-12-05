*start
; 初期化処理
[jump target="*menu_start" cond="f.system_initialized == true" ]

; プラグインを読み込む
[plugin name="monaco_editor"]
[plugin name="cpp_executor"]
[plugin name="glink_ex"]
[plugin name="mascot_chat"]
; css読み込み
[loadcss file="./tyrano/libs/jquery-ui/jquery-ui.css"]
[loadcss file="./data/others/css/modal_dark_theme.css"]
[loadcss file="./data/others/plugin/css/mystyle.css"]

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

; 好感度
[eval exp="f.love_level = 20"]

[eval exp="f.system_initialized = true"]

*menu_start

; ステージ選択へ
[jump storage="select.ks" target="*start"]