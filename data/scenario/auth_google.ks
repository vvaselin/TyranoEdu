*start

[cm]
[clearfix]
[stop_keyconfig]
@layopt layer="message0" visible=false

; 背景
[bg storage="room.jpg" time="100"]
[filter layer="base" blur=5]

[html]
<div id="auth-box" style="
    position: absolute; 
    transform: translate(50%, 40%);
    width: 640px; 
    padding:40px 20px; 
    background: rgba(20, 20, 30, 0.9);
    border: 1px solid #444; 
    border-radius: 8px; 
    color: white; 
    text-align: center; 
    z-index: 10000; 
    font-family: sans-serif;
    font-size:30px; 
">
    <h3 style="margin-top:0; margin-bottom:30px;">LOGIN</h3>
    
    <button id="btn-google-login" style="
        width:100%; 
        padding:20px; 
        cursor:pointer; 
        background:#ffffff; 
        color:#757575; 
        border:none; 
        border-radius:8px; 
        font-size:22px;
        font-weight:bold;
        display:flex;
        align-items:center;
        justify-content:center;
        gap:10px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    ">
        <img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" width="24" height="24">
        大学アカウントでログイン
    </button>

    <p style="font-size:16px; color:#aaa; margin-top:20px;">
        ※ @g.ibaraki.ac.jp のみ利用可能です
    </p>
    
    <p id="auth-msg" style="margin-top:20px; color:#ffcc00; min-height:1.5em; font-size:20px;"></p>
</div>

<div id="reg-modal" style="
    display: none;
    position: absolute; 
    transform: translate(50%, 40%);
    width: 640px; 
    padding:40px 20px;
    background: rgba(20, 20, 30, 0.95);
    border: 2px solid #2196F3; 
    border-radius: 8px; 
    color: white; 
    text-align: center; 
    z-index: 10001; 
    font-family: sans-serif;
">
    <h3 style="margin-top:0;">初期設定</h3>
    <p style="font-size:18px; color:#ccc; margin-bottom:20px;">使用する名前を入力してください</p>
    
    <input type="text" id="reg-name" maxlength="10" placeholder="ユーザー名(2〜10文字)" style="width:100%; padding:10px; margin-bottom:30px; box-sizing:border-box; font-size:24px;">

    <button id="btn-reg-confirm" style="width:100%; padding:15px; cursor:pointer; background:#2196F3; color:white; border:none; border-radius:30px; font-size:20px">利用を開始する</button>
</div>
[endhtml]

[iscript]
// 入力伝播の防止
$("#reg-modal input").on("keydown keyup keypress", function(e) {
    e.stopPropagation();
});

// ログインセッションの監視
const checkSession = async () => {
    const { data: { session }, error } = await window.sb.auth.getSession();
    
    if (session) {
        const user = session.user;
        const email = user.email || "";

        // 1. ドメインチェック
        if (!email.endsWith("@g.ibaraki.ac.jp")) {
            $("#auth-msg").text("エラー：指定のドメイン以外は許可されていません。");
            await window.sb.auth.signOut();
            return;
        }

        // 2. プロフィール（名前）が登録済みか確認
        // ここでは、profilesテーブルに該当ユーザーのnameが存在するかを確認します
        const { data: profile, error: pError } = await window.sb
            .from('profiles')
            .select('name')
            .eq('id', user.id)
            .single();

        if (profile && profile.name) {
            // 登録済みならメイン画面へ
            handleAuthSuccess(user.id);
        } else {
            // 未登録（初回）なら名前入力モーダルを表示
            $("#auth-box").hide();
            $("#reg-modal").show();
        }
    }
};

// ページ読み込み時に実行
checkSession();

// Google SSOログイン実行
$("#btn-google-login").click(async function() {
    $("#auth-msg").text("Googleへリダイレクト中...");
    
    const { data, error } = await window.sb.auth.signInWithOAuth({
        provider: 'google',
        options: {
            queryParams: {
                hd: 'g.ibaraki.ac.jp' // Google側でのドメイン制限のヒント
            },
            redirectTo: window.location.origin + window.location.pathname
        }
    });

    if (error) {
        $("#auth-msg").text("ログインエラー: " + error.message);
    }
});

// 初回名前登録の確定処理
$("#btn-reg-confirm").click(async function() {
    const userName = $("#reg-name").val().trim();

    if (userName.length < 2) {
        alert("ユーザー名は2文字以上で入力してください");
        return;
    }
    const validPattern = /^[a-zA-Z0-9あ-んア-ン一-龠々]+$/;
    if (!validPattern.test(userName)) {
        alert("ユーザー名に記号やスペースは使用できません");
        return;
    }

    $("#btn-reg-confirm").prop("disabled", true).text("処理中...");

    // profilesテーブルを更新（名前を保存）
    // Supabaseの構成によりますが、通常はAuth.userのメタデータ更新か
    // profilesテーブルへのupsertを行います
    const { data: { session } } = await window.sb.auth.getSession();
    
    const { error } = await window.sb
        .from('profiles')
        .update({ name: userName })
        .eq('id', session.user.id);

    if (error) {
        alert("エラー: " + error.message);
        $("#btn-reg-confirm").prop("disabled", false).text("利用を開始する");
        return;
    }

    handleAuthSuccess(session.user.id);
});

const handleAuthSuccess = (userId) => {
    TYRANO.kag.stat.f.user_id = userId;
    $("#auth-box, #reg-modal").remove();
    // ログイン成功後は既存の処理と同様 
    tyrano.plugin.kag.ftag.startTag("jump", { storage: "first.ks", target: "*load_user_data" });
    tyrano.plugin.kag.ftag.startTag("free_filter");
};
[endscript]