*start

[cm]
[clearfix]
[hidemenubutton]
[stop_keyconfig]
@layopt layer="message0" visible=false

[bg storage="room.jpg" time="100"]
[filter layer="base" blur=5]

[html]
<div id="anon-auth-box" style="
    position:absolute;
    left:650px;
    top:350px;
    transform:translate(-50%, -50%);
    width:640px;
    padding:40px 28px;
    box-sizing:border-box;
    background:rgba(20, 20, 30, 0.92);
    border:1px solid rgba(255,255,255,0.28);
    border-radius:10px;
    color:white;
    text-align:center;
    z-index:10000;
    font-family:'BIZ UDPGothic','MS PGothic',sans-serif;
">
    <h3 style="margin:0 0 24px 0; font-size:30px;">利用登録</h3>
    <p style="margin:0 0 26px 0; font-size:18px; line-height:1.8; color:#ddd;">
        アプリ内で表示する名前を入力してください。
    </p>

    <input type="text" id="anon-display-name" maxlength="10" placeholder="表示名（2〜10文字）" style="
        width:100%;
        padding:14px 16px;
        margin-bottom:14px;
        box-sizing:border-box;
        border:2px solid rgba(255,255,255,0.35);
        border-radius:8px;
        background:#fff;
        color:#222;
        font-size:24px;
        outline:none;
    ">

    <input type="text" id="anon-participant-id" maxlength="8" placeholder="学籍番号" autocapitalize="characters" autocomplete="off" style="
        width:100%;
        padding:14px 16px;
        margin-bottom:22px;
        box-sizing:border-box;
        border:2px solid rgba(255,255,255,0.35);
        border-radius:8px;
        background:#fff;
        color:#222;
        font-size:24px;
        outline:none;
    ">

    <button id="btn-anon-register" style="
        width:100%;
        padding:16px;
        cursor:pointer;
        background:#159f96;
        color:white;
        border:none;
        border-radius:30px;
        font-size:22px;
        font-weight:bold;
        box-shadow:0 4px 10px rgba(0,0,0,0.25);
    ">はじめる</button>

    <p id="anon-auth-msg" style="
        margin:20px 0 0 0;
        color:#ffdd66;
        min-height:1.5em;
        font-size:17px;
        line-height:1.6;
    "></p>
</div>
[endhtml]

[iscript]
$("#anon-auth-box input").on("keydown keyup keypress", function(e) {
    e.stopPropagation();
});

function setAnonMessage(message) {
    $("#anon-auth-msg").text(message || "");
}

function setAnonBusy(isBusy) {
    $("#btn-anon-register")
        .prop("disabled", isBusy)
        .css("opacity", isBusy ? 0.65 : 1)
        .text(isBusy ? "登録中..." : "はじめる");
}

function isValidDisplayName(name) {
    return /^[A-Za-z0-9ぁ-んァ-ヶ一-龠々ー]{2,10}$/.test(name);
}

function normalizeParticipantId(participantId) {
    return participantId.trim().toUpperCase();
}

function isValidParticipantId(participantId) {
    return /^\d{2}[A-Z]{1,2}\d{3}[A-Z]$/.test(participantId);
}

function isDuplicateParticipantError(error) {
    var message = String((error && (error.message || error.details || error.hint || error.code)) || "");
    return message.indexOf("participant_id") >= 0 || message.indexOf("already registered") >= 0 || message.indexOf("duplicate") >= 0 || message.indexOf("23505") >= 0;
}

async function completeRegistration(session, displayName, participantId) {
    const { data, error } = await window.sb.rpc("complete_anonymous_registration", {
        display_name: displayName,
        input_participant_id: participantId
    });

    if (error) {
        throw error;
    }

    var registeredParticipantId = "";
    if (Array.isArray(data) && data.length > 0) {
        registeredParticipantId = data[0].participant_id || "";
    } else if (data && data.participant_id) {
        registeredParticipantId = data.participant_id;
    } else if (typeof data === "string") {
        registeredParticipantId = data;
    }

    f.user_id = session.user.id;
    f.user_name = displayName;
    f.participant_id = registeredParticipantId;
    f.tutorial_from_home = false;
    $("#anon-auth-box").remove();
    tyrano.plugin.kag.ftag.startTag("jump", { storage: "tutorial/intro.ks", target: "*start" });
    tyrano.plugin.kag.ftag.startTag("free_filter");
}

async function getCurrentSession() {
    const { data: { session } } = await window.sb.auth.getSession();
    return session;
}

async function checkExistingAnonymousSession() {
    const session = await getCurrentSession();
    if (!session) return;

    const { data: profile } = await window.sb
        .from("profiles")
        .select("name, participant_id")
        .eq("id", session.user.id)
        .single();

    if (profile && profile.name && profile.participant_id) {
        f.user_id = session.user.id;
        f.user_name = profile.name;
        f.participant_id = profile.participant_id;
        $("#anon-auth-box").remove();
        tyrano.plugin.kag.ftag.startTag("jump", { storage: "first.ks", target: "*load_user_data" });
        tyrano.plugin.kag.ftag.startTag("free_filter");
    }
}

checkExistingAnonymousSession();

$("#btn-anon-register").off("click").on("click", async function() {
    const displayName = $("#anon-display-name").val().trim();
    const participantId = normalizeParticipantId($("#anon-participant-id").val());

    if (!isValidDisplayName(displayName)) {
        setAnonMessage("表示名は2〜10文字で入力してください。空白や記号は使えません。");
        return;
    }

    if (!isValidParticipantId(participantId)) {
        setAnonMessage("学籍番号は 25NM741R または 25N741R の形式で入力してください。");
        return;
    }

    setAnonBusy(true);
    setAnonMessage("");

    try {
        let session = await getCurrentSession();
        if (!session) {
            const { data, error } = await window.sb.auth.signInAnonymously();
            if (error) throw error;
            session = data.session;
        }
        if (!session) throw new Error("匿名セッションを作成できませんでした。");

        await completeRegistration(session, displayName, participantId);
    } catch (error) {
        if (window.sb) await window.sb.auth.signOut();
        console.error("Anonymous registration error:", error);
        setAnonMessage(isDuplicateParticipantError(error) ? "この学籍番号はすでに登録されています。" : "登録に失敗しました。時間をおいてもう一度試してください。");
        setAnonBusy(false);
    }
});
[endscript]
