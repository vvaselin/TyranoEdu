*start
[clearfix]
[bg storage="rouka.jpg" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

[jump target="*menu_start" cond="f.system_initialized == true" ]

; プラグインを読み込む
[plugin name="monaco_editor"]
[plugin name="cpp_executor"]
[plugin name="glink_ex"]
;[plugin name="ai_chat"]
[plugin name="mascot_chat"]
; css読み込み
[loadcss file="./data/others/css/glink.css"]
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

; 好感度（初期値0）
[eval exp="f.love_level = 20"]

[eval exp="f.system_initialized = true"]

*menu_start

; 実行ボタンglinkのデザイン用マクロ
[macro name="start_button"]
[glink color=%color storage="first.ks" target=%target text=%text width="300" size="20" x=%x y=%y]
[endmacro]

[start_button color="btn_01_blue" target="*quest1" text="課題1" x="50" y="70"]
[start_button color="btn_01_blue" target="*quest2" text="課題2" x="50" y="170"]
[start_button color="btn_01_blue" target="*quest3" text="課題3" x="50" y="270"]

[start_button color="btn_01_blue" target="*questEX" text="課題EX" x="50" y="470"]

[start_button color="btn_01_blue" target="*lecture1" text="講義1" x="500" y="70"]

[s]

*quest1
[eval exp="f.current_task_id = 'task1'"]
[jump target="*common_task_start"]

*quest2
[eval exp="f.current_task_id = 'task2'"]
[jump target="*common_task_start"]

*quest3
[eval exp="f.current_task_id = 'task3'"]
[jump target="*common_task_start"]

*lecture1
@layopt layer="message0" visible=true
[start_keyconfig]

[jump storage="lecture/1.ks" target="*start"]

*questEX
[eval exp="f.current_task_id = 'task_ex'"]
[jump target="*common_task_start"]

*common_task_start
[iscript]
var taskId = TYRANO.kag.stat.f.current_task_id;
var taskData = TYRANO.kag.stat.f.all_tasks[taskId];

if (taskData && taskData.initial_code) {
    if (Array.isArray(taskData.initial_code)) {
        TYRANO.kag.stat.f.my_code = taskData.initial_code.join('\n');
    } else {
        TYRANO.kag.stat.f.my_code = taskData.initial_code;
    }
} else {
    TYRANO.kag.stat.f.my_code = "// コードが見つかりません";
}
[endscript]

; エディタ画面へ移動
[jump storage="editor.ks" target="*start"]