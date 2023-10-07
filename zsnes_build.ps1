try {
    $vsPath = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationpath
    Import-Module (Get-ChildItem $vsPath -Recurse -File -Filter Microsoft.VisualStudio.DevShell.dll).FullName
    Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments '-arch=x86'
} catch {
    Write-Output "Failed to enter VS Dev Shell: $_"
    Exit 1
}

try {
    git --version | Out-Null
} catch [System.Management.Automation.CommandNotFoundException] {
    Write-Output "This script requires git to be installed."
    Exit 1
}

try {
    nasm --version | Out-Null
} catch [System.Management.Automation.CommandNotFoundException] {
    Write-Output "This script requires nasm to be installed and on the path."
    Exit 1
}

& $PSScriptRoot\download_deps.ps1

$patchstring='
diff --git a/build/zsnes_1_51/src/makefile.ms b/build/zsnes_1_51/src/makefile.ms
index c1d8c2d..e335ad8 100644
--- a/build/zsnes_1_51/src/makefile.ms
+++ b/build/zsnes_1_51/src/makefile.ms
@@ -87,8 +87,8 @@ ifeq (${ENV},win32)
 endif
 
 ifeq (${ENV},msvc)
-  CFLAGSORIG=/nologo /Ox /G6 /c /EHsc
-  MSVCLIBS=zlib.lib libpng.lib wsock32.lib user32.lib gdi32.lib shell32.lib winmm.lib dinput8.lib dxguid.lib
+  CFLAGSORIG=/nologo /Ox /c /EHsc /MT /I"${LIB_INCLUDE_DIR}"
+  MSVCLIBS="${LIB_LIBRARY_DIR}\zlib.lib" "${LIB_LIBRARY_DIR}\libpng16.lib" wsock32.lib user32.lib gdi32.lib shell32.lib winmm.lib dinput8.lib dxguid.lib
   DRESOBJ=${WINDIR}/zsnes.res
   OS=__WIN32__
 endif
@@ -212,7 +212,7 @@ ifneq (${DEBUGGER},no)
     LIBS+= -lpdcur
   else
     LIBS+= -lpdcurses -ladvapi32
-    MSVCLIBS+= pdcurses.lib advapi32.lib
+    MSVCLIBS+= "${LIB_LIBRARY_DIR}\pdcurses.lib" advapi32.lib
   endif
 endif
 
@@ -298,7 +298,7 @@ else
 	 @echo /Fezsnesw.exe *.obj ${CPUDIR}\*.obj ${VIDEODIR}\*.obj ${CHIPDIR}\*.obj ${EFFECTSDIR}\*.obj ${DOSDIR}\*.obj ${WINDIR}\*.obj ${GUIDIR}\*.obj > link.vc
 	 @echo ${ZIPDIR}\*.obj ${JMADIR}\*.obj ${NETDIR}\*.obj ${MMLIBDIR}\*.obj >> link.vc
 	 @echo ${MSVCLIBS} >> link.vc
-	 cl /nologo @link.vc ${WINDIR}/zsnes.res /link
+	 cl /MT /nologo @link.vc ${WINDIR}/zsnes.res /link
 endif
 
 cfg${OE}: cfg.psr ${PSR}
@@ -493,7 +493,7 @@ ${OBJFIX}: objfix.c
 endif
 ${PSR}: parsegen.cpp
 ifeq (${ENV},msvc)
-	cl /nologo /EHsc /Fe$@ parsegen.cpp zlib.lib
+	cl /nologo /EHsc /MD /I"${LIB_INCLUDE_DIR}" /Fe$@ parsegen.cpp "${LIB_LIBRARY_DIR}\zlib.lib"
 	${DELETECOMMAND} parsegen.obj
 else
 ifeq (${ENV},dos)
'

$currentdir=($pwd)
$outdir = "$currentdir\build"
$depspath = "$outdir\libs"
$libpath = "$depspath\lib"
$includepath = "$depspath\include"
New-Item -Path $outdir -ItemType Directory -Force 
New-Item -Path $depspath -ItemType Directory -Force

# if libs/lib is already present and the zsnesw.exe is present
# then we assume that the build is already done and just rebuild zsnes
if ((Test-Path -Path $libpath) -and (Test-Path -Path $includepath) -and (Test-Path -Path "$outdir/zsnesw.exe")) {
    Write-Warning "zsnesw.exe already exists and the lib folder already exists, starting partial rebuild"
    Write-Warning "If the intention was to initiate a full rebuild, please delete the zsnesw.exe executable and rerun the script"

    # just rebuild zsnes
    Set-Location $outdir\zsnes_1_51\src
    $env:PATH = "$env:PATH;$depspath/bin"
    $env:NASMENV = "-w-orphan-labels -w-pp-macro-params-legacy"
    make -f makefile.ms PLATFORM=msvc LIB_INCLUDE_DIR=$includepath LIB_LIBRARY_DIR=$libpath
    Copy-Item .\zsnesw.exe "$outdir/zsnesw.exe"
    Set-Location $currentdir
    Write-Output "Done"
    Exit 0
} else {
    Write-Output "Starting full build..."
}

# zlib
Set-Location $currentdir
tar -xvzf .\zlib.tar.gz
Move-Item .\zlib-1.2.12 "$outdir/zlib-1.2.12"
Set-Location $outdir\zlib-1.2.12
mkdir build
Set-Location .\build
cmake -DCMAKE_INSTALL_PREFIX="$depspath"  -A Win32 ..
cmake --build . --config Release
cmake --install .
Set-Location $outdir

# libpng
Set-Location $currentdir
Expand-Archive -Path libpng.zip -DestinationPath $outdir
Set-Location $outdir\lpng1637
mkdir build
Set-Location .\build
cmake -DCMAKE_INSTALL_PREFIX="$depspath" -DPNG_BUILD_ZLIB=ON -DZLIB_LIBRARY="$libpath/zlib.lib" -DZLIB_INCLUDE_DIR="$includepath" -A Win32 ..
cmake --build . --config Release
cmake --install .
Set-Location $outdir

# pdcurses
Set-Location $currentdir
Expand-Archive -Path pdcurses.zip -DestinationPath $outdir
Set-Location $outdir\PDCurses-3.9\wincon
nmake /f Makefile.vc
Copy-Item .\pdcurses.lib "$depspath/lib/pdcurses.lib"
Set-Location $outdir
Get-ChildItem -Path .\PDCurses-3.9\*.h -Recurse | Move-Item -Destination .\libs\include -Force

# zsnes
Set-Location $currentdir
Expand-Archive -Path zsnes.zip -DestinationPath $outdir -Force
Set-Location $outdir
$patchstring | Out-File ".\zsnes_makefile.patch" 
git apply zsnes_makefile.patch
Set-Location $outdir\zsnes_1_51\src

$env:PATH = "$env:PATH;$depspath/bin"
$env:NASMENV = "-w-orphan-labels -w-pp-macro-params-legacy"
make -f makefile.ms PLATFORM=msvc LIB_INCLUDE_DIR=$includepath LIB_LIBRARY_DIR=$libpath
Copy-Item zsnesw.exe "$outdir/zsnesw.exe"
Set-Location $currentdir
Copy-Item $outdir\libs\bin\zlib.dll "$outdir/zlib.dll"
Copy-Item $outdir\libs\bin\libpng16.dll "$outdir/libpng16.dll"

Write-Output "Done"