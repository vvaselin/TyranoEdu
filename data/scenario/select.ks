; select.ks - 課題選択画面
*start
[mask time=500]
[clearfix]
[wait time=500]
[bg storage="room_f.jpg" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

; -----------------------------------------------------------
; ▼▼▼ [for]プラグインを活用したボタン生成 ▼▼▼
; 課題1〜5までループしてボタンを表示します
; -----------------------------------------------------------

[for name="tf.i" from="1" to="5"]

    [iscript]
    // 現在のループ番号（1〜5）
    var i = parseInt(tf.i);
    var current_task = "task" + i;
    var prev_task    = "task" + (i - 1);
    
    // Y座標を計算
    var y_pos = 100 + (i - 1) * 100;
    
    // ロック判定
    // 1問目は常に解放。2問目以降は「前の課題」がクリア済みなら解放。
    var is_locked = false;
    
    if (i > 1) {
        // 前の課題がクリアリストにない、または false ならロック
        if (!f.cleared_tasks || !f.cleared_tasks[prev_task]) {
            is_locked = true;
        }
    }

    // ボタンの生成 (JSからglinkタグを動的に呼び出すことで、変数を正しく埋め込めます)
    if (is_locked) {
        // ■ ロック状態のボタン (グレー、押すと警告)
        tyrano.plugin.kag.ftag.startTag("glink", {
            color: "mybtn_locked",
            storage: "select.ks",
            target: "*locked",       // 警告ラベルへ
            text: "課題" + i,
            x: 50,
            y: y_pos,
            width: 300,
            size: 30
        });
    } else {
        // ■ 解放状態のボタン (緑、押すと開始)
        tyrano.plugin.kag.ftag.startTag("glink", {
            color: "mybtn_08",
            storage: "select.ks",
            target: "*common_task_start", // 共通開始ラベルへ
            text: "課題" + i,
            x: 50,
            y: y_pos,
            width: 300,
            size: 30,
            
            exp: "f.current_task_id = '" + current_task + "'"
        });
    }
    [endscript]

[nextfor]

; -----------------------------------------------------------
; その他のボタン
; -----------------------------------------------------------

; 講義ボタン（例：課題1クリアで解放）
[if exp="f.cleared_tasks && f.cleared_tasks['task1']"]
    [glink color="mybtn_10" storage="select.ks" target="*lecture1" text="講義1" width="300" size="30" x="500" y="100"]
[else]
    [glink color="mybtn_locked" storage="select.ks" target="*locked" text="講義1 (Lock)" width="300" size="30" x="500" y="100"]
[endif]

[glink color="mybtn_09" storage="home.ks" text="戻る↩" target="*start" width="200" size="20" x="50" y="10"]

[mask_off time=500]
[s]

; -----------------------------------------------------------
; ▼▼▼ 共通処理パート ▼▼▼
; -----------------------------------------------------------

; ロック時の警告メッセージ
*locked
[dialog type="alert" text="この課題はまだ解放されていません。<br>前の課題をクリアしてください。"]
[jump target="*start"]

; 講義開始
*lecture1
@layopt layer="message0" visible=true
[start_keyconfig]
[jump storage="lecture/1.ks" target="*start"]

; 課題開始（全課題共通）
*common_task_start
[iscript]
var taskId = TYRANO.kag.stat.f.current_task_id;
// タスクデータの取得
if(TYRANO.kag.stat.f.all_tasks){
    var taskData = TYRANO.kag.stat.f.all_tasks[taskId];
    if (taskData && taskData.initial_code) {
        if (Array.isArray(taskData.initial_code)) {
            TYRANO.kag.stat.f.my_code = taskData.initial_code.join('\n');
        } else {
            TYRANO.kag.stat.f.my_code = taskData.initial_code;
        }
    } else {
        TYRANO.kag.stat.f.my_code = "// コードが見つかりません: " + taskId;
    }
}
[endscript]

; エディタ画面へ移動
[if exp="f.user_role == 'experimental' "]
[jump storage="editor.ks" target="*start"]
[else]
[jump storage="editor_control.ks" target="*start"]
[endif]