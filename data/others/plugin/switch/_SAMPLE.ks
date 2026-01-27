
[plugin name=switch]

[wait time=300]

[iscript]
f.name = "太郎"
f.num = 25
[endscript]



f.name=[emb exp=f.name]、f.num=[emb exp=f.num]でテスト。[r][r]



■ f.nameが太郎か花子かでswitch分岐[r]……
[switch exp=f.name]
[case is=太郎]
  太郎だ。
[case is=花子]
  花子だ。
[case]
  花子でも太郎でもない。
[endswitch]
[l][r][r]



■ f.numが20か40かでswitch分岐[r]……
[switch exp=f.num]
[case is=20]
  20だ。
[case is=40]
  40だ。
[case]
  20でも40でもない。
[endswitch]
[l][r][r]



■ f.numが「20以下」か「20より大きく40以下」かでswitch分岐[r]……
[switch exp=f.num]
[case is=~20]
  20以下だ。
[case is=~40]
  20より大きく40以下だ。
[case]
  どちらでもない(40より大きい数値である、もしくは数値ですらない)。
[endswitch]
[l][r][r]



■ f.numが「25以上35以下」かどうかでswitch分岐[r]……
[switch exp=f.num]
[case is=25~35]
  「25以上35以下」だ。
[case]
  「25以上35以下」ではない。
[endswitch]
[l][r][r]



■ f.numが「0以下」か「0より大きく100以下」かでswitch分岐[r]……
[switch exp=f.num]
[case is=~0]
  0以下だ。
[case is=~100]
  0より大きく100以下だ。
[case]
  いずれでもない(100より大きい数値である、もしくは数値ですらない)。
[endswitch]
[l][r][r]



サンプルおわり[s]