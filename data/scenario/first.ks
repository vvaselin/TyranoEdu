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
[plugin name="scroll_area"]
[plugin name="theme_kopanda_22_HD_anim"]

[loadcss file="./tyrano/libs/jquery-ui/jquery-ui.css"]
[loadcss file="./data/others/css/modal_dark_theme.css"]
[loadcss file="./data/others/plugin/css/mystyle.css"]
[loadcss file="./data/others/plugin/css/button.css"]
[loadcss file="./data/others/plugin/css/tooltip.css"]
[loadcss file="./data/others/plugin/css/bubbles.css"]
[loadcss file="./data/others/plugin/css/perse_btn.css"]

; キャラ定義
[chara_new name name="mocha" storage="chara/mocha/normal.png" jname="モカ"]
; 表情定義 
[chara_face name="mocha" face="normal" storage="chara/mocha/normal.png" ]
[chara_face name="mocha" face="oko" storage="chara/mocha/oko.png" ]
[chara_face name="mocha" face="tere" storage="chara/mocha/tere.png" ]
[chara_face name="mocha" face="terekomari" storage="chara/mocha/terekomari.png" ]
[chara_face name="mocha" face="melt" storage="chara/mocha/melt.png" ]
[chara_face name="mocha" face="surprise" storage="chara/mocha/surprise.png" ]
[chara_face name="mocha" face="iya" storage="chara/mocha/iya.png" ]
[chara_face name="mocha" face="kowai" storage="chara/mocha/kowai.png" ]
[chara_face name="mocha" face="huhun" storage="chara/mocha/huhun.png" ]
[chara_face name="mocha" face="doubt" storage="chara/mocha/doubt.png" ]
[chara_face name="mocha" face="doya" storage="chara/mocha/doya.png" ]
[chara_face name="mocha" face="donbiki" storage="chara/mocha/donbiki.png" ]
[chara_face name="mocha" face="aseri" storage="chara/mocha/aseri.png" ]
[chara_face name="mocha" face="komari" storage="chara/mocha/komari.png" ]
[chara_face name="mocha" face="happy" storage="chara/mocha/happy.png" ]
[chara_face name="mocha" face="frustration" storage="chara/mocha/frustration.png" ]
[chara_face name="mocha" face="sad" storage="chara/mocha/sad.png" ]
[chara_face name="mocha" face="doya" storage="chara/mocha/doya.png" ]
[chara_face name="mocha" face="iya" storage="chara/mocha/iya.png" ]
[chara_face name="mocha" face="akire" storage="chara/mocha/akire.png" ]

; マクロ定義
[macro name="play_clear"]
    ; layer="fix" のオブジェクトを消去（同じ名前のものがあれば）
    [free name="clear_obj" layer=%layer|2]

    ; 画像表示（zindexは十分に大きく、fixレイヤーに指定可能）
    [image storage="clear.svg" name="clear_obj" layer=%layer|2 zindex=2000000 x=0 y=0 width=1280 height=720 visible=true]

    ; アニメーション時間分待機
    [wait time=1500]

    ; 自動消去
    [if exp="mp.auto_remove=='true'"]
        [free name="clear_obj" layer=%layer|2]
    [endif]
[endmacro]

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
        tyrano.plugin.kag.ftag.startTag("jump", { storage: "auth_google.ks" });
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

$.ajax({
    url: '/api/memory?user_id=' + uid,
    type: 'GET',
    dataType: 'json',
    success: function(data) {
        TYRANO.kag.stat.f.love_level = data.love_level || 0;
        TYRANO.kag.stat.f.user_role = data.role || "control";
        TYRANO.kag.stat.f.ai_memory = data;
        TYRANO.kag.stat.f.user_name = data.name || "ゲスト";
    },
    error: function() {
        TYRANO.kag.stat.f.love_level = 0;
        TYRANO.kag.stat.f.ai_memory = {};
        TYRANO.kag.stat.f.user_role = "control";
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