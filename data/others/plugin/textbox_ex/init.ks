;---------------------------------------------------------------------------------------
; 2019.08.19 ko10panda edit
; 2019.09.01 change_textboxマクロにopacity属性を追加
; 2019.09.07 check_blankマクロを修正
;            storage_ok,storage_ngの指定がないときは呼び出し元のシナリオファイルにジャンプ
; 2022.03.28 アラート表示後にテキストボックスが操作できなくなっていたのを修正
;---------------------------------------------------------------------------------------

; ▼マクロ
;=======================================================================================
; テキストボックスの外観を変えるマクロ [change_textbox]
;---------------------------------------------------------------------------------------
; 設定できるパラメータ
;
; font_color    ：フォントカラー（ edit タグの color パラメータが無効化されます）
; font_weight   ：フォントを太字にするか（太字にしたいときだけ font_weight = "bold" と指定）
; bg_color      ：背景色（0xRRGGBB）
; bg_image      ：背景に読み込ませる画像（画像はimageフォルダに配置）
; bg_repeat     ：背景画像のくりかえしパターン（repeat, x-repeat, y-repeat, no-repeat）
; border_color  ：ふちどりの色（0xRRGGBB）
; border_width  ：ふちどりの太さ（px）※単位不要
; border_style　：ボーダースタイル（solid, double, groove, ridge, inset, outset, dashed, dotted）
; border_radius ：角丸の半径（px）※単位不要
; padding       ：左右の余白（px）※単位不要
; opacity　　　　：背景の不透明度（0で完全透明、255で完全不透明）
;=======================================================================================
[macro name="change_textbox"]

[iscript]

var font_color    = mp.font_color    || "0xFFFFFF",
    font_weight   = mp.font_weight   || "normal",
    bg_color      = mp.bg_color      || "0x333333",
    bg_image      = mp.bg_image      || "none",
    bg_repeat     = mp.bg_repeat     || "repeat",
    border_color  = mp.border_color  || "0xFFFFFF",
    border_width  = mp.border_width  || "3",
    border_style  = mp.border_style  || "solid",
    border_radius = mp.border_radius || "0",
    padding       = mp.padding       || "20",
    opacity       = mp.opacity       || "255",

    list_bg_repeat    = ["no-repeat", "x-repeat", "y-repeat", "repeat"],
    list_border_style = ["double", "groove", "ridge", "inset", "outset", "dashed", "dotted", "solid"];

    font_color   = font_color.replace("0x", "#");
    border_color = border_color.replace("0x", "#");
    bg_color     = bg_color.replace("0x", "#");

    var red      = parseInt( bg_color.substring(1,3), 16 );
    var green    = parseInt( bg_color.substring(3,5), 16 );
    var blue     = parseInt( bg_color.substring(5,7), 16 );
        opacity  = opacity / 255;
        bg_color = "rgba(" + red + "," + green + "," + blue + "," + opacity + ")";


    if(bg_image != "none"){
      bg_image  = 'url(data/image/' + bg_image + ')'; // 配置フォルダを変えたいときはここを編集

        if(list_bg_repeat.indexOf(bg_repeat) == -1){
          bg_repeat = "repeat";
        }

        $(".text_box").css({
          "background-image"  : bg_image,
          "background-repeat" : bg_repeat,
          "background-size"   : "auto"
        });
    }


    if(list_border_style.indexOf(border_style) == -1){
      border_style = "solid";
    }

  $(".text_box").css({
    "padding-left"     : padding + "px",
    "padding-right"    : padding + "px",
    "background-color" : bg_color,
    "border-style"     : border_style,
    "border-color"     : border_color,
    "border-width"     : border_width + "px",
    "border-radius"    : border_radius + "px",
    "box-sizing"       : "border-box",
    "color"            : font_color,
    "font-weight"      : font_weight
  });

[endscript]

[endmacro]

