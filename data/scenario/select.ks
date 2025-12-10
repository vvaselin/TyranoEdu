; ステージ選択
*start
[hidemenubutton] 
[clearfix]
[bg storage="rouka.jpg" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

; 実行ボタンglinkのデザイン用マクロ
[macro name="start_quest"]
[glink color=mybtn_08 storage="select.ks" target=%target text=%text width="300" size="30" x=%x y=%y]
[endmacro]
[macro name="start_story"]
[glink color=mybtn_10 storage="select.ks" target=%target text=%text width="300" size="30" x=%x y=%y]
[endmacro]

[start_quest  target="*quest1" text="課題1" x="50" y="70"]
[start_quest  target="*quest2" text="課題2" x="50" y="170"]
[start_quest  target="*quest3" text="課題3" x="50" y="270"]
[start_quest  target="*quest4" text="課題4" x="50" y="370"]
[start_quest  target="*quest5" text="課題5" x="50" y="470"]

[start_story  target="*lecture1" text="講義1" x="500" y="70"]
; ログアウトボタンを表示
[button name="logout_btn" graphic="button/close.png" enterimg="button/close2.png" x=1180 y=20 width=80 height=30 role="sleep" fix="true"]

[iscript]
$(".logout_btn").off("click").on("click", async function() {
    // 確認ダイアログ
    if (!confirm("ログアウトしますか？")) return;

    // Supabaseからログアウト
    if (window.sb) {
        await window.sb.auth.signOut();
    }

    // ユーザーID情報をクリア
    TYRANO.kag.stat.f.user_id = null;
    TYRANO.kag.stat.f.ai_memory = null;

    // ログイン画面へ戻る
    tyrano.plugin.kag.ftag.startTag("jump", { storage: "auth.ks" });
});
[endscript]

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

*quest4
[eval exp="f.current_task_id = 'task4'"]
[jump target="*common_task_start"]

*quest5
[eval exp="f.current_task_id = 'task5'"]
[jump target="*common_task_start"]

*lecture1
@layopt layer="message0" visible=true
[start_keyconfig]

[jump storage="lecture/1.ks" target="*start"]

*common_task_start
[iscript]
var taskId = TYRANO.kag.stat.f.current_task_id;
var taskData = TYRANO.kag.stat.f.all_tasks[taskId];
var inputData = (taskData && taskData.stdin) ? taskData.stdin : "";

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