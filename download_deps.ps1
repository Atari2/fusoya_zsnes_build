# in the hopes that these links don't change and/or die.
# the zipped dependencies that this script download should already be present in the git repo
# but this script is here in case they are not.

function Get-File-If-Not-Exist {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$OutFile,
        [Parameter(Mandatory=$false)][string]$UserAgent = ([Microsoft.PowerShell.Commands.PSUserAgent]::FireFox)
    )
    if (!(Test-Path -Path $OutFile)) {
        Write-Output "Downloading $Uri to $OutFile"
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UserAgent $UserAgent
    } else {
        Write-Warning "$OutFile already exists, skipping download"
    }
}

$oldProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'
Get-File-If-Not-Exist "https://www.zlib.net/fossils/zlib-1.2.12.tar.gz" -OutFile "zlib.tar.gz"
Get-File-If-Not-Exist -UserAgent "Wget" -Uri "https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/lpng1637.zip" -OutFile "libpng.zip"
Get-File-If-Not-Exist -Uri "https://github.com/wmcbrine/PDCurses/archive/refs/tags/3.9.zip" -OutFile "pdcurses.zip"
Get-File-If-Not-Exist -Uri "https://fusoya.eludevisibility.org/emulator/download/zsnesw151-FuSoYa-8MB_R2src.zip" -OutFile "zsnes.zip"
$ProgressPreference = $oldProgressPreference