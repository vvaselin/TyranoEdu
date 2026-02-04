;スタイルシート呼び出し
[loadcss file="./data/others/plugin/turnover/style.css"]
; マクロ作成
[macro name="turn_start"]
  [iscript]
    $('#root_layer_game').addClass("turn_start");
    $('#root_layer_system').addClass("turn_start");
  [endscript]
  [wait time="800"]
[endmacro]

[macro name="turn_end"]
  [iscript]
    $('#root_layer_game').removeClass("turn_start").addClass("turn_end");
    $('#root_layer_system').removeClass("turn_start").addClass("turn_end");
  [endscript]
  [wait time="810"]
  [iscript]
    $('#root_layer_game').removeClass("turn_end");
    $('#root_layer_system').removeClass("turn_end");
  [endscript]
[endmacro]

@return