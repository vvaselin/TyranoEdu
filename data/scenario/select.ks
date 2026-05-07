; select.ks - 課題・講義選択画面（縦スクロール版）
*start
[mask time=500]
[clearfix]
[hidemenubutton]
[wait time=500]
[bg storage="黒板.png" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

[if exp="f.all_tasks == undefined"]
    [iscript]
    // 課題データを同期的に読み込み
    $.ajax({
        url: "./data/others/tasks.json",
        dataType: "json",
        async: false,
        success: function(data) {
            f.all_tasks = data;
            console.log("Tasks loaded:", data);
        }
    });
    [endscript]
[endif]

; タイトル表示
[ptext name="lecture_title" layer="fix" text="講義パート" size="20" color="0xFFFFFF" x="200" y="50" bold="true"]
[ptext name="task_title" layer="fix" text="課題パート" size="20" color="0xFFFFFF" x="680" y="50" bold="true"]

; 1. 講義パート用縦スクロールエリアの作成（左側）
[scroll_area_vertical id="lecture_area" top=100 left=200 width=450 height=600 contents_h=2100 zindex=1000000]

; 2. 課題パート用縦スクロールエリアの作成（右側）
[scroll_area_vertical id="task_area" top=100 left=680 width=450 height=600 contents_h=2100 zindex=1000000]

[for name="tf.i" from="1" to="20"]
    [iscript]
        var i = parseInt(tf.i);
        var prev_task = "task" + (i - 1);
        
        // 座標計算（縦並び）
        tf.y_lecture = (i - 1) * 100 + 50;  // 講義ボタンのY座標
        tf.y_task    = (i - 1) * 100 + 50;  // 課題ボタンのY座標
        tf.x_lecture = 80;   // 講義エリア内でのX座標
        tf.x_task    = 80;   // 課題エリア内でのX座標

        tf.l_name = "l_btn_" + i;
        tf.t_name = "t_btn_" + i;

        // ロック判定
        tf.is_locked = (i > 1 && (!f.cleared_tasks || !f.cleared_tasks[prev_task]));
    [endscript]

    [if exp="tf.is_locked == false"]
        ; --- 解放状態 ---
        ; 講義ボタン
        [glink name="&tf.l_name" color="mybtn_10" text="&'ep. '+tf.i" x="&tf.x_lecture" y="&tf.y_lecture" width=250 height=50 size=20 target="*lecture_jump" exp="&'tf.target_lecture_num='+tf.i"]

        ; 課題ボタン
        [glink name="&tf.t_name" color="mybtn_08" storage="select.ks" target="*common_task_start" text="&'課題'+tf.i" x="&tf.x_task" y="&tf.y_task" width=250 height=50 size=20 exp="&'f.current_task_id = \"task' + tf.i + '\"'"]

    [else]
        ; --- ロック状態 ---
        [glink name="&tf.l_name" color="mybtn_locked" text="&'ep. '+tf.i+' (Lock)'" x="&tf.x_lecture" y="&tf.y_lecture" width=250 height=50 size=20 target="*locked"]
        [glink name="&tf.t_name" color="mybtn_locked" text="&'課題 '+tf.i+' (Lock)'" x="&tf.x_task" y="&tf.y_task" width=250 height=50 size=20 target="*locked"]
    [endif]

    ; それぞれのエリアにボタンを配置
    [scroll_area_vertical_in id="lecture_area" name="&tf.l_name"]
    [scroll_area_vertical_in id="task_area" name="&tf.t_name"]
[nextfor]

; 画面固定の戻るボタン
[glink color="mybtn_09" text="戻る↩" target="*back_home" size=20 width=100 x=50 y=20]

[mask_off time=500]
[s]

; -----------------------------------------------------------
; ▼▼▼ 各種ハンドラ・共通処理 ▼▼▼
; -----------------------------------------------------------

; 講義開始処理
*lecture_jump
[scroll_area_vertical_del id="lecture_area"]
[scroll_area_vertical_del id="task_area"]
[clearfix]
@layopt layer="message0" visible=true
[start_keyconfig]
; ファイルパスを組み立ててジャンプ
[eval exp="tf.lecture_path = 'lecture/' + tf.target_lecture_num + '.ks'"]
[jump storage="&tf.lecture_path" target="*start"]

; ロック時の警告
*locked
[dialog type="alert" text="前の課題をクリアすると解放されます。"]
[scroll_area_vertical_del id="lecture_area"]
[scroll_area_vertical_del id="task_area"]
[clearfix]
[jump target="*start"]

; ホームに戻る
*back_home
[scroll_area_vertical_del id="lecture_area"]
[scroll_area_vertical_del id="task_area"]
[clearfix]
[jump storage="home.ks" target="*start"]

; 課題開始
*common_task_start
[scroll_area_vertical_del id="lecture_area"]
[scroll_area_vertical_del id="task_area"]
[clearfix]
[iscript]
// 1. クリックされたIDを取得
var taskId = f.current_task_id;
console.log("Selected Task ID:", taskId);

if (f.all_tasks && f.all_tasks[taskId]) {
    var taskData = f.all_tasks[taskId];
    console.log("Found Task Data:", taskData.title);
    
    // 2. 初期コードのパース
    if (taskData.initial_code) {
        if (Array.isArray(taskData.initial_code)) {
            f.my_code = taskData.initial_code.join('\n');
        } else {
            f.my_code = taskData.initial_code;
        }
    }
} else {
    console.error("Task not found! ID:", taskId);
    f.my_code = "// 課題データが見つかりません。ID: " + taskId;
}
[endscript]

[eval exp="f.is_sandbox = false"]
@layopt layer="message0" visible=true
[start_keyconfig]
;[if exp="f.user_role == 'experimental'"]
    [jump storage="editor.ks" target="*start"]
;[else]
;    [jump storage="editor_control.ks" target="*start"]
;[endif]

[eval exp="f.is_sandbox = false"]

@layopt layer="message0" visible=true
[start_keyconfig]
;[if exp="f.user_role == 'experimental' "]
    [jump storage="editor.ks" target="*start"]
;[else]
;    [jump storage="editor_control.ks" target="*start"]
;[endif]
