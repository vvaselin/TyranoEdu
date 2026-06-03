========== ========== ========== ==========
     漫符プラグイン Ver.1.0.1
========== ========== ========== ==========

【最終更新日】2022/2/10 17:00
【  名  称  】漫符プラグイン
【  種  別  】ティラノスクリプト用の外部プラグイン
【 製 作 者 】おぎはら
【 開発環境 】ティラノスクリプトv511d, Windows 10, Google Chrome 96
【 動作環境 】上記開発環境にて確認
【 連 絡 先 】https://twitter.com/ogihara88sai
【ライセンス】MIT

---------- ----------



◇ 概要 ◇

このプラグインは、ティラノスクリプトに『漫符（まんぷ）』表示機能を実装するものです。
このプラグインを導入すると、
    [manpu layer=0 name=akane type=bikkuri]
とか、
    [manpu layer=1 name=yamato type=hatena x=-50 y=50]
とか記述することで、キャラ画像の位置を基準として漫符の表示を行うことができるようになります。



◇ ファイル構成 ◇

manpu
 ├ image
 ｜  ├ ase.png
 ｜  ├ ase2.png
 ｜  ├ bikkuri.png
 ｜  ├ bikkuri2.png
 ｜  ├ fukidashi.png
 ｜  ├ fukidashi2.png
 ｜  ├ gaan.png
 ｜  ├ hatena.png
 ｜  ├ heart.png
 ｜  ├ heart2.png
 ｜  ├ heart3.png
 ｜  ├ kiran.png
 ｜  ├ mojamoja.png
 ｜  ├ muka.png
 ｜  ├ muka2.png
 ｜  ├ nami.png
 ｜  ├ nami2.png
 ｜  ├ nanto.png
 ｜  ├ onpu.png
 ｜  ├ oya.png
 ｜  ├ pikon.png
 ｜  ├ tameiki.png
 ｜  └ waiwai.png
 ├ sound
 ｜  ├ se.ogg
 ｜  ├ se2.ogg
 ｜  ├ se3.ogg
 ｜  ├ se4.ogg
 ｜  ├ se5.ogg
 ｜  ├ se6.ogg
 ｜  ├ se7.ogg
 ｜  ├ se8.ogg
 ｜  └ se9.ogg
 ├ init.ks
 ├ manpu.css
 ├ manpu.js
 ├ _SAMPLE.ks
 └ _README.txt



◇ 導入方法 ◇

zipファイルを展開して出てきた「manpu」フォルダを
「data/others/plugin/」下にコピーしてください。
その後、first.ksに以下のタグを記述してください。

    [plugin name=manpu]

また、make.ksの[return]よりも前に以下のタグを記述してください。
※この操作を行わないと、漫符表示中にセーブされたデータを読み込んだ際に漫符が表示されたままになります。

    [manpu_reset]


◇ pluginタグに指定できるパラメータ ◇

-



◇ タグリファレンス ◇

◆ [manpu] 漫符の表示
    
    || 概要
    
    漫符を表示します。
    
    || 指定できるパラメータ
    
    layer     : 漫符を出すレイヤーを指定します。
    name      : 漫符を出す基準点とするキャラクターのnameを指定します。
    type      :【必須】漫符のタイプを指定します。デフォルトで23種が定義済。
                ase/ase2/bikkuri/bikkuri2/fukidashi/fukidashi2/gaan/hatena/heart/heart2/heart3/
                kiran/mojamoja/muka/muka2/nami/nami2/nanto/onpu/oya/pikon/tameiki/waiwai
    wait      : wait=trueを指定すると漫符表示中ウェイトします。
    x         : x座標調整。
    y         : y座標調整。
    その他    : manpu.jsの48～63行目にある記述はすべてパラメータとして指定可能です。

◆ [manpu_reset] 漫符の削除
    
    || 概要
    
    画面上のすべての漫符を削除します。
    
    || 指定できるパラメータ
    
    ありません。



◇ FAQ・既知のバグ等 ◇

-



◇ 履歴 ◇

2022/02/20 タグ[manpu_reset]が存在しないというエラーが出るバグを修正
2021/12/14 ティラノスクリプトV5用にアップデート
2018/01/30 アップデート
2017/05/11 公開
