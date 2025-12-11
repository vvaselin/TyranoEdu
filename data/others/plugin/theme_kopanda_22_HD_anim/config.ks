; 2024/09/13 @ko10panda edit

;===============================================================================

; Creating the Config Mode Screen

;===============================================================================

[mask time="100"]

[layopt layer="message0" visible="false"]
[clearfix]
[stop_keyconfig]
[free_layermode wait="true" time="0"]
[reset_camera wait="true" time="0"]
[hidemenubutton]

[iscript]

$(".layer_camera").empty();
$("#bgmovie").remove();

TG.config.autoRecordLabel = "true";

/*
 * コンフィグ内のみで使用する変数
 *
 * tf.img_path            共通：画像類のパス
 * tf.uiConfig		        コンフィグで使用する画像、サイズ、配置座標を管理するオブジェクト
 *
 * tf.index_num_bgm		    BGM音量：インデックス
 * tf.index_num_se			  SE音量：インデックス
 * tf.index_num_ch			  テキスト速度：インデックス
 * tf.index_num_auto		  オートウェイト：インデックス
 *
 * tf.current_bgm_vol		  BGM音量：現在のBGM音量
 * tf.current_se_vol		  SE音量：現在のSE音量
 * tf.current_ch_speed		テキスト速度：現在のテキスト速度
 * tf.current_auto_speed	オートウェイト：現在のオートウェイト
 *
 * tf.text_skip				    未読スキップ：現在の未読スキップの状態
 * tf.screen_size			    画面サイズ：現在の画面サイズ
 *
 * f.prev_vol_list			  BGM、SE：BGMとSEの音量とインデックスを保存する配列
 *
*/

tf.img_path = '../others/plugin/theme_kopanda_22_HD_anim/image/config/';

tf.uiConfig = {

	img_btn : tf.img_path + 'c_btn.gif',

	gauge : {
		img        : tf.img_path + 'gauge_act.png',
		img_hov    : tf.img_path + 'gauge_hov.png',
		posx       : [0, 310, 382, 454, 526, 598, 670, 742, 814, 886, 958],
		posy       : [182, 262, 342, 422],
		width      : 48,
		height     : 48
	},

	mute : {
		img        : tf.img_path + 'mute_act.png',
		img_hov    : tf.img_path + 'mute_hov.png',
		pos_bgm    : [1078, 182],
		pos_se     : [1078, 262],
		width      : 48,
		height     : 48
	},

	skip : {
		img        : tf.img_path + 'gauge_act.png',
		img_hov    : tf.img_path + 'gauge_hov.png',
		pos_off    : [310, 502],
		pos_on     : [454, 502],
		width      : 48,
		height     : 48
	},

	screen : {
		img        : tf.img_path + 'gauge_act.png',
		img_hov    : tf.img_path + 'gauge_hov.png',
		pos_full   : [814, 502],
		pos_window : [958, 502],
		width      : 48,
		height     : 48
	}
};

	tf.index_num_bgm;
	tf.index_num_se;
	tf.index_num_ch;
	tf.index_num_auto;

	tf.current_bgm_vol    = parseInt(TG.config.defaultBgmVolume);
	tf.current_se_vol     = parseInt(TG.config.defaultSeVolume);
	tf.current_ch_speed   = parseInt(TG.config.chSpeed);
	tf.current_auto_speed = parseInt(TG.config.autoSpeed);

	tf.text_skip ="ON";
		if(TG.config.unReadTextSkip != "true") {
			tf.text_skip ="OFF";
		}

	tf.screen_size = (function() {
		if ((document.FullscreenElement !== undefined && document.FullscreenElement !== null) ||
	    	(document.webkitFullscreenElement !== undefined && document.webkitFullscreenElement !== null) ||
	      	(document.msFullscreenElement !== undefined && document.msFullscreenElement !== null)) {
	    	return 'full';
	 	} else {
	  		return 'window';
		}
	})();

	switch(tf.current_bgm_vol) {
		case   0: tf.index_num_bgm =  0; break;
		case  10: tf.index_num_bgm =  1; break;
		case  20: tf.index_num_bgm =  2; break;
		case  30: tf.index_num_bgm =  3; break;
		case  40: tf.index_num_bgm =  4; break;
		case  50: tf.index_num_bgm =  5; break;
		case  60: tf.index_num_bgm =  6; break;
		case  70: tf.index_num_bgm =  7; break;
		case  80: tf.index_num_bgm =  8; break;
		case  90: tf.index_num_bgm =  9; break;
		case 100: tf.index_num_bgm = 10; break;

		default: break;
	};

	switch(tf.current_se_vol) {
		case   0: tf.index_num_se =  0; break;
		case  10: tf.index_num_se =  1; break;
		case  20: tf.index_num_se =  2; break;
		case  30: tf.index_num_se =  3; break;
		case  40: tf.index_num_se =  4; break;
		case  50: tf.index_num_se =  5; break;
		case  60: tf.index_num_se =  6; break;
		case  70: tf.index_num_se =  7; break;
		case  80: tf.index_num_se =  8; break;
		case  90: tf.index_num_se =  9; break;
		case 100: tf.index_num_se = 10; break;

		default: break;
	};

	switch(tf.current_ch_speed) {
		case 100: tf.index_num_ch =  0; break;
		case  80: tf.index_num_ch =  1; break;
		case  50: tf.index_num_ch =  2; break;
		case  40: tf.index_num_ch =  3; break;
		case  30: tf.index_num_ch =  4; break;
		case  25: tf.index_num_ch =  5; break;
		case  20: tf.index_num_ch =  6; break;
		case  11: tf.index_num_ch =  7; break;
		case   8: tf.index_num_ch =  8; break;
		case   5: tf.index_num_ch =  9; break;

		default: break;
	};

	switch(tf.current_auto_speed) {
		case 5000: tf.index_num_auto =  0; break;
		case 4500: tf.index_num_auto =  1; break;
		case 4000: tf.index_num_auto =  2; break;
		case 3500: tf.index_num_auto =  3; break;
		case 3000: tf.index_num_auto =  4; break;
		case 2500: tf.index_num_auto =  5; break;
		case 2000: tf.index_num_auto =  6; break;
		case 1300: tf.index_num_auto =  7; break;
		case  800: tf.index_num_auto =  8; break;
		case  500: tf.index_num_auto =  9; break;

		default: break;
	};

	// Array variable to store BGM and SE volumes before mute
	if(typeof f.prev_vol_list === 'undefined') {
		f.prev_vol_list = [tf.current_bgm_vol, tf.config_num_bgm, tf.current_se_vol, tf.index_num_se];
	}

