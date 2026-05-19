@echo off
pushd %~dp0..\..\

lune run Test\ConfigToFile.luau
darklua process src\Main.luau Temp\main.bundle.luau
lune build Temp\main.bundle.luau -o Temp\Phoenix.exe