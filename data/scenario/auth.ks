; auth.ks - ログイン・新規登録画面
*start

[cm]
[clearfix]
[stop_keyconfig]
@layopt layer="message0" visible=false

; 背景
[bg storage="room.jpg" time="100"]

[html]
<style>
    .switch-container {
        display: flex; align-items: center; justify-content: center;
        margin-bottom: 20px; gap: 15px; font-size: 20px; color: white;
    }
    .switch {
        position: relative; display: inline-block; width: 60px; height: 34px;
    }
    .switch input { opacity: 0; width: 0; height: 0; }
    .slider {
        position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0;
        background-color: #666; transition: .4s; border-radius: 34px;
    }
    .slider:before {
        position: absolute; content: ""; height: 26px; width: 26px;
        left: 4px; bottom: 4px; background-color: white; transition: .4s; border-radius: 50%;
    }
    input:checked + .slider { background-color: #2196F3; }
    input:checked + .slider:before { transform: translateX(26px); }
</style>

<div id="auth-box" style="
    position: absolute; 
    transform: translate(50%, 40%);
    width: 640px; 
    padding:20px; 
    background: rgba(20, 20, 30, 0.9);
    border: 1px solid #444; 
    border-radius: 8px; 
    color: white; 
    text-align: center; 
    z-index: 10000; 
    font-family: sans-serif;
    font-size:30px; 
">
    <h3 style="margin-top:0;">LOGIN</h3>
    <input type="email" id="email" placeholder="Email" style="width:100%; 
        padding:10px; 
        margin-bottom:10px; 
        box-sizing:border-box;
        font-size:24px;">
    <input type="password" id="password" placeholder="Password" 
        style="width:100%; 
            padding:10px; 
            margin-bottom:20px; 
            box-sizing:border-box;
            font-size:24px;">
    
    <div style="display:flex; gap:10px;">
        <button id="btn-login" 
            style="flex:1; padding:15px; cursor:pointer; background:#4CAF50; color:white; border:none; border-radius:30px; font-size:20px">ログイン</button>
        <button id="btn-signup-step1" 
            style="flex:1; padding:15px; cursor:pointer; background:#2196F3; color:white; border:none; border-radius:30px; font-size:20px">新規登録</button>
    </div>
    <p id="auth-msg" style="margin-top:15px; color:#ffcc00; min-height:1.5em; font-size:20px;"></p>
</div>

<div id="reg-modal" style="
    display: none;
    position: absolute; 
    transform: translate(50%, 40%);
    width: 640px; 
    padding:20px; 
    background: rgba(20, 20, 30, 0.95);
    border: 2px solid #2196F3; 
    border-radius: 8px; 
    color: white; 
    text-align: center; 
    z-index: 10001; 
    font-family: sans-serif;
">
    <h3 style="margin-top:0;">詳細設定</h3>
    <p style="font-size:18px; color:#ccc; margin-bottom:15px;">名前とモードを設定してください</p>
    
    <input type="text" id="reg-name" placeholder="ユーザー名" style="width:100%; padding:10px; margin-bottom:20px; box-sizing:border-box; font-size:24px;">
    
    <div class="switch-container">
        <span>親密度モード:</span>
        <label class="switch">
            <input type="checkbox" id="mode-toggle">
            <span class="slider"></span>
        </label>
        <span id="mode-label" style="width:200px; text-align:left;">オフ (統制群)</span>
    </div>

    <button id="btn-reg-confirm" style="width:100%; padding:15px; cursor:pointer; background:#2196F3; color:white; border:none; border-radius:30px; font-size:20px">登録を完了する</button>
    <button id="btn-reg-cancel" style="background:none; border:none; color:#888; cursor:pointer; margin-top:15px; font-size:16px;">キャンセル</button>
</div>
[endhtml]

[iscript]
// 入力伝播の防止
$("#auth-box input, #reg-modal input").on("keydown keyup keypress", function(e) {
    e.stopPropagation();
});

// トグルの表示切り替え
$("#mode-toggle").on("change", function() {
    $("#mode-label").text(this.checked ? "オン (実験群)" : "オフ (統制群)");
});

// 新規登録の第一段階
$("#btn-signup-step1").click(function() {
    if (!$("#email").val() || !$("#password").val()) {
        $("#auth-msg").text("EmailとPasswordを入力してください");
        return;
    }
    $("#auth-box").hide();
    $("#reg-modal").show();
});

// キャンセル
$("#btn-reg-cancel").click(function() {
    $("#reg-modal").hide();
    $("#auth-box").show();
});

// ログイン処理
$("#btn-login").click(async function() {
    $("#auth-msg").text("通信中...");
    const { data, error } = await window.sb.auth.signInWithPassword({
        email: $("#email").val(),
        password: $("#password").val(),
    });
    if (error) $("#auth-msg").text(error.message);
    else handleAuthSuccess(data.user.id);
});

// 最終的な登録処理
$("#btn-reg-confirm").click(async function() {
    const email = $("#email").val();
    const password = $("#password").val();
    const userName = $("#reg-name").val().trim();
    const roleValue = $("#mode-toggle").prop("checked") ? "experimental" : "control";

    if (!userName) {
        alert("ユーザー名を入力してください");
        return;
    }

    $("#btn-reg-confirm").prop("disabled", true).text("処理中...");

    // 1. サインアップを実行（options.data にプロフィール情報を含める）
    const { data, error } = await window.sb.auth.signUp({
        email: email,
        password: password,
        options: {
            data: { 
                name: userName, // トリガーがこれを拾って profiles に入れる
                role: roleValue 
            }
        }
    });

    if (error) {
        alert("エラー: " + error.message);
        $("#btn-reg-confirm").prop("disabled", false).text("登録を完了する");
        return;
    }

    // 2. 状態の判定
    // メール認証が必要な設定の場合、session は null になる
    if (data.user && data.session === null) {
        // メール認証待ちの状態
        $("#reg-modal").hide();
        $("#auth-box").show();
        $("#auth-msg").html("認証メールを送信しました。<br>メール内のリンクをクリックして認証を完了してください。");
        $("#btn-reg-confirm").prop("disabled", false).text("登録を完了する");
    } else if (data.session) {
        // メール認証が不要な設定、あるいは即座にログインできた場合
        handleAuthSuccess(data.user.id);
    }
});

const handleAuthSuccess = (userId) => {
    TYRANO.kag.stat.f.user_id = userId;
    $("#auth-box, #reg-modal").remove();
    tyrano.plugin.kag.ftag.startTag("jump", { storage: "first.ks", target: "*load_user_data" });
};
[endscript]