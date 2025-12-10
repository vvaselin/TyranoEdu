; auth.ks - ログイン画面
*start

[cm]
[clearfix]
; キー操作を無効化
[stop_keyconfig]
; メッセージ枠を消す
@layopt layer="message0" visible=false

; 背景
[bg storage="room.jpg" time="100"]

[html]
<div id="auth-box" style="
    position: absolute; top: 50%; left: 50%; transform: translate(50%, 50%);
    width: 360px; padding: 30px; background: rgba(20, 20, 30, 0.9);
    border: 1px solid #444; border-radius: 8px; color: white; text-align: center; z-index: 10000; font-family: sans-serif;
">
    <h3 style="margin-top:0;">LOGIN</h3>
    <input type="email" id="email" placeholder="Email" style="width:100%; padding:10px; margin-bottom:10px; box-sizing:border-box;">
    <input type="password" id="password" placeholder="Password" style="width:100%; padding:10px; margin-bottom:20px; box-sizing:border-box;">
    
    <div style="display:flex; gap:10px;">
        <button id="btn-login" style="flex:1; padding:10px; cursor:pointer; background:#4CAF50; color:white; border:none;">ログイン</button>
        <button id="btn-signup" style="flex:1; padding:10px; cursor:pointer; background:#2196F3; color:white; border:none;">新規登録</button>
    </div>
    <p id="auth-msg" style="margin-top:15px; font-size:12px; color:#ffcc00; min-height:1.5em;"></p>
</div>
[endhtml]

[iscript]
$("#auth-box input").on("keydown keyup keypress", function(e) {
    e.stopPropagation();
});

// 成功時の処理
const handleAuthSuccess = (userId) => {
    $("#auth-msg").text("成功！データを読み込みます...");
    TYRANO.kag.stat.f.user_id = userId; // IDを保存
    $("#auth-box").remove(); // UIを消す
    
    tyrano.plugin.kag.ftag.startTag("jump", { storage: "first.ks", target: "*load_user_data" });
};

// ログインボタン
$("#btn-login").click(async function() {
    $("#auth-msg").text("通信中...");
    const { data, error } = await window.sb.auth.signInWithPassword({
        email: $("#email").val(),
        password: $("#password").val(),
    });
    if (error) $("#auth-msg").text(error.message);
    else handleAuthSuccess(data.user.id);
});

// 登録ボタン
$("#btn-signup").click(async function() {
    const { data, error } = await window.sb.auth.signUp({
        email: $("#email").val(),
        password: $("#password").val(),
        options: {
            // メール確認後の戻り先を指定（設定したSite URLと合わせる）
            emailRedirectTo: 'http://localhost:8088/index.html' 
        }
    });

    if (error) {
        $("#auth-msg").text("エラー: " + error.message);
    } else {
        // セッションがあるか確認（確認不要設定なら即座にsessionが入る）
        if (data.session) {
            handleAuthSuccess(data.user.id);
        } else {
            // 確認メールONの場合、ここに来る
            $("#auth-msg").html("確認メールを送信しました。<br>メール内のリンクをクリックしてから<br>再度ログインしてください。");
        }
    }
});
[endscript]

[s]