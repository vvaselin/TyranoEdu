; first.ks - 初期化とデータロード
*start
@layopt layer="message0" visible=false

; 初期化済みならメニューへ飛ばす
[jump target="*menu_start" cond="f.system_initialized == true" ]

; --- 1. プラグイン読み込み ---
[plugin name="monaco_editor"]
[plugin name="cpp_executor"]
[plugin name="glink_ex"]
[plugin name="mascot_chat"]
[plugin name="ai_chat"]
[plugin name="doc_viewer"]
[plugin name="for"]
[plugin name="theme_kopanda_22_HD_anim"]

[loadcss file="./tyrano/libs/jquery-ui/jquery-ui.css"]
[loadcss file="./data/others/css/modal_dark_theme.css"]
[loadcss file="./data/others/plugin/css/mystyle.css"]

[chara_new name name="mocha" storage="chara/mocha/normal.png" jname="モカ"]

; --- 課題データの読み込み (認証チェックの前に移動！) ---
[eval exp="f.current_task_id = sf.current_task_id || 'task1'"]
[iscript]
var json_path = "./data/others/tasks.json";
$.ajax({
    url: json_path,
    type: 'GET',
    dataType: 'json',
    cache: false,
    async: false,
    success: function(data) {
        TYRANO.kag.stat.f.all_tasks = data;
    },
    error: function(xhr, status, error) {
        console.error("tasks.json Load Error:", error);
        TYRANO.kag.stat.f.all_tasks = { "error": { "title":"Error", "description":"Load Failed" }};
    }
});
[endscript]


; --- Supabase認証チェック ---
[iscript]
const SUPABASE_URL = "https://wiekjpgvpyiowlkcmdjg.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_Nd2TWtIAsPIijQhZg2oDSg_06O9paNr";

const { createClient } = supabase;
window.sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

sb.auth.getSession().then(({ data: { session } }) => {
    if (session) {
        // ログイン済み -> プロフィール読み込みへ
        TYRANO.kag.stat.f.user_id = session.user.id;
        tyrano.plugin.kag.ftag.startTag("jump", { target: "*load_user_data" });
    } else {
        // 未ログイン -> ログイン画面へ移動
        tyrano.plugin.kag.ftag.startTag("jump", { storage: "auth.ks" });
    }
});
[endscript]

; 判定待ち
[s]


; --- ユーザープロフィール読み込み ---
*load_user_data

[iscript]

// ▼▼▼ ローディング画面を表示 ▼▼▼
if ($("#loading_overlay").length === 0) {
    $('body').append('<div id="loading_overlay" class="loading-overlay" style="display:none;"><div class="loader">Loading...</div></div>');
}
$("#loading_overlay").fadeIn(200);

var uid = TYRANO.kag.stat.f.user_id;
console.log("Loading Profile for:", uid);

$.ajax({
    url: '/api/memory?user_id=' + uid,
    type: 'GET',
    dataType: 'json',
    success: function(data) {
        TYRANO.kag.stat.f.love_level = data.love_level || 0;
        TYRANO.kag.stat.f.ai_memory = data;
    },
    error: function() {
        TYRANO.kag.stat.f.love_level = 0;
        TYRANO.kag.stat.f.ai_memory = {};
    }
}).always(function(){
    window.sb.from('task_progress')
        .select('task_id')
        .eq('user_id', uid)
        .eq('is_cleared', true)
        .then(({ data, error }) => {
            if (data) {
                TYRANO.kag.stat.f.cleared_tasks = {};
                data.forEach(row => {
                    TYRANO.kag.stat.f.cleared_tasks[row.task_id] = true;
                });
            }
            
            $("#loading_overlay").fadeOut(300, function(){
                tyrano.plugin.kag.ftag.startTag("jump", { storage: "home.ks", target: "*start" });
            });
        });
});
[endscript]

[wait time=500]
[jump storage="home.ks" target="*start"]

[s]

*menu_start
[jump storage="home.ks" target="*start"]