# 7zTheme
*ResourceLib wrapper for applying 7-zip themes.*

Uses [Vestris.ResourceLib 2.2.0-beta0004](https://www.nuget.org/packages/Vestris.ResourceLib/2.2.0-beta0004). All commands require full paths.


## Edit-7zFiletypeIcon
*Change the icons for supported 7-zip filetypes.*

Icons should follow the 7zTM naming convention of `extension.ico`.
Multiple theme directories can be used, in which case the last available filetype icons will be applied.

```PowerShell
# Edit-7zFiletypeIcon [-SevenZipPath] <DirectoryInfo> [-FilePath] <DirectoryInfo[]>
Edit-7zFiletypeIcon -SevenZipPath 'C:\Program Files\7-Zip\' -FilePath 'C:\temp\7zTM\filetype\'
```

## Edit-7zToolbarIcon
*Change the toolbar images in 7-zip.*

The BMP images will need to be in a subfolder named based on their resolution. Currently this will be either `24x24` or `48x36`.
The BMP images themselves should be named after the button they're for, these are currently:
  Add, Extract, Test, Copy, Move, Delete, Info
Multiple theme directories can be used, in which case the last available BMP images will be applied.
```PowerShell
# Edit-7zToolbarIcon [-SevenZipPath] <DirectoryInfo> [-FilePath] <DirectoryInfo[]>
Edit-7zToolbarIcon -SevenZipPath 'C:\Program Files\7-Zip\' -FilePath 'C:\temp\7zTM\toolbar\'
```

## Edit-7zIcon
*Change the icon(s) for 7-zip.*

At least one switch should be selected for this to do anything, but multiple can be used at once if it's for the same icon.
```PowerShell
# Edit-7zIcon [-SevenZipPath] <DirectoryInfo> [-FilePath] <DirectoryInfo> [-FileManagerIcon] [-GUIIcon] [-PluginIcon] [-SFXIcon]
Edit-7zToolbarIcon -SevenZipPath 'C:\Program Files\7-Zip\' -FilePath 'C:\temp\7zTM\SFX Icon\Some icon file.ico' -SFXIcon
```

---

The structure of `C:\temp\7zTM` in the examples might be as follows.
```
C:\TEMP\7ZTM
├───filetype
│       001.ico
│       7z.ico
│       arj.ico
│       bz2.ico
│       cab.ico
│       cpio.ico
│       deb.ico
│       dmg.ico
│       fat.ico
│       gz.ico
│       hfs.ico
│       iso.ico
│       lha.ico
│       lzh.ico
│       ntfs.ico
│       rar.ico
│       rpm.ico
│       sqfs.ico
│       tar.ico
│       vhd.ico
│       wim.ico
│       xar.ico
│       xz.ico
│       z.ico
│       zip.ico
│
├───SFX Icon
│       Some icon file.ico
│
└───toolbar
    ├───24x24
    │       Add.bmp
    │       Copy.bmp
    │       Delete.bmp
    │       Extract.bmp
    │       Info.bmp
    │       Move.bmp
    │       Test.bmp
    │
    └───48x36
            Add.bmp
            Copy.bmp
            Delete.bmp
            Extract.bmp
            Info.bmp
            Move.bmp
            Test.bmp
```
