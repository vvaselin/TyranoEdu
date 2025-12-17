;=========================================
; 会話モード (Talk Mode) - 復習クイズ
;=========================================
*start

[clearfix]
[add_theme_button]
[start_keyconfig]

[bg storage="room.jpg" time="0"]
[chara_new name="mocha" storage="chara/mocha/normal.png" jname="宮舞モカ"]
[chara_show name="mocha" width=600 top=100]
@layopt layer="message0" visible=true

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

;-----------------------------------------
; 変数初期化 & クイズ開始
;-----------------------------------------
[iscript]
f.talk_history = [];
f.script_queue = [];
f.quiz_count = 0;      // 現在の問題数
f.quiz_limit = 3;      // 最大問題数
f.user_input = "QUIZ_START"; // 初回トリガー
[endscript]

; 自動的に送信へジャンプ
[jump target="*send_api"]

;-----------------------------------------
; API送信処理
;-----------------------------------------
*send_api
[cm]

; 履歴に追加（QUIZ_STARTは見せないが、回答は見せる）
[iscript]
if(f.user_input !== "QUIZ_START"){
    f.talk_history.push({role: "user", content: f.user_input});
}
[endscript]

; 初回以外はユーザーの回答を表示
[if exp="f.user_input != 'QUIZ_START'"]
    #あなた
    [emb exp="f.user_input"][p]
    ; カウントアップ
    [iscript]
    f.quiz_count += 1;
    [endscript]
[endif]

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
        love_level: f.love_level || 0,
        quiz_count: f.quiz_count  // 現在の問題数を送信
    }),
    contentType: "application/json",
    dataType: "json",
    timeout: 30000,
    success: function(data) {
        f.script_queue = data.script;
        tyrano.plugin.kag.ftag.startTag("jump", {target:"*play_loop"});
    },
    error: function(e) {
        console.error(e);
        alert("通信エラーが発生しました");
        tyrano.plugin.kag.ftag.startTag("jump", {target:"*end_session"});
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
    // 現在の問題数が3問に達しており、かつキューも消化しきったなら終了
    if (f.quiz_count >= f.quiz_limit) {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*end_session"});
    }
} else {
    // アクション実行
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

;--- 各アクション処理 ---
*act_text
[cm]
#モカ
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
// 選択肢表示
if(f.current_act.choices && f.current_act.choices.length > 0){
    f.current_act.choices.forEach(function(item, i){
        tyrano.plugin.kag.ftag.startTag("glink", {
            color: "ts22",
            text: item.label,
            x: "190",
            y: 200 + (i * 80),
            width: "1000",
            target: "*on_select",
            exp: "f.user_input = '" + item.value + "'"
        });
    });
}
[endscript]
[s]

;--- 選択肢クリック時 ---
*on_select
[cm]
[jump target="*send_api"]

;-----------------------------------------
; セッション終了 (select.ksへ戻る)
;-----------------------------------------
*end_session
[cm]
#
（復習を終了します）[p]
[chara_hide name="mocha" time="0" ]
[jump storage="select.ks"]