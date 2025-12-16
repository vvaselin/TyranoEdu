;=========================================
; 会話モード (Talk Mode) メインシナリオ
;=========================================
*start

[clearfix]
[add_theme_button]
[start_keyconfig]

[bg storage="room.jpg" time="0"]
[chara_new name="mocha" storage="chara/mocha/normal.png" jname="宮舞モカ"]
[chara_show name="mocha" width=600 top=100]
@layopt layer="message0" visible=true

; 変数初期化
[iscript]
f.talk_history = [];
f.script_queue = [];
f.user_input = "";
[endscript]

;-----------------------------------------
; 入力待ち状態 (Wait Input)
;-----------------------------------------
*wait_input
[cm]

[html]
<div style="
    position: absolute;
    top: 450px;
    left: 300px;
    transform: translateX(-50%);
    width: 600px;
    z-index: 999;
    text-align: center;
">
    <input type="text" id="user_input_field" placeholder="メッセージを入力..." style="
        width: 70%;
        padding: 12px;
        font-size: 18px;
        border-radius: 30px;
        border: 2px solid #aaa;
        outline: none;
    ">
    <button id="send_btn" style="
        padding: 12px 24px;
        font-size: 18px;
        cursor: pointer;
        background-color: #555;
        color: white;
        border: none;
        border-radius: 30px;
        margin-left: 10px;
    ">送信</button>
</div>
<script>
    $("#user_input_field").on("keydown", function(e) {
        if (e.key === 'Enter') $("#send_btn").click();
    });
    $("#send_btn").off("click").on("click", function(){
        var val = $("#user_input_field").val();
        if(val){
            tyrano.plugin.kag.stat.f.user_input = val;
            tyrano.plugin.kag.ftag.startTag("jump", {target:"*send_api"});
        }
    });
    $("#user_input_field").focus();
</script>
[endhtml]

[s]

;-----------------------------------------
; API送信処理
;-----------------------------------------
*send_api
[cm]
[html]
<script>
    $("#user_input_field").remove();
    $("#send_btn").remove();
</script>
[endhtml]

[iscript]
f.talk_history.push({role: "user", content: f.user_input});
[endscript]

#あなた
[emb exp="f.user_input"][p]

#
（……）

[iscript]
$.ajax({
    url: "/api/talk",
    type: "POST",
    data: JSON.stringify({
        user_id: f.user_id || "guest", 
        message: f.user_input,
        history: f.talk_history,
        mode: "quiz",
        love_level: f.love_level || 0
    }),
    contentType: "application/json",
    dataType: "json",
    success: function(data) {
        f.script_queue = data.script;
        tyrano.plugin.kag.ftag.startTag("jump", {target:"*play_loop"});
    },
    error: function(e) {
        console.error(e);
        tyrano.plugin.kag.ftag.startTag("text", {val: "（通信エラーが発生しました…）"});
        tyrano.plugin.kag.ftag.startTag("p");
        tyrano.plugin.kag.ftag.startTag("jump", {target:"*wait_input"});
    }
});
[endscript]
[s]

;-----------------------------------------
; JSON再生ループ
;-----------------------------------------
*play_loop
[iscript]
if (!f.script_queue || f.script_queue.length === 0) {
    tyrano.plugin.kag.ftag.startTag("jump", {target: "*wait_input"});
} else {
    f.current_act = f.script_queue.shift();
    
    if (f.current_act.type === "text") {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*act_text"});
    } else if (f.current_act.type === "emotion") {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*act_emotion"});
    } else if (f.current_act.type === "choices") {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*act_choices"});
    } else {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*play_loop"});
    }
}
[endscript]
[s]

*act_text
#宮舞モカ
[emb exp="f.current_act.content"]
[iscript]
f.talk_history.push({role: "assistant", content: f.current_act.content});
[endscript]
[p]
[jump target="*play_loop"]

*act_emotion
[chara_mod name="mocha" face="&f.current_act.content" time="200"]
[jump target="*play_loop"]

*act_choices
[iscript]
f.current_act.choices.forEach(function(item, i){
    tyrano.plugin.kag.ftag.startTag("glink", {
        color: "ts22",
        text: item.label,
        x: "380",
        y: 200 + (i * 80),
        width: "400",
        target: "*on_select",
        exp: "f.user_input = '" + item.value + "'"
    });
});
[endscript]
[s]

*on_select
[jump target="*send_api"]