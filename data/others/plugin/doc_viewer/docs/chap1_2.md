### 1.2 文字の入力

ユーザーが打ち込んだ文字を受け取るには `std::cin` を使います。
本ソフトの課題では決まった文字が自動で入力されます。

```cpp
#include <iostream>
#include <string>

int main() {
    std::string name; // 名前を入れるための「箱」を用意
    std::cout << "名前を入力してください: ";
    std::cin >> name; // 入力された内容をnameに入れる
    std::cout << "こんにちは、" << name << "さん！" << std::endl;
    return 0;
}