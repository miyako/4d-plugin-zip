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
 
**CAUTION**

Do not use this plugin to archive apps on Mac. This zip program is not fully capable of handing symbolic links.

Rather try [ditto](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/ditto.1.html) or [zip](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/zip.1.html) with the ```-y``` option.

```sh
ditto -c -k --sequesterRsrc --keepParent Product.app Product.app.zip
```

Compatibility
---
* The v14 package is built with the new v14 architecture. Supports v14 or above, OS X 10.8+, 32/64 bits, Windows 32/64 bits.

* The v11 package is built with the v11 architecture. Supports v11 or above, including v14, OS X 10.6+ 32 bits, Windows 32/64 bits.

About Unicode
---
The plugin will store the file paths in UTF-8 on both platforms.

You can safely unarchive such zip files using the plugin.

However, the Windows kernel on Windows 7 and Windows Server 2008 R2 assumes that the paths are stored in the current locale, so UTF-8 paths will be converted wrongly. There is a Microsoft Patch to correct this.

[http://support.microsoft.com/kb/2704299](http://support.microsoft.com/kb/2704299)

New
---

You can instruct the plugin to ignore files and folders whose name begins with a dot.

You can specify the compression level (1 to 9).

You can compress an empty folder. (why not?)

When you compress a folder, the top-level folder name is included in the path.

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
