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
[plugin name="doc_viewer"]
[plugin name="for"]
[plugin name="scroll_area"]
[plugin name="theme_kopanda_22_HD_anim"]
[plugin name="turnover"]
[plugin name="manpu"]
[plugin name="scenario_effects"]

[loadjs storage="./data/others/js/progress_config.js"]
[loadjs storage="./data/others/js/experiment_log.js"]
[loadjs storage="./data/others/js/filter_time.js"]

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
    [chara_face name="mocha" face="magao" storage="chara/mocha/magao.png" ]
    [chara_face name="mocha" face="thinking" storage="chara/mocha/thinking.png" ]
    [chara_face name="mocha" face="sorashi" storage="chara/mocha/sorashi.png" ]
    [chara_face name="mocha" face="nico" storage="chara/mocha/nico.png" ]
    [chara_face name="mocha" face="hokkori" storage="chara/mocha/hokkori.png" ]

[chara_new name name="adviser" storage="chara/adviser/lifeform.svg" jname="アドバイザー"]
[chara_new name name="teacher" storage="chara/teacher/normal.png" jname="先生"]

; マクロ定義
[macro name=haneru]
    [anim name=%chara top="&(+mp.top - (mp.jump_h||30))" time=100 effect=easeInBounce]
    [wa]
    [anim name=%chara top=%top time=100 effect=easeInBounce]
    [wa]
[endmacro]

[macro name=yureru_x]
[iscript]
mp.amp = parseInt(mp.amp || 15);
mp.time = parseInt(mp.time || 50);
mp.count = parseInt(mp.count || 2);
[endscript]
[for name=tf.i from=1 to="&mp.count"]
[anim name=%chara left="&(+mp.left - mp.amp)" time="&mp.time" effect=easeInOutSine]
[wa]
[anim name=%chara left="&(+mp.left + mp.amp)" time="&mp.time" effect=easeInOutSine]
[wa]
[nextfor]
[anim name=%chara left=%left time="&mp.time" effect=easeInOutSine]
[wa]
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
        f.all_tasks = data;
    },
    error: function(xhr, status, error) {
        console.error("tasks.json Load Error:", error);
        f.all_tasks = { "error": { "title":"Error", "description":"Load Failed" }};
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
        f.user_id = session.user.id;
        tyrano.plugin.kag.ftag.startTag("jump", { target: "*load_user_data" });
    } else {
        // 未ログイン -> ログイン画面へ移動
        tyrano.plugin.kag.ftag.startTag("jump", { storage: "auth_anonymous.ks" });
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

var uid = f.user_id;

function applyProfileData(data) {
    data = data || {};
    f.love_level = parseInt(data.love_level) || 0;
    f.user_role = data.role || f.user_role || "control";
    f.ai_memory = data;
    f.user_name = data.name || f.user_name || "ゲスト";
    f.participant_id = data.participant_id || f.participant_id || "";
    if (f.user_role == 'control') {
        f.love_level = window.AppProgressConfig.getControlLoveLevel();
    }
    f.level = window.AppProgressConfig.getLoveGaugeState(f.love_level).level;
}

function applyProfileFallback() {
    f.love_level = window.AppProgressConfig.getControlLoveLevel();
    f.ai_memory = {};
    f.user_role = "control";
    f.user_name = f.user_name || "ゲスト";
    f.level = window.AppProgressConfig.getLoveGaugeState(f.love_level).level;
}

function loadTaskProgressAndHome() {
    function enterHome() {
        $("#loading_overlay").fadeOut(300, function(){
            if (window.ensureExperimentSessionId) window.ensureExperimentSessionId();
            if (window.logExperimentEvent) {
                window.logExperimentEvent("session_start", {
                    name: f.user_name || "",
                    love_level: f.love_level || 0,
                    level: f.level || 1,
                    cleared_task_count: Object.keys(f.cleared_tasks || {}).length
                }, { task_id: null });
            }
            tyrano.plugin.kag.ftag.startTag("jump", { storage: "home.ks", target: "*start" });
        });
    }

    function loadWatchedLecturesAndHome() {
        $.ajax({
            url: '/api/lecture-views?user_id=' + encodeURIComponent(uid),
            type: 'GET',
            dataType: 'json',
            success: function(data) {
                f.watched_lectures = data && data.watched_lectures ? data.watched_lectures : {};
                enterHome();
            },
            error: function(xhr, status, error) {
                console.warn("Lecture views restore failed:", status, error);
                f.watched_lectures = f.watched_lectures || {};
                enterHome();
            }
        });
    }

    window.sb.from('task_progress')
        .select('task_id')
        .eq('user_id', uid)
        .eq('is_cleared', true)
        .then(({ data, error }) => {
            if (data) {
                f.cleared_tasks = {};
                data.forEach(row => {
                    f.cleared_tasks[row.task_id] = true;
                });
            }
            loadWatchedLecturesAndHome();
        });
}

$.ajax({
    url: '/api/memory?user_id=' + uid,
    type: 'GET',
    dataType: 'json',
    success: function(data) {
        applyProfileData(data);
        loadTaskProgressAndHome();
    },
    error: function(xhr, status, error) {
        console.warn("Memory API failed. Trying Supabase profile fallback:", status, error);
        if (!window.sb) {
            applyProfileFallback();
            loadTaskProgressAndHome();
            return;
        }
        window.sb.from('profiles')
            .select('id,love_level,summary,learned_topics,weaknesses,last_updated,role,name,participant_id')
            .eq('id', uid)
            .single()
            .then(({ data, error }) => {
                if (data && !error) {
                    applyProfileData(data);
                } else {
                    console.warn("Supabase profile fallback failed:", error);
                    applyProfileFallback();
                }
            })
            .catch(function(e) {
                console.warn("Supabase profile fallback error:", e);
                applyProfileFallback();
            })
            .finally(function() {
                loadTaskProgressAndHome();
            });
    }
});
[endscript]

[wait time=500]
[jump storage="home.ks" target="*start"]

[s]

*menu_start
[jump storage="home.ks" target="*start"]