;=======================================================================================
; テキストボックスにフォーカスするマクロ [focus_textbox]
;---------------------------------------------------------------------------------------
; 設定できるパラメータ
; num：何番目のテキストボックスにフォーカスするか（def=0)　※番号は0からスタート
;=======================================================================================
[macro name="focus_textbox"]

  [iscript]

  var num = mp.num || "0";

  $(".text_box").eq(num).focus();

  [endscript]

[endmacro]

;=======================================================================================
; 未入力かどうかチェックするマクロ [check_blank]
;---------------------------------------------------------------------------------------
; 設定できるパラメータ
;
; var_name      ：判定したい変数名（※必須）
; show_alert    ：アラートを表示するかどうか（true of false）
; alert_message ：アラートに表示したいテキスト
; storage_ok    ：入力済のときにジャンプするシナリオファイル名（記述がないときは現在のシナリオファイルを指定）
; target_ok     ：入力済のときにジャンプするラベル名（※必須）
; storage_ng    ：未入力のときにジャンプするシナリオファイル名（記述がないときは現在のシナリオファイルを指定）
; target_ng     ：未入力のときにジャンプするラベル名（※必須）

;=======================================================================================
[macro name="check_blank"]

[iscript]

var show_alert    = mp.show_alert    || "true",
    alert_message = mp.alert_message || "未入力です",
    var_name      = mp.var_name,
    storage_ok    = mp.storage_ok,
    storage_ng    = mp.storage_ng;

    tf.check_input = var_name.length < 1 ? "false" : "true"; // 変数の長さが１未満ならfalse（=未入力）

    if(tf.check_input == "false" && show_alert == "true"){
      TYRANO.kag.ftag.startTag("dialog", {"type":alert, "text":alert_message});
    }

    if(tf.check_input == "true" && storage_ok == undefined){
      mp.storage_ok = tyrano.plugin.kag.stat.stack.macro[0].storage;
    }

    if(tf.check_input == "false" && storage_ng == undefined){
      mp.storage_ng = tyrano.plugin.kag.stat.stack.macro[0].storage;
    }

[endscript]

  [if exp="tf.check_input == 'true'"]
  [jump storage="&mp.storage_ok" target="&mp.target_ok"]
  [else]
  [jump storage="&mp.storage_ng" target="&mp.target_ng"]
  [endif]

[endmacro]

;---------------------------------------------------------------------------------------
; ▼ 関　数　str1：結果を代入したい変数名　str2：処理したい値（基本的には変数が入る）
;          システム変数で不都合がある場合は f. 変数に変えてもらって構いません
;=======================================================================================
; 空白をすべて削除 str1 = sf.del_space(str2);
;=======================================================================================
[iscript]

  sf.del_space = function(str){
    return str.replace(/(\n|\s|\t)/g, "");
  }

[endscript]

;=======================================================================================
; 半角を全角に変換 str1 = sf.to_full_width(str2);
;=======================================================================================
[iscript]

  sf.to_full_width = function(str){
    return (str + '').replace(/[!-~]/g, function(s) {
      return String.fromCharCode(s.charCodeAt(0) + 0xFEE0);
    });
  };

[endscript]

;=======================================================================================
; 全角を半角に変換 str1 = sf.to_half_width(str2);
;=======================================================================================
[iscript]

  sf.to_half_width = function(str){
    return (str + '').replace(/[！-～]/g, function(s) {
      return String.fromCharCode(s.charCodeAt(0) - 0xFEE0);
    });
  };

[endscript]

;=======================================================================================
; 文字列を数値に変換 str1 = sf.to_number(str2);
;=======================================================================================
[iscript]

  sf.to_number = function(str){
      return parseFloat(str);
  }

[endscript]

;=======================================================================================
; 半角の数字だけ残す str1 = sf.only_number(str2);
;=======================================================================================
[iscript]

  sf.only_number = function(str){
    return str.replace(/[^0-9]/g, "");
  }

[endscript]
