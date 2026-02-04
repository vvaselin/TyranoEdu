; select.ks - 課題・講義選択画面
*start
[mask time=500]
[clearfix]
[wait time=500]
[bg storage="黒板.png" time="0"]
@layopt layer="message0" visible=false
[stop_keyconfig]

; 1. スクロールエリアの作成
; 1280x720全体を使用。contents_wはボタンの数に合わせて調整（例: 5セットで約3500px）
[scroll_area id="select_screen" top=150 left=0 width=1280 height=500 contents_w=3500 zindex=1000000]

; -----------------------------------------------------------
; ▼▼▼ ループによるボタン生成パート ▼▼▼
; -----------------------------------------------------------

[for name="tf.i" from="1" to="5"]
    [iscript]
    var i = parseInt(tf.i);
    tf.x_lecture = (i - 1) * 650 + 150;
    tf.x_task    = tf.x_lecture + 300;
    var prev_task = "task" + (i - 1);
    
    // スクロールエリア内（高さ500px）でのボタン位置
    // y=200 にすれば、画面全体で見ると 100 + 200 = y=300 の位置に見えます
    tf.y_btn = 200; 

    tf.l_name = "l_btn_" + i;
    tf.t_name = "t_btn_" + i;
    tf.is_locked = false;
    if (i > 1) {
        if (!f.cleared_tasks || !f.cleared_tasks[prev_task]) {
            tf.is_locked = true;
        }
    }
    [endscript]

    [if exp="tf.is_locked == false"]
        ; --- 解放状態 ---
        [glink name="&tf.l_name" color="mybtn_08" text="&'ep. '+tf.i" x="&tf.x_lecture" y=300 width=250 target="*lecture_jump" exp="&'tf.target_lecture_num='+tf.i"]
        [glink name="&tf.t_name" color="mybtn_09" text="&'課題 '+tf.i" x="&tf.x_task" y=300 width=250 target="*common_task_start" exp="&'f.current_task_id=\'task'+tf.i+'\''"]
    [else]
        ; --- ロック状態 ---
        [glink name="&tf.l_name" color="mybtn_locked" text="&'ep. '+tf.i+' (Lock)'" x="&tf.x_lecture" y=300 width=250 target="*locked"]
        [glink name="&tf.t_name" color="mybtn_locked" text="&'課題 '+tf.i+' (Lock)'" x="&tf.x_task" y=300 width=250 target="*locked"]
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
var taskId = TYRANO.kag.stat.f.current_task_id;
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

[eval exp="f.is_sandbox = false"]

@layopt layer="message0" visible=true
[start_keyconfig]
[if exp="f.user_role == 'experimental' "]
    [jump storage="editor.ks" target="*start"]
[else]
    [jump storage="editor_control.ks" target="*start"]
[endif]