###Zip

```
success:=Zip (src;dst;pass;level;options;callback;codepage)
```

パラメーター|タイプ|説明
------------|------|----
src|TEXT|圧縮したいフォルダーまたはファイルのフルパス名
dst|TEXT|作成する圧縮ファイルのフルパス名
pass|TEXT|パスワード（設定する場合）
level|INT32|圧縮率（デフォルトは``Z_DEFAULT_COMPRESSION``）
options|INT32|フラグの組み合わせ
callback|TEXT|コールバックとして使用するプロジェクトメソッド名
codepage|INT32|コードページ（デフォルト:0=UTF-8）

* 圧縮率について

下記の定数が使用できます。

```
ZIP_Compression_level_default (-1)
ZIP_Compression_level_0 (0)
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

処理が中断された場合，``success``に``0``が返されます。

####コールバックメソッドの引数

```
abort:=Callback (pathRelative;pathAbsolute;pass;total)
```

パラメーター|タイプ|説明
------------|------|----
pathRelative|TEXT|ファイル・フォルダーの相対パス名
pathAbsolute|TEXT|ファイル・フォルダーの絶対パス名
count|REAL|ファイル・フォルダーの番号
total|REAL|ファイル・フォルダーの合計数

``abort``に``True``が返されると処理を中断します。

###Unzip

```
result:=Unzip (src;dst;pass;options;callback;codepage)
```

パラメーター|タイプ|説明
------------|------|----
src|TEXT|圧縮したいフォルダーまたはファイルのフルパス名
dst|TEXT|作成する圧縮ファイルのフルパス名
pass|TEXT|パスワード（設定されている場合）
options|INT32|フラグの組み合わせ
callback|TEXT|コールバックとして使用するプロジェクトメソッド名
codepage|INT32|コードページ（デフォルト:``0``=UTF-8, ``Zip_Charset_automatic``:``-1``=自動判定）

* フラグについて

下記のものが有効です。

``ZIP_Ignore_hidden``

``ZIP_With_attributes``

####コールバックメソッドの引数

```
abort:=Callback (pathRelative;pathAbsolute;pass;total;sizeCompressed;sizeUncompressed)
```

パラメーター|タイプ|説明
------------|------|----
pathRelative|TEXT|ファイル・フォルダーの相対パス名
pathAbsolute|TEXT|ファイル・フォルダーの絶対パス名
count|REAL|ファイル・フォルダーの番号
total|REAL|ファイル・フォルダーの合計数
sizeCompressed|REAL|ファイル・フォルダーの圧縮サイズ
sizeUncompressed|REAL|ファイル・フォルダーのサイズ

``abort``に``True``が返されると処理を中断します。
