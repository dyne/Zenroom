#!/bin/sh

# this script is needed to inscribe metadata in the .exe files
# targeting windows. it creates a .rs to be used when linking

cat << EOF > zenroom.rc
1 VERSIONINFO
FILEVERSION     1,0,0,0
PRODUCTVERSION  1,0,0,0
BEGIN
  BLOCK "StringFileInfo"
  BEGIN
    BLOCK "040904E4"
    BEGIN
      VALUE "CompanyName", "Dyne.org Foundation"
      VALUE "FileDescription", "Zenroom, cryptolang VM"
      VALUE "FileVersion", "`date +'%Y%m%d'`"
      VALUE "InternalName", "zenroom"
      VALUE "LegalCopyright", "Written and designed by Denis Roio <jaromil@dyne.org>"
      VALUE "OriginalFilename", "zenroom.exe"
      VALUE "ProductName", "Zenroom"
      VALUE "ProductVersion", "`cat ../VERSION`"
    END
  END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x409, 1252
  END
END
EOF

if [ "$(which windres)" = "" ]; then
    x86_64-w64-mingw32-windres zenroom.rc -O coff -o zenroom.res
else
    windres zenroom.rc -O coff -o zenroom.res
fi
