; select.ks - 課題・講義選択画面
*start
[mask time=500]
[clearfix]
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
            TYRANO.kag.stat.f.all_tasks = data;
            console.log("Tasks loaded:", data);
        }
    });
    [endscript]
[endif]

; 1. スクロールエリアの作成
[iscript]
tf.area_contents_w = (f.user_role == 'experimental') ? 3500 : 2000;
[endscript]
[scroll_area id="select_screen" top=150 left=0 width=1280 height=500 contents_w="&tf.area_contents_w" zindex=1000000]

[for name="tf.i" from="1" to="5"]
    [iscript]
        var i = parseInt(tf.i);
        var prev_task = "task" + (i - 1);
        
        // 座標計算
        tf.y_btn = 350; 
        if (f.user_role == 'experimental') {
            tf.x_lecture = (i - 1) * 600 + 150;
            tf.x_task    = tf.x_lecture + 260;
        } else {
            // 講義なし：間隔を詰めて中央寄りに配置
            tf.x_task = (i - 1) * 350 + 200;
        }

        tf.l_name = "l_btn_" + i;
        tf.t_name = "t_btn_" + i;

        // ロック判定
        tf.is_locked = (i > 1 && (!f.cleared_tasks || !f.cleared_tasks[prev_task]));
    [endscript]

    [if exp="tf.is_locked == false"]
        ; --- 解放状態 ---
        ; 講義ボタン (experimentalのみ)
        [if exp="f.user_role == 'experimental'"]
            [glink name="&tf.l_name" color="mybtn_10" text="&'ep. '+tf.i" x="&tf.x_lecture" y="&tf.y_btn" width=250 target="*lecture_jump" exp="&'tf.target_lecture_num='+tf.i"]
        [endif]

        ; 課題ボタン
        ; expの中で 'task1' のように文字列として評価されるよう、引用符の扱いに注意します
        [glink name="&tf.t_name" color="mybtn_08" storage="select.ks" target="*common_task_start" text="&'課題'+tf.i" x="&tf.x_task" y="&tf.y_btn" width=250 size=30 exp="&'f.current_task_id = \"task' + tf.i + '\"'"]

    [else]
        ; --- ロック状態 ---
        [if exp="f.user_role == 'experimental'"]
            [glink name="&tf.l_name" color="mybtn_locked" text="&'ep. '+tf.i+' (Lock)'" x="&tf.x_lecture" y="&tf.y_btn" width=250 target="*locked"]
        [endif]
        [glink name="&tf.t_name" color="mybtn_locked" text="&'課題 '+tf.i+' (Lock)'" x="&tf.x_task" y="&tf.y_btn" width=250 target="*locked"]
    [endif]

    [scroll_area_in id="select_screen" name="&tf.l_name + ',' + tf.t_name"]
[nextfor]

; 画面固定の戻るボタン
[glink color="mybtn_09" text="戻る↩" target="*back_home" width=200 x=50 y=20]

[mask_off time=500]
[s]

; -----------------------------------------------------------
; ▼▼▼ 各種ハンドラ・共通処理 ▼▼▼
; -----------------------------------------------------------

; 講義開始処理
*lecture_jump
[scroll_area_del id="select_screen"]
@layopt layer="message0" visible=true
[start_keyconfig]
; ファイルパスを組み立ててジャンプ
[eval exp="tf.lecture_path = 'lecture/' + tf.target_lecture_num + '.ks'"]
[jump storage="&tf.lecture_path" target="*start"]

; ロック時の警告
*locked
[dialog type="alert" text="前の課題をクリアすると解放されます。"]
[scroll_area_del id="select_screen"]
[jump target="*start"]

; ホームに戻る
*back_home
[scroll_area_del id="select_screen"]
[jump storage="home.ks" target="*start"]

; 課題開始
*common_task_start
[scroll_area_del id="select_screen"]
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
[if exp="f.user_role == 'experimental'"]
    [jump storage="editor.ks" target="*start"]
[else]
    [jump storage="editor_control.ks" target="*start"]
[endif]

[eval exp="f.is_sandbox = false"]

@layopt layer="message0" visible=true
[start_keyconfig]
[if exp="f.user_role == 'experimental' "]
    [jump storage="editor.ks" target="*start"]
[else]
    [jump storage="editor_control.ks" target="*start"]
[endif]