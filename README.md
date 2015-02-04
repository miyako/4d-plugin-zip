# 4d-plugin-zip
4D plugin to zip and unzip.

Important
---
This plugin project is a forked subset of what was published as [OAuth](https://github.com/miyako/4d-plugin-oauth).

Existing commands have the same name and functionality, but their tokens (internal IDs) have changed.

To migrate existing methods, do the following:

1. Comment the code that calls ```Zip``` or ```Unzip``` commands.
2. Close 4DB.
3. Replace the plugin.
4. Uncomment the code.
 
New
---

Pass 1 to as the fourth parameter to ignore files and folders whose name begins with a dot.


Example
---
```
$src:=Get 4D folder(Database folder)
$dst:=System folder(Desktop)+"test.zip"
$password:=""
$compression_level:=1
$ignore_dot:=1

$success:=Zip ($src;$dst;$password;$compression_level;$ignore_dot)

$src:=$dst
$dst:=System folder(Desktop)+"test"

$success:=Unzip ($src;$dst;$password;$ignore_dot)
```