[endscript]

[cm]

; background
[bg storage="&tf.img_path +'config_bg.jpg'" time="100"]
[image name="label_config" storage="&tf.img_path +'label_config.png'" layer="0" width="330" height="158" x="0" y="-10" time="100"]

; btn back
[button fix="true" graphic="&tf.img_path + 'btn_back.png'" enterimg="&tf.img_path + 'btn_back_hov.png'" activeimg="&tf.img_path + 'btn_back_clk.png'" target="*backtitle" width="160" height="100" x="16" y="604"]

[jump target="*config_page"]

*config_page

[clearstack]
;-------------------------------------------------------------------------------
; BGM Volume
;-------------------------------------------------------------------------------
[button name="bgmvol,bgmvol_10"  fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[1]"  y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol =  10; tf.index_num_bgm =  1"]
[button name="bgmvol,bgmvol_20"  fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[2]"  y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol =  20; tf.index_num_bgm =  2"]
[button name="bgmvol,bgmvol_30"  fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[3]"  y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol =  30; tf.index_num_bgm =  3"]
[button name="bgmvol,bgmvol_40"  fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[4]"  y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol =  40; tf.index_num_bgm =  4"]
[button name="bgmvol,bgmvol_50"  fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[5]"  y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol =  50; tf.index_num_bgm =  5"]
[button name="bgmvol,bgmvol_60"  fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[6]"  y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol =  60; tf.index_num_bgm =  6"]
[button name="bgmvol,bgmvol_70"  fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[7]"  y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol =  70; tf.index_num_bgm =  7"]
[button name="bgmvol,bgmvol_80"  fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[8]"  y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol =  80; tf.index_num_bgm =  8"]
[button name="bgmvol,bgmvol_90"  fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[9]"  y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol =  90; tf.index_num_bgm =  9"]
[button name="bgmvol,bgmvol_100" fix="true" target="*vol_bgm_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[10]" y="&tf.uiConfig.gauge.posy[0]" exp="tf.current_bgm_vol = 100; tf.index_num_bgm = 10"]

