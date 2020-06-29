# note
- 2:22 @d0iasm: `mosh blue`
  - Mosh: mobileのような不安定な回線用のシェル
- 2:27 @d0iasm: `screen -S fizzbuzz`
  - screenコマンド: `-S`はセッションに名前をつけるオプション
  - これで電源が切れない限りジョブを動かし続けられる(SSHだと接続が切れてジョブが止まるということが起こりうる)
- 2:52 @hikalium: "ちゃんとmvしてinodeを再利用しているの優しい感じがする"
  - mvコマンド: ファイル名の変更
  - inode: [man](https://man7.org/linux/man-pages/man7/inode.7.html) 各ファイルが持っているもので、ファイルのメタデータを含んでいるものがinode statシステムコールでファイルのinode番号やメタデータの一部を得られる。
  - プロセスとinodeのつながり: プロセステーブルエントリ - ファイルテーブルエントリ - v-node(i-node)の形でつながっている
  - また、ファイル名はinodeに含まれず、ディレクトリエントリにinode番号とファイル名の組が記載されている。
  - "優しい"は何と比較して優しいのか？: inodeには限りがある。mvしたときはinodeはそのままに、新しいファイル名の入ったディレクトリエントリを追加して、古いファイル名の入ったディレクトリエントリをunlinkするのでinodeは変化しない。それに対し、rmして新規に作り直す場合、ファイル名がまず消されてunlinkされるので、inodeはシステムに回収されてしまう。そして新規に作り直すので、inodeが新しく作られることになる。この違いを指して、inodeを再利用していて優しいと言っているのかな？

```
## mvする場合 
vagrant@vagrant:~/src/low-1$ mkdir fizzbuss
vagrant@vagrant:~/src/low-1$ ls -i
114 fizzbuss
vagrant@vagrant:~/src/low-1$ mv fizzbuss/ fizzbuzz
vagrant@vagrant:~/src/low-1$ ls -i
114 fizzbuzz # inodeの番号に変化なし。優しい

## rmしてmkdirする場合
vagrant@vagrant:~/src/low-1$ mkdir fizzbuss
vagrant@vagrant:~/src/low-1$ ls -i
115 fizzbuss
vagrant@vagrant:~/src/low-1$ rm -rf fizzbuss/
vagrant@vagrant:~/src/low-1$ mkdir fizzbuzz
vagrant@vagrant:~/src/low-1$ ls -i
116 fizzbuzz # inodeの番号が+1されている
```

- 3:30 まずは何もしないexitだけのアセンブリを書く
- 3:40 `exit` syscallって何番？
- 4:07 @hikalium: "調べるのと、既存のプログラムの挙動を調べるのとどっちがいいかなあ"
  - Cでexitを呼ぶ
- 4:32 @hikalium: "return 0だとプログラムの中ではexitシステムコールが呼ばれない。戻った先でexitするけど、それはプログラムの中ではない。"
  - 検証してみた
  - gcc (Ubuntu 9.3.0-10ubuntu2) 9.3.0 `gcc -o test-exit test-exit.c`, `gcc -o test-return test-return.c` で作ったバイナリを`objdump -d -M intel test-X`でdisasした結果
  - 実際、`return`の方は`exit`はなく、retでmainからreturnしている。これはどこに返っているんだろう...(`_start`みたいなmainの前に行われるスタートアップルーチンか？) :question:

```
# exit
0000000000001149 <main>:
    1149: f3 0f 1e fa           endbr64
    114d: 55                    push   rbp
    114e: 48 89 e5              mov    rbp,rsp
    1151: bf 00 00 00 00        mov    edi,0x0
    1156: e8 f5 fe ff ff        call   1050 <exit@plt> # これはexit@GLIBC_2.2.5
    115b: 0f 1f 44 00 00        nop    DWORD PTR [rax+rax*1+0x0]

# return
0000000000001129 <main>:
    1129: f3 0f 1e fa           endbr64
    112d: 55                    push   rbp
    112e: 48 89 e5              mov    rbp,rsp
    1131: b8 00 00 00 00        mov    eax,0x0
    1136: 5d                    pop    rbp
    1137: c3                    ret
    1138: 0f 1f 84 00 00 00 00  nop    DWORD PTR [rax+rax*1+0x0]
    113f: 00
(exitなし)
```

- 5:32 @hikalium: "`man 3`でみれる"
  - `man 3 exit`
  - `3`オプションでどのライブラリからインクルードするかがわかる
  - Ubuntuだと`sudo apt install manpages-dev`が必要かもしれない。

```
SYNOPSIS
       #include <stdlib.h>

       void exit(int status);
```

- 5:50 @d0iasm: "`man 2`は？"
  - 各オプションについては`man man`で見れる。
  - `2`はシステムコール、`3`はライブラリコールになっている。

```
       1   Executable programs or shell commands
       2   System calls (functions provided by the kernel)
       3   Library calls (functions within program libraries)
       4   Special files (usually found in /dev)
       5   File formats and conventions, e.g. /etc/passwd
       6   Games
       7   Miscellaneous (including macro packages and conventions), e.g. man(7), groff(7)
       8   System administration commands (usually only for root)
       9   Kernel routines [Non standard]
```

- 7:32 PLTについて
  - Procedure Linkage Table
  - 動的ライブラリのシンボル解決を遅延させるための仕組み
- 8:31 @hikalium: "staticにリンクしたいけど、それはコンパイル時には出てこない"
  - 通常、実行ファイルは コンパイル→リンク→(リンク後の実行可能な状態になる)→ロード の順に行われて実行されるので、コンパイルより先の工程はできないという意味？
  - 調べてみると、gccはコンパイル後にリンカ(ld)を呼び出してリンクも行うらしいので、オプションとして渡せる。`-Wl,[Option],[Option]...`の形でいけるらしい。やってみる。 -> できなかった。
  - :question: `-static` `-Wl,-Bstatic`の違いは？どちらもldにオプションを渡しているのではないの？

```
vagrant@vagrant:~/src/low-1$ file exit-zero
exit-zero: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=e5c040eca868a2cc93fdd79791a293e73c39de36, for GNU/Linux 3.2.0, not stripped
vagrant@vagrant:~/src/low-1$ file exit-zero-static
exit-zero-static: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=63b3f8c53ced8d9948721398f1f708b5f11615f0, for GNU/Linux 3.2.0, not stripped

# gcc exit-zero.c -o exit-zero
# dynamically linked
0000000000001149 <main>:
    1149:       f3 0f 1e fa             endbr64
    114d:       55                      push   rbp
    114e:       48 89 e5                mov    rbp,rsp
    1151:       bf 00 00 00 00          mov    edi,0x0
    1156:       e8 f5 fe ff ff          call   1050 <exit@plt>
    115b:       0f 1f 44 00 00          nop    DWORD PTR [rax+rax*1+0x0]

# gcc exit-zero.c -o exit-zero-static -static
# statically linked
0000000000401ce5 <main>:
  401ce5:       f3 0f 1e fa             endbr64
  401ce9:       55                      push   rbp
  401cea:       48 89 e5                mov    rbp,rsp
  401ced:       bf 00 00 00 00          mov    edi,0x0
  401cf2:       e8 c9 e3 00 00          call   4100c0 <exit>
  401cf7:       66 0f 1f 84 00 00 00    nop    WORD PTR [rax+rax*1+0x0]
  401cfe:       00 00

## -Wlでldにオプションを渡そうとしたときのエラー
vagrant@vagrant:~/src/low-1$ gcc exit-zero.c -o exit-zero-static -Wl,-Bstatic
/usr/bin/ld: cannot find -lgcc_s
/usr/bin/ld: cannot find -lgcc_s
collect2: error: ld returned 1 exit status
```

- 11:08 exit発見、syscall発見

```
# gcc exit-zero.c -o exit-zero-static -static
# objdumpして、"exit>" で検索をかけた

0000000000447db0 <_exit>:
  447db0:       f3 0f 1e fa             endbr64
  447db4:       49 c7 c1 c0 ff ff ff    mov    r9,0xffffffffffffffc0
  447dbb:       89 fa                   mov    edx,edi
  447dbd:       41 b8 e7 00 00 00       mov    r8d,0xe7
  447dc3:       be 3c 00 00 00          mov    esi,0x3c
  447dc8:       eb 15                   jmp    447ddf <_exit+0x2f>
  447dca:       66 0f 1f 44 00 00       nop    WORD PTR [rax+rax*1+0x0]
  447dd0:       89 d7                   mov    edi,edx
  447dd2:       89 f0                   mov    eax,esi
  447dd4:       0f 05                   syscall
  447dd6:       48 3d 00 f0 ff ff       cmp    rax,0xfffffffffffff000
  447ddc:       77 22                   ja     447e00 <_exit+0x50>
  447dde:       f4                      hlt
  447ddf:       89 d7                   mov    edi,edx
  447de1:       44 89 c0                mov    eax,r8d
  447de4:       0f 05                   syscall
  447de6:       48 3d 00 f0 ff ff       cmp    rax,0xfffffffffffff000
  447dec:       76 e2                   jbe    447dd0 <_exit+0x20>
  447dee:       f7 d8                   neg    eax
  447df0:       64 41 89 01             mov    DWORD PTR fs:[r9],eax
  447df4:       eb da                   jmp    447dd0 <_exit+0x20>
  447df6:       66 2e 0f 1f 84 00 00    nop    WORD PTR cs:[rax+rax*1+0x0]
  447dfd:       00 00 00
  447e00:       f7 d8                   neg    eax
  447e02:       64 41 89 01             mov    DWORD PTR fs:[r9],eax
  447e06:       eb d6                   jmp    447dde <_exit+0x2e>
  447e08:       0f 1f 84 00 00 00 00    nop    DWORD PTR [rax+rax*1+0x0]
```

- 11:37 @d0iasm: 記法について
  - 動画内ではAT&T記法をつかっている。`-M intel`オプションをobjdumpにつけるとインテル記法で読める。
- 12:12 @hikalium: "intel syntaxつけてないからかな"
  - `.intel_syntax` directiveをつけるとintel記法が使える。今はGNUアセンブラ(GAS)での話なので、referenceとしては`binutils > as`を見ればよさそう？ [link](https://sourceware.org/binutils/docs-2.18/as/i386_002dSyntax.html#i386_002dSyntax)
- 12:50 @hikalium: "mainがないって怒られると思うよ"
  - やってみたら実際怒られた
  - linker(ld)が、mainがないよ！と言っている

```
vagrant@vagrant:~/src/low-1$ gcc fizzbuzz.s
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/9/../../../x86_64-linux-gnu/Scrt1.o: in function `_start':
(.text+0x24): undefined reference to `main'
collect2: error: ld returned 1 exit status
```

- 16:47 @hikalium: "globalってつけてないからかも"
  - binutil as [link](https://sourceware.org/binutils/docs-2.18/as/Global.html#Global) symbolがldから見えるようにする。

```
vagrant@vagrant:~/src/low-1$ gcc fizzbuzz.s -c -o fizzbuzz.o
vagrant@vagrant:~/src/low-1$ ld -e main -o fizzbuzz.bin fizzbuzz.o
ld: warning: cannot find entry symbol main; defaulting to 0000000000401000
```

- 15:50 @hikalium: "0x3cではない適当な数字を入れてみたら落ちるのでは？"
  - 0x3dを入れてみた

```
vagrant@vagrant:~/src/low-1$ gcc fizzbuzz.s -c -o fizzbuzz.o
vagrant@vagrant:~/src/low-1$ ld -e main -o fizzbuzz.bin fizzbuzz.o
vagrant@vagrant:~/src/low-1$ ./fizzbuzz.bin
Segmentation fault (core dumped) # 落ちた！
vagrant@vagrant:~/src/low-1$ echo $?
139
```

- 16:41 @d0iasm: "システムコールテーブルっていうのを見つけた"
  - `sys_call_table` :question: これ何を指すのかよくわからず。
- 17:05 @d0iasm: "システムコールのwriteは..."
  - :question: これreferenceとしてどこを見ればいいのかわからず...(System V ABIの話かと思ったら違うっぽい)
  - file descripter 
- 18:26 @hikalium: "Read Onlyだから、データ領域に置かなくても大丈夫なんじゃない？"
- 18:49 @hikalium: "なんで頭にアンダーバーをつけたの？"
  - MacだとSymbolの先頭にアンダーバーがつく
  - 昔のLinuxもアンダーバーがついていた。 Cのアセンブリのシンボルと重ならないようにしてたが、最近は重ならなくなったのでアンダーバーはなくなった
- 20:36 アドレスを代入するには
  - `lea rsi, [string]`
- 22:25 @hikalium: 64bit rip相対
- 26:07 @d0iasm: 3項書ける？
  - d0iasmさんはRISC-Vの方なので、RV32Iのインストラクションセットを調べてみた。
  - RV32I: RISC-Vの基本のISA(インストラクション セット アーキテクチャ)モジュール
  - `addi rd, rs1, immediate` レジスタrs1 + 即値immediate(符号拡張したもの)の結果をレジスタrdに入れる。
  - ほんとに3項だ。
- 26:48 @d0iasm: `j`
  - RISC-V `j offset` でジャンプ
  - [ref](https://content.riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf) p.110 table 20.2
- 28:18 @d0iasm: `beq`
  - レジスタrs1, rs2が等しいか見る
  - [ref](https://content.riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf) p.17 Conditional Branches
- 

