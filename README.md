![version](https://img.shields.io/badge/version-16%2B-8331AE)
![platform](https://img.shields.io/static/v1?label=platform&message=mac-intel%20|%20mac-arm%20|%20win-64&color=blue)
[![license](https://img.shields.io/github/license/miyako/4d-plugin-zip)](LICENSE)
![downloads](https://img.shields.io/github/downloads/miyako/4d-plugin-zip/total)

Compresses files/folders into a `.zip` archive and extracts `.zip` archives back to disk. Under the hood it drives the [nmoinvaz/minizip (minizip-ng)](https://github.com/nmoinvaz/minizip) engine (replacing the plugin's earlier `madler/zlib/minizip` implementation), plus native OS APIs for file attributes, symlinks, and legacy code‑page handling. Both commands return a `Longint` (`1` success / `0` failure) and can drive a progress callback method of your own.

| Command | Returns | Purpose |
|---|---|---|
| [Zip](#zip) | Longint | Compress one or more files/folders into an archive |
| [Unzip](#unzip) | Longint | Extract the contents of an archive to a destination folder |

**Platforms:** macOS (Intel & Apple Silicon) and Windows (64-bit), 4D v16 or later.

---

## Requirements & platform notes

- **Trailing parameters are optional.** Both commands can be called with fewer than their full parameter list — the plugin's own sample code does this routinely (e.g. `Zip ($src;$ZipFile;"";0)` with no `options`/`callback`/`codepage`, or `Unzip ($src;$dst;$pass)` with no `options`/`callback`/`codepage` at all). Omitted trailing parameters default to `0` for `Longint`/flags and `""` (empty) for `Text`. See each command's parameter table for what each specific default means in practice.
- **Neither command is transactional.** If a job is interrupted — by your callback method returning `True`, by the 4D process being stopped from the Runtime Explorer, or by an entry that fails partway — whatever was already written to disk stays there. `Zip` leaves a partial archive on disk rather than deleting it; `Unzip` leaves whatever files it had already extracted. Check the `Longint` result and don't assume all-or-nothing behavior.
- **Failure is reported only as `0`, never as a 4D error/exception.** There's no `OnError`-style hook here — always check the returned `Longint` if the operation's success matters to your code.
- **The progress callback fires roughly once per second, not once per file.** Both commands only check the elapsed time (and invoke your callback, or yield if none is set) about once a second; a fast job on many small files may call your method only a handful of times, or not at all. If you need per-file granularity for a very large job, don't rely on this callback as a per-item counter — it reports whichever item happened to be current when that second elapsed.
- **`ZIP_With_attributes` (value `2`) is obsolete and has no effect on either platform**, regardless of whether you pass it: **on macOS**, POSIX permissions and symbolic links are *always* preserved (`Zip`) / restored (`Unzip`); **on Windows**, they are *never* preserved/restored. The bit is still accepted for backward compatibility with existing calls but is not read internally — don't rely on toggling it.
- **`ZIP_BZ2` (16) and `ZIP_7Z` (32) both change the entries' internal compression codec, not the container format.** The output file is always a standard `.zip` container (readable as one) whose entries happen to be compressed with BZIP2 or LZMA instead of Deflate — not a genuine standalone `.7z` or `.bz2` file, despite the `.7z`/`.bz2` extension convention below. Don't combine the two flags: they aren't mutually exclusive at the API level, and if both bits are set, `ZIP_7Z`/LZMA silently wins.
- **A password alone gives you legacy ("ZipCrypto") encryption, which is weak by modern standards.** Add `ZIP_With_encryption` (8) if you want real AES‑256 encryption. AES-encrypted archives need an AES-capable unarchiver to open (7‑Zip or similar) — plain double-click extraction on some platforms may not support it.
- **Unicode is UTF‑8 internally.** The plugin always stores/reads entry filenames as UTF‑8. The `codepage` parameter exists only for interoperating with archives created by other, non‑UTF‑8‑aware tools — leave it `0` unless you know you need it (see each command's parameter table). Note: on Windows 7 / Windows Server 2008 R2 specifically, the OS itself assumes non-UTF‑8 paths are in the current locale, which can mis-render UTF‑8 filenames from this plugin unless [Microsoft's patch](http://support.microsoft.com/kb/2704299) is installed — this is a Windows OS‑level caveat, not something the plugin can work around.
- **Destination folders for `Unzip` don't need to exist beforehand** — the plugin creates the destination and any intermediate folders as it extracts each entry.

---

## Zip

### Syntax
```4d
success:=Zip (src;dst;pass;level;options;callback;codepage)
```

| Parameter | Type | Description |
|---|---|---|
| `src` | Text | Absolute path of a single file or folder to compress, **or** a JSON-stringified array of paths (e.g. via `JSON Stringify array`) to archive several items in one call. |
| `dst` | Text | Absolute path of the archive file to create. The file is always written as a `.zip` container — see the compression-codec caveat above regarding `.7z`/`.bz2`. |
| `pass` | Text | Password to protect the archive with. Empty (or omitted) = no password. See the encryption caveat above for `pass` alone vs. combined with `ZIP_With_encryption`. |
| `level` | Longint | Compression level. `0` (or omitted) = default compression. `-1` = store only (no compression). `1`–`9` = explicit Deflate level; values above `9` are clamped to `9` (best). Ignored for entries actually compressed as BZIP2/LZMA (those codecs manage their own level internally). |
| `options` | Longint | Bitmask — see the options table below. `0` (or omitted) = no flags set. |
| `callback` | Text | Name of a project method in the host database to call periodically as progress is made (see [Requirements](#requirements--platform-notes) for timing/signature). Empty (or omitted) = no callback; the plugin still yields periodically so the host app stays responsive. |
| `codepage` | Longint | `0` (or omitted) = no charset conversion; filenames are written as UTF‑8 as-is. `-1` = auto-detect the source filenames' charset before conversion. A positive value = a specific Windows code page number to convert filenames *from* before storing them. |
| Result | Longint | `1` if the operation completed; `0` on failure or if aborted (by the callback or by the process being stopped). |

**`options` bitmask (for `Zip`):**

| Value | Constant | Effect |
|---|---|---|
| 1 | `ZIP_Ignore_hidden` | Skip dot-files and hidden items when building the file list. |
| 2 | `ZIP_With_attributes` | **Obsolete/ignored** — see the platform note above; has no effect on either OS. |
| 4 | `ZIP_Without_enclosing_folder` | Archive only the *contents* of a source folder, without adding the folder itself as a top-level entry. |
| 8 | `ZIP_With_encryption` | Use AES-256 encryption instead of legacy ZipCrypto, when `pass` is non-empty. |
| 16 | `ZIP_BZ2` | Compress entries with BZIP2 instead of Deflate. |
| 32 | `ZIP_7Z` | Compress entries with LZMA instead of Deflate. Wins if combined with `ZIP_BZ2`. |

Combine flags by adding the values, e.g. `ZIP_Ignore_hidden+ZIP_With_encryption` = `9`.

### Description

`src` accepts either a single path or, for multiple items in one call, a JSON array of paths passed as a stringified collection — the plugin parses it, and any entry that isn't valid JSON is treated as one plain path.

**On macOS**, building the file list walks the source folder(s) via Cocoa's directory enumeration APIs and always captures POSIX permissions, symbolic links, and file type (regular/dir/symlink/socket/device) for each entry, storing them in the archive's external file attributes; permissions are also detected file-by-file when populating each ZIP entry. **On Windows**, this attribute/symlink capture doesn't happen — entries carry whatever `mz_os_get_file_attribs` reports for a plain file/folder.

If your callback method resolves via `PA_GetMethodID` (i.e., it's a genuine project method — the normal, supported case), it's called with:

| Parameter | Type | Description |
|---|---|---|
| `$1` | Text | Relative path (inside the archive) of the item just processed. |
| `$2` | Text | Absolute path of the source file on disk. |
| `$3` | Real | 1-based index of the item just processed. |
| `$4` | Real | Total number of items to be archived. |
| Function result | Boolean | Optional. Return `True` to abort the remainder of the job. |

### Example

From the plugin's own test method (`Method11.4dm`) — zipping a single item, no password, default level, no options:
```4d
C_TEXT:C284($src;$ZipFile)
C_LONGINT:C283($Ok)
ARRAY TEXT:C222($MonTab;2)
$MonTab{1}:=System folder:C487(Desktop:K41:16)+"木暮理太郎 白馬岳.pdf"
$MonTab{2}:=""

$ZipFile:=System folder:C487(Desktop:K41:16)+"木暮理太郎 白馬岳.zip"


$src:=JSON Stringify array:C1228($MonTab)

$Ok:=Zip ($src;$ZipFile;"";0)
```

From `test_zip.4dm` — zipping a whole app bundle with a password and an explicit level:
```4d
$pass:="password"

$src:=System folder:C487(Applications or program files:K41:17)+"4D"+Folder separator:K24:12+"4D v17 R6"+Folder separator:K24:12+"4D.app"
$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".zip"
$start:=Milliseconds:C459
$success:=Zip ($src;$dst;$pass;ZIP_Compression_level_2)
$duration:=Milliseconds:C459-$start
```

From `test_password.4dm` — with an options flag (note `ZIP_With_attributes` is obsolete/ignored per the platform note above; quoted here as the plugin's own sample):
```4d
$pass:="password"

$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".zip"
$success:=Zip ($src;$dst;$pass;0;ZIP_With_attributes)

$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".7z"
$success:=Zip ($src;$dst;$pass;0;ZIP_7Z)
```

A generic pattern combining a password, AES encryption, and a callback:
```4d
C_TEXT($src;$dst;$pass)
C_LONGINT($level;$options;$codepage;$success)

$src:=Get 4D folder(Current resources folder)
$dst:=System folder(Desktop)+"Archive.zip"
$pass:="a strong password"
$level:=0  // default compression
$options:=ZIP_With_encryption  // AES-256, not just ZipCrypto
$success:=Zip ($src;$dst;$pass;$level;$options;"Zip_Progress")
```
```4d
// Method: Zip_Progress ($1..$4 as documented above)
C_TEXT($1;$2)
C_LONGINT($3;$4)
C_BOOLEAN($0)
If (Some flag to abort)
	$0:=True
Else
	$0:=False
End if
```

---

## Unzip

### Syntax
```4d
result:=Unzip (src;dst;pass;options;callback;codepage)
```

| Parameter | Type | Description |
|---|---|---|
| `src` | Text | Absolute path of the `.zip` archive to extract. |
| `dst` | Text | Absolute path of the destination folder. Created automatically (with any needed intermediate folders) if it doesn't already exist. |
| `pass` | Text | Password, if the archive is protected. Empty (or omitted) = no password. |
| `options` | Longint | Bitmask — only `ZIP_Ignore_hidden` (`1`) has any effect for `Unzip`; see below. `0` (or omitted) = no flags. |
| `callback` | Text | Name of a project method to call periodically during extraction (see [Requirements](#requirements--platform-notes) for timing, and below for its signature). Empty (or omitted) = no callback. |
| `codepage` | Longint | `0` (or omitted) = no charset conversion (entry names are read as stored, UTF‑8). `-1` = auto-detect the charset the archive's filenames were stored in. A positive value = a specific Windows code page to convert filenames *to* when they were written in a legacy (non‑UTF‑8) charset. |
| Result | Longint | `1` if every entry in the archive was reached and processed; `0` if extraction failed, was aborted, or the number of entries actually iterated didn't match the archive's stated entry count. |

**`options` bitmask (for `Unzip`):**

| Value | Constant | Effect |
|---|---|---|
| 1 | `ZIP_Ignore_hidden` | Skip dot-files/hidden entries when extracting. |
| 2 | `ZIP_With_attributes` | **Obsolete/ignored** — see the platform note above. |

### Description

**On macOS**, entries whose external attributes mark them as symbolic links are recreated as real symlinks (not as regular files containing the link target), and each entry's modification/creation/access dates and POSIX permissions are restored on the extracted file. **On Windows**, none of that attribute/symlink handling happens — files are written as plain files with whatever default attributes Windows assigns, though file modification/access/creation *dates* are still set from the archive's stored values on both platforms.

If your callback method resolves via `PA_GetMethodID` (the normal, supported case), it's called with:

| Parameter | Type | Description |
|---|---|---|
| `$1` | Text | Relative path of the entry just processed (its path inside the archive). |
| `$2` | Text | Absolute destination path the entry was (or will be) written to. |
| `$3` | Real | 1-based index of the entry just processed. |
| `$4` | Real | Total number of entries in the archive. |
| `$5` | Real | Compressed size of this entry, in bytes. |
| `$6` | Real | Uncompressed size of this entry, in bytes. |
| Function result | Boolean | Optional. Return `True` to abort the remainder of the extraction. |

### Example

From `test_zip.4dm` — round-tripping the archive created in the `Zip` example above, using the same password:
```4d
$src:=System folder:C487(Desktop:K41:16)+Current method name:C684+".zip"
$dst:=System folder:C487(Desktop:K41:16)
$start:=Milliseconds:C459
$success:=Unzip ($src;$dst;$pass)
$duration:=Milliseconds:C459-$start
```

A generic pattern with all parameters and a progress callback that reports percent complete:
```4d
C_TEXT($src;$dst;$pass)
C_LONGINT($options;$codepage;$success)

$src:=Select folder file dialog goes here  // e.g. via SELECT LOG FILE, a dialog, etc.
$dst:=System folder(Desktop)+"Extracted"+Folder separator
$pass:=""
$options:=ZIP_Ignore_hidden
$success:=Unzip ($src;$dst;$pass;$options;"Unzip_Progress")
```
```4d
// Method: Unzip_Progress
C_TEXT($1;$2)
C_LONGINT($3;$4;$5;$6)
C_BOOLEAN($0)
$percent:=Round(($3/$4)*100;0)
$0:=False  // return True here to abort
```

---

## Error handling & troubleshooting

- **A `0` result doesn't tell you which entry failed.** Neither command surfaces a per-entry error code or message back to 4D — you only get the overall `Longint`. If you need to know why a specific archive failed, that has to happen inside your own callback (e.g. logging `$1`/`$2` each time it's called) rather than from the return value alone.
- **A partial archive or partial extraction can be left on disk after a `0` result.** Neither operation cleans up after itself if interrupted — see the transactional-behavior note above.
- **`ZIP_With_attributes` won't do what its name suggests, on either platform** — see the dedicated caveat above. If you need conditional attribute preservation, that decision currently isn't exposed by this plugin; it's always-on for macOS and always-off for Windows.
- **A weak password isn't a bug — it's the default.** If you pass `pass` without also passing `ZIP_With_encryption`, you get legacy ZipCrypto, which is not considered cryptographically strong. Add the flag explicitly if password strength matters for your use case.
- **Don't combine `ZIP_BZ2` and `ZIP_7Z`.** Both flags are read independently and the last one checked (`ZIP_7Z`) silently overrides the other if both bits are set — there's no error, just LZMA winning.
- **Callback not firing at all on a fast job is expected, not a bug** — it's tied to elapsed wall-clock time (about once a second), not to file count.
- **Garbled non-ASCII filenames after extracting an older/foreign-made archive** are almost always a `codepage` issue — try `-1` (auto-detect) or the specific source code page, rather than assuming the archive is corrupt.
- **Windows 7 / Server 2008 R2 specifically** can mis-render this plugin's UTF‑8 paths in certain OS-level contexts unless [Microsoft's UTF‑8 path patch](http://support.microsoft.com/kb/2704299) is applied — this is outside the plugin's control.

---

## Quick reference

```4d
// Compress a folder, ignoring hidden files, with AES password protection and a progress method
$success:=Zip ($srcFolder;$zipPath;$password;0;ZIP_Ignore_hidden+ZIP_With_encryption;"MyZipProgress")

// Compress the contents only (no enclosing folder), LZMA-compressed, no password
$success:=Zip ($srcFolder;$zipPath;"";0;ZIP_Without_enclosing_folder+ZIP_7Z)

// Extract everything, no password, no callback
$success:=Unzip ($zipPath;$destFolder;"")

// Extract a password-protected archive, skipping hidden entries, with a progress method
$success:=Unzip ($zipPath;$destFolder;$password;ZIP_Ignore_hidden;"MyUnzipProgress")
```
