*start
[cm]
[clearfix]
[start_keyconfig]

; 背景と立ち絵の初期化（必要に応じて変更してください）
[bg storage="room.jpg" time="1000"]
[chara_show name="mocha" time="1000" top="50"]

; メッセージウィンドウの設定
[position layer="message0" left=20 top=400 width=920 height=200 page=fore visible=true]
[layopt layer=message0 visible=true]

; 変数初期化
[iscript]
f.talk_history = [];    // 会話履歴
f.script_queue = [];    // 実行待ちのアクションリスト
f.user_input = "";      // ユーザーの入力テキスト
[endscript]

;-----------------------------------------
; 入力待ち状態 (Wait Input)
;-----------------------------------------
*wait_input
[cm]

; ユーザー入力を受け付ける（editタグまたはボタンで実装）
; ここでは簡易的に「テキスト入力欄」と「決定ボタン」を表示します
[html]
<div style="position:absolute; top:300px; left:100px; z-index:999;">
    <input type="text" id="user_input_field" style="width:600px; height:40px; font-size:24px;">
    <button id="send_btn" style="height:46px; font-size:24px;">話しかける</button>
</div>
<script>
    $("#send_btn").off("click").on("click", function(){
        var val = $("#user_input_field").val();
        if(val){
            // ティラノの変数にセットしてジャンプ
            tyrano.plugin.kag.stat.f.user_input = val;
            tyrano.plugin.kag.ftag.startTag("jump", {target:"*send_api"});
        }
    });
</script>
[endhtml]

[s]

;-----------------------------------------
; API送信処理
;-----------------------------------------
*send_api
[cm]
; 入力欄を消去
[html]
<script>
    $("#user_input_field").remove();
    $("#send_btn").remove();
</script>
[endhtml]

; ユーザーの発言を表示（履歴に追加）
[iscript]
f.talk_history.push({role: "user", content: f.user_input});
[endscript]
#あなた
[emb exp="f.user_input"][p]

#
（考え中...）

; サーバーへ送信
[iscript]
$.ajax({
    url: "/api/talk",
    type: "POST",
    data: JSON.stringify({
        user_id: f.user_id, // ログイン時に設定されている想定
        message: f.user_input,
        history: f.talk_history,
        mode: "quiz" // "chat" or "quiz" を状況で切り替え
    }),
    contentType: "application/json",
    dataType: "json",
    success: function(data) {
        // 受け取ったスクリプトをキューに格納
        f.script_queue = data.script;
        // 再生ループへ
        tyrano.plugin.kag.ftag.startTag("jump", {target:"*play_loop"});
    },
    error: function(e) {
        alert("通信エラーが発生しました");
        tyrano.plugin.kag.ftag.startTag("jump", {target:"*wait_input"});
    }
});
[endscript]
[s]

;-----------------------------------------
; JSON再生ループ (Main Loop)
;-----------------------------------------
*play_loop

; キューが空なら入力待ちへ戻る
[iscript]
if (f.script_queue.length === 0) {
    tyrano.plugin.kag.ftag.startTag("jump", {target: "*wait_input"});
} else {
    // 先頭の要素を取り出す
    f.current_act = f.script_queue.shift();
    
    // タイプに応じてジャンプ先を決定
    if (f.current_act.type === "text") {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*act_text"});
    } else if (f.current_act.type === "emotion") {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*act_emotion"});
    } else if (f.current_act.type === "choices") {
        tyrano.plugin.kag.ftag.startTag("jump", {target: "*act_choices"});
    }
}
[endscript]
[s]

;--- アクション: テキスト表示 ---
*act_text
#宮舞モカ
[emb exp="f.current_act.content"]
; 履歴にも追加（AIの発言として）
[iscript]
f.talk_history.push({role: "assistant", content: f.current_act.content});
[endscript]
[p]
[jump target="*play_loop"]

;--- アクション: 表情変更 ---
*act_emotion
[chara_mod name="mocha" face="&f.current_act.content" time="200"]
[jump target="*play_loop"]

;--- アクション: 選択肢表示 ---
*act_choices
[iscript]
// 選択肢ボタンを動的に生成
f.current_act.choices.forEach(function(item, i){
    // glinkタグをJavaScriptから発行
    tyrano.plugin.kag.ftag.startTag("glink", {
        color: "blue",
        text: item.label,
        x: "200",
        y: 200 + (i * 80),
        target: "*on_select",
        exp: "f.user_input = '" + item.value + "'" // 選択した値を次の入力とする
    });
});
[endscript]
[s]

;--- 選択肢が選ばれた時 ---
*on_select
; 選んだ内容をそのままAPI送信フローへ回す
[jump target="*send_api"]