# 4d-plugin-zip
4D plugin to zip and unzip.

Example
---
```
$src:=Get 4D folder(Database folder)
$dst:=System folder(Desktop)+"test.zip"
$password:=""
$ignore_dot_file:=1

$success:=Zip ($src;$dst;$password;$ignore_dot_file)

$src:=$dst
$dst:=System folder(Desktop)+"test-unzip"

$success:=Unzip ($src;$dst;$password;$ignore_dot_file)
```
