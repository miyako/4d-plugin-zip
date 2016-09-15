* Zip

```
result:=Zip (src;dst;pass;level;options;callback)
```

パラメーター|タイプ|説明
------------|------|----
src|TEXT|圧縮したいフォルダーまたはファイルのフルパス名
dst|TEXT|作成する圧縮ファイルのフルパス名
pass|TEXT|パスワード（付与する場合）
level|INT32|圧縮率（デフォルトは``Z_DEFAULT_COMPRESSION``）
options|INT32|フラグの組み合わせ
callback|テキスト|コールバックとして使用するプロジェクトメソッド名

* 圧縮率について

下記の定数が使用できます。

```
ZIP_Compression_level_1 (1)
ZIP_Compression_level_2 (2)
ZIP_Compression_level_3 (3)
ZIP_Compression_level_4 (4)
ZIP_Compression_level_5 (5)
ZIP_Compression_level_6 (6)
ZIP_Compression_level_7 (7)
ZIP_Compression_level_8 (8)
ZIP_Compression_level_9 (9)
```

``1``は``Z_BEST_SPEED``，``9``は``Z_BEST_COMPRESSION``ということです。

``0``を指定した場合は``Z_DEFAULT_COMPRESSION``つまり``-1``になります。

``0``つまり``Z_NO_COMPRESSION``を指定することはできないということです。（しまった！）

* フラグについて

``ZIP_Ignore_hidden``

非表示ファイルや非表示フォルダーを除外します。非表示とは，

* 名前がドットから始まる
* ``NSURL``の``NSURLIsHiddenKey``属性が``YES``である（Macのみ）

いずれかの条件を満たしているアイテムのことです。

``ZIP_With_attributes``

Macの場合，ファイル属性を保持します。特にシンボリックリンクを圧縮する場合には指定が必要です。

``ZIP_Without_enclosing_folder``

指定した場合，フォルダーの内容だけを圧縮し，フォルダー名は省略します。

``ZIP_With_encryption``

AESで暗号化します。


