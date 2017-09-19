# lvm_snapshot

## 概要

スナップショットリストに記載されたLVMスナップショットの操作

## 使用方法

### lvm_snapshot.sh

    スナップショットを作成します。
    # lvm_snapshot.sh create スナップショットリストのファイル名

    スナップショットをマウントします。
    # lvm_snapshot.sh mount スナップショットリストのファイル名

    スナップショットの情報を表示します。
    # lvm_snapshot.sh info スナップショットリストのファイル名

    スナップショットをアンマウントします。
    # lvm_snapshot.sh umount スナップショットリストのファイル名

    スナップショットを削除します。
    # lvm_snapshot.sh remove スナップショットリストのファイル名

### スナップショットリストの書式

    第1フィールド   第2フィールド   …
    --------------------------------------------
    src_lv_path  dest_pv_path  snap_lv_path  snap_le_number  snap_chunksize  snap_permission  mnt_dir  mnt_opt  備考 (無視される)

    ・「#」で始まる行はコメント行扱いされます。
    ・空行は無視されます。
    ・フィールド区切り文字は「タブ」とします。
    ・以下のフィールドの設定値は必須設定です。  
        スナップショット取得元論理ボリュームパス
        スナップショット取得先物理ボリュームパス
        スナップショット論理ボリュームパス
        スナップショット論理エクステント数
        マウントディレクトリ名
    ・アンマウント以外は各行の記載順に実行され、アンマウントは各行の記載順の逆順に実行されます。

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Linux

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* lvm2
* [fs_tools_unix](https://github.com/yuksiy/fs_tools_unix) (「lvm_snapshot.sh」 にて「mount」「umount」を使用する場合のみ)

## インストール

ソースからインストールする場合:

    (Linux の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

## 最新版の入手先

<https://github.com/yuksiy/lvm_snapshot>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/lvm_snapshot/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2010-2017 Yukio Shiiya
