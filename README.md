# PowerShell script for FuSoYa's ZSNES 8MB custom build
This repository contains 2 scripts and the required libraries to build FuSoYa's ZSNES 8MB custom build.
## Requirements
- [Microsoft Visual Studio 2022](https://visualstudio.microsoft.com/it/downloads/)
- [CMake 3.15 or higher](https://cmake.org/download/) 
- [make](https://community.chocolatey.org/packages/make)
- [git](https://gitforwindows.org/)
- [nasm](https://www.nasm.us/)
- [PowerShell 7](https://github.com/PowerShell/PowerShell)
## How to build
Building should be as simple as running `zsnes_build.ps1` in PowerShell 7 or newer.
The resulting executable file will be placed in the `build` folder.