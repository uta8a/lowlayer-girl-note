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

- 