; Mute BGM
[button name="bgmvol,bgmvol_0"   fix="true" target="*vol_bgm_mute" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.mute.img_hov" width="&tf.uiConfig.mute.width" height="&tf.uiConfig.mute.height" x="&tf.uiConfig.mute.pos_bgm[0]" y="&tf.uiConfig.mute.pos_bgm[1]"]

;-------------------------------------------------------------------------------
; SE Volume
;-------------------------------------------------------------------------------
[button name="sevol,sevol_10"  fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[1]"  y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol =  10; tf.index_num_se =  1"]
[button name="sevol,sevol_20"  fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[2]"  y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol =  20; tf.index_num_se =  2"]
[button name="sevol,sevol_30"  fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[3]"  y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol =  30; tf.index_num_se =  3"]
[button name="sevol,sevol_40"  fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[4]"  y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol =  40; tf.index_num_se =  4"]
[button name="sevol,sevol_50"  fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[5]"  y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol =  50; tf.index_num_se =  5"]
[button name="sevol,sevol_60"  fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[6]"  y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol =  60; tf.index_num_se =  6"]
[button name="sevol,sevol_70"  fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[7]"  y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol =  70; tf.index_num_se =  7"]
[button name="sevol,sevol_80"  fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[8]"  y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol =  80; tf.index_num_se =  8"]
[button name="sevol,sevol_90"  fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[9]"  y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol =  90; tf.index_num_se =  9"]
[button name="sevol,sevol_100" fix="true" target="*vol_se_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[10]" y="&tf.uiConfig.gauge.posy[1]" exp="tf.current_se_vol = 100; tf.index_num_se = 10"]

; Mute SE
[button name="sevol,sevol_0"   fix="true" target="*vol_se_mute" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.mute.img_hov" width="&tf.uiConfig.mute.width" height="&tf.uiConfig.mute.height" x="&tf.uiConfig.mute.pos_se[0]" y="&tf.uiConfig.mute.pos_se[1]"]

;-------------------------------------------------------------------------------
; Text Speed
;-------------------------------------------------------------------------------
[button name="ch,ch_100" fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[1]"  y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed =100; tf.index_num_ch = 0"]
[button name="ch,ch_80"  fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[2]"  y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed = 80; tf.index_num_ch = 1"]
[button name="ch,ch_50"  fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[3]"  y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed = 50; tf.index_num_ch = 2"]
[button name="ch,ch_40"  fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[4]"  y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed = 40; tf.index_num_ch = 3"]
[button name="ch,ch_30"  fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[5]"  y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed = 30; tf.index_num_ch = 4"]
[button name="ch,ch_25"  fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[6]"  y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed = 25; tf.index_num_ch = 5"]
[button name="ch,ch_20"  fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[7]"  y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed = 20; tf.index_num_ch = 6"]
[button name="ch,ch_11"  fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[8]"  y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed = 11; tf.index_num_ch = 7"]
[button name="ch,ch_8"   fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[9]"  y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed =  8; tf.index_num_ch = 8"]
[button name="ch,ch_5"   fix="true" target="*ch_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[10]" y="&tf.uiConfig.gauge.posy[2]" exp="tf.set_ch_speed =  5; tf.index_num_ch = 9"]

;-------------------------------------------------------------------------------
; Auto Text Speed
;-------------------------------------------------------------------------------
[button name="auto,auto_5000" fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[1]"  y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed = 5000; tf.index_num_auto = 0"]
[button name="auto,auto_4500" fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[2]"  y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed = 4500; tf.index_num_auto = 1"]
[button name="auto,auto_4000" fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[3]"  y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed = 4000; tf.index_num_auto = 2"]
[button name="auto,auto_3500" fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[4]"  y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed = 3500; tf.index_num_auto = 3"]
[button name="auto,auto_3000" fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[5]"  y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed = 3000; tf.index_num_auto = 4"]
[button name="auto,auto_2500" fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[6]"  y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed = 2500; tf.index_num_auto = 5"]
[button name="auto,auto_2000" fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[7]"  y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed = 2000; tf.index_num_auto = 6"]
[button name="auto,auto_1300" fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[8]"  y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed = 1300; tf.index_num_auto = 7"]
[button name="auto,auto_800"  fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[9]"  y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed =  800; tf.index_num_auto = 8"]
[button name="auto,auto_500"  fix="true" target="*auto_speed_change" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.gauge.width" height="&tf.uiConfig.gauge.height" x="&tf.uiConfig.gauge.posx[10]" y="&tf.uiConfig.gauge.posy[3]" exp="tf.set_auto_speed =  500; tf.index_num_auto = 9"]

;-------------------------------------------------------------------------------
; Unread Text Skip
;-------------------------------------------------------------------------------
; Off
[button name="unread_off" fix="true" target="*skip_off" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.skip.width" height="&tf.uiConfig.skip.height" x="&tf.uiConfig.skip.pos_off[0]" y="&tf.uiConfig.skip.pos_off[1]"]

; On
[button name="unread_on"  fix="true" target="*skip_on"  graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.skip.width" height="&tf.uiConfig.skip.height" x="&tf.uiConfig.skip.pos_on[0]" y="&tf.uiConfig.skip.pos_on[1]"]

;-------------------------------------------------------------------------------
; Screen Size
;-------------------------------------------------------------------------------
; FullScreen
[button name="screen_full"   fix="true" target="*screen_full"   graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.screen.width" height="&tf.uiConfig.screen.height" x="&tf.uiConfig.screen.pos_full[0]" y="&tf.uiConfig.screen.pos_full[1]"]

; Windowed
[button name="screen_window" fix="true" target="*screen_window" graphic="&tf.uiConfig.img_btn" enterimg="&tf.uiConfig.gauge.img_hov" width="&tf.uiConfig.screen.width" height="&tf.uiConfig.screen.height" x="&tf.uiConfig.screen.pos_window[0]" y="&tf.uiConfig.screen.pos_window[1]"]

;-------------------------------------------------------------------------------
; Load on Config Mode startup
;-------------------------------------------------------------------------------
[layopt layer="0" visible="true"]

[call target="*load_bgm_img"]
[call target="*load_se_img"]
[call target="*load_ch_img"]
[call target="*load_auto_img"]
[call target="*load_skip_img"]
[call target="*load_screen_img"]

;test message
[test_message_start]

[mask_off time="300"]

[s]

;-------------------------------------------------------------------------------
; Exit Config Mode
;-------------------------------------------------------------------------------
*backtitle
[mask time="250"]

[cm]
[layopt layer="message1" visible="false"]
[endkeyframe]
[freeimage layer="0"]
[freeimage layer="base"]
[clearfix]
[clearstack]
[start_keyconfig]

[iscript]
  $(".layer_free").empty();
[endscript]

[mask_off time="10"]

[awakegame]

;===============================================================================

; Handle button click

;===============================================================================
;-------------------------------------------------------------------------------
; BGM Volume
;-------------------------------------------------------------------------------
*vol_bgm_mute
[iscript]

if(tf.current_bgm_vol != 0) {
	f.prev_vol_list[0] = tf.current_bgm_vol;
	f.prev_vol_list[1] = tf.index_num_bgm;
	tf.current_bgm_vol = 0;
	tf.index_num_bgm   = 0;
} else {
	tf.current_bgm_vol = f.prev_vol_list[0];
	tf.index_num_bgm   = f.prev_vol_list[1];
}

[endscript]

*vol_bgm_change
[free layer="0" name="bgmvol" time="0" wait="true"]
[call target="*load_bgm_img"]
[bgmopt volume="&tf.current_bgm_vol"]

[return]

;-------------------------------------------------------------------------------
; SE Volume
;-------------------------------------------------------------------------------
*vol_se_mute
[iscript]

if( tf.current_se_vol != 0 ) {
	f.prev_vol_list[2] = tf.current_se_vol;
	f.prev_vol_list[3] = tf.index_num_se;
	tf.current_se_vol  = 0;
	tf.index_num_se    = 0;
} else {
	tf.current_se_vol = f.prev_vol_list[2];
	tf.index_num_se   = f.prev_vol_list[3];
}

[endscript]

*vol_se_change
[free layer="0" name="sevol" time="0" wait="true"]
[call target="*load_se_img"]
[seopt volume="&tf.current_se_vol"]

[return]

;-------------------------------------------------------------------------------
; Text Speed
;-------------------------------------------------------------------------------
*ch_speed_change
[eval exp="tf.current_ch_speed = tf.set_ch_speed"]
[free layer="0" name="ch" time="0" wait="true"]
[call target="*load_ch_img"]
[configdelay speed="&tf.set_ch_speed"]
[test_message_reset]

[return]

;-------------------------------------------------------------------------------
; Auto Text Speed
;-------------------------------------------------------------------------------
*auto_speed_change
[eval exp="tf.current_auto_speed = tf.set_auto_speed"]
[free layer="0" name="auto" time="0" wait="true"]
[call target="*load_auto_img"]
[autoconfig speed="&tf.set_auto_speed"]

[return]

;-------------------------------------------------------------------------------
; Unread Text Skip -- Off
;-------------------------------------------------------------------------------
*skip_off
[free layer="0" name="unread_on" time="10"]
[image layer="0" name="unread_off" storage="&tf.uiConfig.skip.img" x="&tf.uiConfig.skip.pos_off[0]" y="&tf.uiConfig.skip.pos_off[1]"]
[config_record_label skip="false"]

[return]

;-------------------------------------------------------------------------------
; Unread Text Skip -- On
;-------------------------------------------------------------------------------
*skip_on
[free layer="0" name="unread_off" time="10"]
[image layer="0" name="unread_on" storage="&tf.uiConfig.skip.img" x="&tf.uiConfig.skip.pos_on[0]" y="&tf.uiConfig.skip.pos_on[1]"]
[config_record_label skip="true"]

[return]

;-------------------------------------------------------------------------------
; Screen Size -- Windowed
;-------------------------------------------------------------------------------
*screen_window
[if exp="tf.screen_size == 'full'"]
	[screen_full]
	[free layer="0" name="screen_full" time="10"]
	[image layer="0" name="screen_window" storage="&tf.uiConfig.screen.img" x="&tf.uiConfig.screen.pos_window[0]" y="&tf.uiConfig.screen.pos_window[1]"]
	[eval exp="tf.screen_size = 'window'"]
[endif]

[return]

;-------------------------------------------------------------------------------
; Screen Size -- FullScreen
;-------------------------------------------------------------------------------
*screen_full
[if exp="tf.screen_size == 'window'"]
	[screen_full]
	[free layer="0" name="screen_window" time="10"]
	[image layer="0" name="screen_full" storage="&tf.uiConfig.screen.img" x="&tf.uiConfig.screen.pos_full[0]" y="&tf.uiConfig.screen.pos_full[1]"]
	[eval exp="tf.screen_size = 'full'"]
[endif]

[return]

;===============================================================================

; Update image

;===============================================================================
*load_bgm_img
[if exp="tf.index_num_bgm == 0"]
	[image layer="0" name="bgmvol" storage="&tf.uiConfig.mute.img"  x="&tf.uiConfig.mute.pos_bgm[0]"              y="&tf.uiConfig.mute.pos_bgm[1]"]
[else]
	[image layer="0" name="bgmvol" storage="&tf.uiConfig.gauge.img" x="&tf.uiConfig.gauge.posx[tf.index_num_bgm]" y="&tf.uiConfig.gauge.posy[0]"]
[endif]

[return]

;-------------------------------------------------------------------------------
*load_se_img
[if exp="tf.index_num_se == 0"]
	[image layer="0" name="sevol" storage="&tf.uiConfig.mute.img"   x="&tf.uiConfig.mute.pos_se[0]"              y="&tf.uiConfig.mute.pos_se[1]"]
[else]
	[image layer="0" name="sevol"  storage="&tf.uiConfig.gauge.img" x="&tf.uiConfig.gauge.posx[tf.index_num_se]" y="&tf.uiConfig.gauge.posy[1]"]
[endif]

[return]

;-------------------------------------------------------------------------------
*load_ch_img
[image layer="0" name="ch" storage="&tf.uiConfig.gauge.img" x="&tf.uiConfig.gauge.posx[tf.index_num_ch + 1]" y="&tf.uiConfig.gauge.posy[2]"]

[return]

;-------------------------------------------------------------------------------
*load_auto_img
[image layer="0" name="auto"  storage="&tf.uiConfig.gauge.img" x="&tf.uiConfig.gauge.posx[tf.index_num_auto + 1]" y="&tf.uiConfig.gauge.posy[3]"]

[return]

;-------------------------------------------------------------------------------
*load_skip_img
[if exp="tf.text_skip == 'ON'"]
	[image layer="0" name="unread_on"  storage="&tf.uiConfig.skip.img" x="&tf.uiConfig.skip.pos_on[0]"  y="&tf.uiConfig.skip.pos_on[1]"]
[else]
	[image layer="0" name="unread_off" storage="&tf.uiConfig.skip.img" x="&tf.uiConfig.skip.pos_off[0]" y="&tf.uiConfig.skip.pos_off[1]"]
[endif]

[return]

;-------------------------------------------------------------------------------
*load_screen_img
[if exp="tf.screen_size == 'full'"]
	[image layer="0" name="screen_full"   storage="&tf.uiConfig.screen.img" x="&tf.uiConfig.screen.pos_full[0]"   y="&tf.uiConfig.screen.pos_full[1]"]
[else]
	[image layer="0" name="screen_window" storage="&tf.uiConfig.screen.img" x="&tf.uiConfig.screen.pos_window[0]" y="&tf.uiConfig.screen.pos_window[1]"]
[endif]

[return]
