*start
[clearfix]
[bg storage="rouka.jpg" time="0"]
@layopt layer="message0" visible=false

[jump target="*menu_start" cond="f.system_initialized == true" ]


; プラグインを読み込む
[plugin name="monaco_editor"]
[plugin name="cpp_executor"]
[plugin name="glink_ex"]
;[plugin name="ai_chat"]
[plugin name="mascot_chat"]
[loadcss file="./data/others/css/glink.css"]

; 課題データの読み込み
[eval exp="f.current_task_id = sf.current_task_id || 'task1'"]
[iscript]
// 読み込む JSON ファイルのパス
var json_path = "./data/others/tasks.json";

$.ajax({
    url: json_path,
    type: 'GET',
    dataType: 'json',
    async: false,
    
    success: function(data) {
        TYRANO.kag.stat.f.all_tasks = data;
        console.log("tasks.json 読み込み成功:", TYRANO.kag.stat.f.all_tasks);
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

; 実行ボタンglinkのデザイン用マクロ
[macro name="start_button"]
[glink color=%color storage="first.ks" target=%target text=%text width="640" size="20" x=%x y=%y]
[endmacro]

[start_button color="btn_01_blue" target="*quest1" text="課題1" x="50" y="70"]
[start_button color="btn_01_blue" target="*quest2" text="課題2" x="50" y="170"]

[s]

*quest1

[eval exp="f.current_task_id = 'task1'"]

[jump storage="editor.ks" target="*start"]

[s]

*quest2

[eval exp="f.current_task_id = 'task2'"]

[jump storage="editor.ks" target="*start"]

[s]
