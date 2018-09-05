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

* ignore dot files or hidden files ``ZIP_Ignore_hidden``

* archive only the contents of the specified folder ``ZIP_Without_enclosing_folder``

* **Mac**: keep UNIX attributes and symbolic links ``ZIP_With_attributes``

* ANSI code page (for old Windows)

### Platform

| carbon | cocoa | win32 | win64 |
|:------:|:-----:|:---------:|:---------:|
|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|

### Version

<img src="https://cloud.githubusercontent.com/assets/1725068/18940649/21945000-8645-11e6-86ed-4a0f800e5a73.png" width="32" height="32" /> <img src="https://cloud.githubusercontent.com/assets/1725068/18940648/2192ddba-8645-11e6-864d-6d5692d55717.png" width="32" height="32" /> <img src="https://user-images.githubusercontent.com/1725068/41266195-ddf767b2-6e30-11e8-9d6b-2adf6a9f57a5.png" width="32" height="32" />

![preemption xx](https://user-images.githubusercontent.com/1725068/41327179-4e839948-6efd-11e8-982b-a670d511e04f.png)

### Releases

[2.1](https://github.com/miyako/4d-plugin-zip/releases/tag/2.1) added missing callback support for unzip

[2.0](https://github.com/miyako/4d-plugin-zip/releases/tag/2.0)

```
success:=Zip (src;dst;pass;level;options;callback;codepage)
```

Parameter|Type|Description
------------|------|----
src|TEXT|
dst|TEXT|
pass|TEXT|
level|LONGINT|
options|LONGINT|
callback|TEXT|
codepage|LONGINT|

```
result:=Unzip (src;dst;pass;options;callback;codepage)
```

Parameter|Type|Description
------------|------|----
src|TEXT|
dst|TEXT|
pass|TEXT|
options|LONGINT|
callback|TEXT|
codepage|LONGINT|

**Keep UNIX file attributes**

You can archive apps, or any folder that contains symbolic links and files with RWX permissions, by passing ```ZIP_With_attributes (2)``` in options.

**Exclude enclosing folder**

Standard compression programs keep the top level folder in the relative path.

You can compress just the contents of a folder by passing ```ZIP_Without_enclosing_folder (4)``` in options.  

About Unicode
---
The plugin will store the file paths in UTF-8 on both platforms.

You can safely unarchive such zip files using the plugin.

However, the Windows kernel on Windows 7 and Windows Server 2008 R2 assumes that the paths are stored in the current locale, so UTF-8 paths will be converted wrongly. There is a Microsoft Patch to correct this.

[http://support.microsoft.com/kb/2704299](http://support.microsoft.com/kb/2704299)
