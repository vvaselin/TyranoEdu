### 2.2 変数の使い方

```cpp
#include <iostream>

int main() {
    int age;      // 1. 変数の宣言（箱を作る）
    age = 20;     // 2. 代入（箱に値を入れる）
    
    int score = 100; // 宣言と同時に値を入れることも可能（初期化）

    std::cout << "年齢は" << age << "歳です。" << std::endl;
    return 0;
}

```