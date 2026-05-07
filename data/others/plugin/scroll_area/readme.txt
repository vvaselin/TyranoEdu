■ スクロールエリアプラグイン

このプラグインは、横スクロールエリアと縦スクロールエリアを作成できます。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
【横スクロールエリア】
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

■ scroll_area タグ（横スクロールエリアを作成）

[scroll_area id="area1" width="1280" height="720" contents_w="3000" top="0" left="0" zindex="20000000"]

必須パラメータ:
  id         : エリアのID（一意の名前）
  width      : エリアの表示幅（px）
  height     : エリアの表示高さ（px）
  contents_w : 内部コンテンツの幅（px）※この幅だけ横スクロールできる

オプションパラメータ:
  top        : 上端位置（px）デフォルト: 0
  left       : 左端位置（px）デフォルト: 0
  zindex     : z-index値 デフォルト: 20000000

■ scroll_area_in タグ（要素をスクロールエリア内に配置）

[scroll_area_in id="area1" name="button1,button2,image1"]

パラメータ:
  id   : 配置先のエリアID
  name : 配置する要素のクラス名（カンマ区切りで複数指定可能）

■ scroll_area_del タグ（スクロールエリアを削除）

[scroll_area_del id="area1"]

パラメータ:
  id : 削除するエリアID


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
【縦スクロールエリア】
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

■ scroll_area_vertical タグ（縦スクロールエリアを作成）

[scroll_area_vertical id="area_v1" width="1280" height="720" contents_h="2000" top="0" left="0" zindex="20000000"]

必須パラメータ:
  id         : エリアのID（一意の名前）
  width      : エリアの表示幅（px）
  height     : エリアの表示高さ（px）
  contents_h : 内部コンテンツの高さ（px）※この高さだけ縦スクロールできる

オプションパラメータ:
  top        : 上端位置（px）デフォルト: 0
  left       : 左端位置（px）デフォルト: 0
  zindex     : z-index値 デフォルト: 20000000

■ scroll_area_vertical_in タグ（要素をスクロールエリア内に配置）

[scroll_area_vertical_in id="area_v1" name="button1,button2,image1"]

パラメータ:
  id   : 配置先のエリアID
  name : 配置する要素のクラス名（カンマ区切りで複数指定可能）

■ scroll_area_vertical_del タグ（スクロールエリアを削除）

[scroll_area_vertical_del id="area_v1"]

パラメータ:
  id : 削除するエリアID


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
【使用例】
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

■ 横スクロールエリアの例

; ボタンを作成
[button name="btn1" graphic="button1.png" x="100" y="200" fix="true"]
[button name="btn2" graphic="button2.png" x="500" y="200" fix="true"]
[button name="btn3" graphic="button3.png" x="1000" y="200" fix="true"]

; 横スクロールエリアを作成（幅1280px、高さ500px、内部コンテンツは幅3000px）
[scroll_area id="horizontal_area" width="1280" height="500" contents_w="3000" top="100" left="0"]

; ボタンをスクロールエリア内に配置
[scroll_area_in id="horizontal_area" name="btn1,btn2,btn3"]

; 削除する場合
[scroll_area_del id="horizontal_area"]


■ 縦スクロールエリアの例

; 画像を作成
[image name="img1" storage="image1.png" x="200" y="100" layer="fix"]
[image name="img2" storage="image2.png" x="200" y="600" layer="fix"]
[image name="img3" storage="image3.png" x="200" y="1200" layer="fix"]

; 縦スクロールエリアを作成（幅800px、高さ720px、内部コンテンツは高さ2000px）
[scroll_area_vertical id="vertical_area" width="800" height="720" contents_h="2000" top="0" left="240"]

; 画像をスクロールエリア内に配置
[scroll_area_vertical_in id="vertical_area" name="img1,img2,img3"]

; 削除する場合
[scroll_area_vertical_del id="vertical_area"]


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
【機能】
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

・マウスホイールでのスクロール対応
・矢印ボタン（◀▶または▲▼）でのスクロール
・ボタン長押しで連続スクロール
・タッチデバイス対応
・カスタマイズ可能なスクロールバー（緑色）
・グラデーション背景（横スクロール: 90度、縦スクロール: 180度）


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
【注意事項】
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

・エリアに配置する要素は、事前に作成しておく必要があります
・要素のクラス名（name属性）を使って配置します
・同じIDのエリアを複数作成しないでください
・エリアを削除する際は、対応するdelタグを使用してください
