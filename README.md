# 4d-plugin-zip
4D plugin to zip and unzip.

the previous version is under the [classic-minizip](https://github.com/miyako/4d-plugin-zip/tree/classic-minizip) branch

this version replaces the original [madler/zlib/minizip](https://github.com/madler/zlib/tree/master/contrib/minizip) with the [nmoinvaz/minizip](https://github.com/nmoinvaz/minizip) implementation

### Features

* multiple input for ``Zip`` (``C_TEXT`` or stringified ``C_COLLECTION``)

* password protected zip (on files, not folders, for Mac Archive Utility)

* LZMA ``ZIP_7Z`` specify ".7z" as the output path

* BZ2 ``ZIP_BZ2`` specify ".bz2" as the output path

* AES encrypted zip ``ZIP_With_encryption`` optionally with password (requires 7z or other capable unarchiver)

* ignore dot files (also hidden files on Mac) ``ZIP_Ignore_hidden``

* archive only the contents of the specified folder ``ZIP_Without_enclosing_folder``

* **Mac**: keep UNIX attributes and symbolic links ``ZIP_With_attributes``

* ANSI code page (for old Windows)

### Platform

| carbon | cocoa | win32 | win64 |
|:------:|:-----:|:---------:|:---------:|
|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|

### Version

<img src="https://cloud.githubusercontent.com/assets/1725068/18940649/21945000-8645-11e6-86ed-4a0f800e5a73.png" width="32" height="32" /> <img src="https://cloud.githubusercontent.com/assets/1725068/18940648/2192ddba-8645-11e6-864d-6d5692d55717.png" width="32" height="32" />

### Releases

[1.5](https://github.com/miyako/4d-plugin-zip/releases/tag/1.5)

## Notes

An optional ``codepage`` paramter is added. Use it to specify an encoding other than the default UTF-8. The Unzip command can auto-detect ANSI file names in proprietary Windows archives.

The component can now accept a callback method that is a **shared component method**.

Pass ``ZIP_With_encryption (8)`` to apply AES encryption. 

Note that basic archive utilities may not support password protection, or AES encryption. Use 7-Zip.

## Examples

```
$src:=Application file
$dst:=System folder(Desktop)+"app.zip"

ZIP_CALLBACK_INIT 

$success:=Zip ($src;$dst;"";\
ZIP_Compression_level_1;ZIP_With_attributes;\
"ZIP_CALLBACK")

ZIP_CALLBACK_DEINIT 
```

* ``ZIP_CALLBACK_INIT``

```
PROGRESS:=Progress New 
Progress SET BUTTON ENABLED (PROGRESS;True)
Progress SET ON STOP METHOD (PROGRESS;"ZIP_CALLBACK_STOP")
```

* ``ZIP_CALLBACK_DEINIT``

```
If (Not(Progress Stopped (PROGRESS)))
Progress QUIT (PROGRESS)
End if 
```

* ``ZIP_CALLBACK``

```
C_TEXT($1;$2)
C_LONGINT($3;$4)
C_BOOLEAN($0)

If (Progress Stopped (PROGRESS))

$0:=True

Else 

Progress SET PROGRESS (PROGRESS;$3/$4;$2)

End if 
```

## Important

This plugin project is a forked subset of what was published as [OAuth](https://github.com/miyako/4d-plugin-oauth).

Existing commands have the same name and functionality, but their tokens (internal IDs) have changed.

To migrate existing methods, do the following:

1. Comment the code that calls ```Zip``` or ```Unzip``` commands.
2. Close 4DB.
3. Replace the plugin.
4. Uncomment the code.
 
**CAUTION**

~~Do not use this plugin to archive apps on Mac. This zip program is not fully capable of handing symbolic links.~~

~~Rather try [ditto](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/ditto.1.html) or [zip](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/zip.1.html) with the ```-y``` option.~~

```sh
ditto -c -k --sequesterRsrc --keepParent Product.app Product.app.zip
```

**Keep UNIX file attributes**

You can archive apps, or any folder that contains symbolic links and files with RWX permissions, by passing ```ZIP_With_attributes (2)``` in options.

```
$src:=System folder(Desktop)+"src"
$dst:=System folder(Desktop)+"src.zip"
$password:=""
$compression_level:=1

  //simply ignore dot-files and folders
$ignore_hidden:=1

  //new in v1.1
  //support unix permissions (755, etc)
  //support symlinks (relative or absolute)
  //when used with ignore_hidden, also ignore items with "hidden" flag
$with_atttributes:=2

$success:=Zip ($src;$dst;$password;$compression_level;$with_atttributes)
```

**Exclude enclosing folder**

Standard compression programs keep the top level folder in the relative path.

You can compress just the contents of a folder by passing ```ZIP_Without_enclosing_folder (4)``` in options.  

About Unicode
---
The plugin will store the file paths in UTF-8 on both platforms.

You can safely unarchive such zip files using the plugin.

However, the Windows kernel on Windows 7 and Windows Server 2008 R2 assumes that the paths are stored in the current locale, so UTF-8 paths will be converted wrongly. There is a Microsoft Patch to correct this.

[http://support.microsoft.com/kb/2704299](http://support.microsoft.com/kb/2704299)
