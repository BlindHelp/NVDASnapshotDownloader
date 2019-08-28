@echo off
title NVDA snapshot downloader
:: Author: Alberto buffolino
:: License: GPL V3
:: French translation: R�my Ruiz
setlocal enabledelayedexpansion
:: backup current codepage, and change it to 1252, more useful for translators
:: saving in ANSI is recomended
for /f "tokens=2 delims=:." %%a in ('chcp') do (set cp=%%a)
chcp 1252>nul 2>&1
wget --version>nul 2>nul
if %errorlevel% == 0 (
 set using=wget
 goto start
)
curl --version>nul 2>nul
if %errorlevel% == 0 (
 set using=curl
 goto start
)
powershell -command "echo Disponible!">nul 2>nul
if %errorlevel% == 0 (
 set using=powershell
 goto start
) else (
 echo ERREUR: le t�l�chargement n'est pas possible,
 echo installe curl ou wget, p. ex. depuis
 echo https://eternallybored.org/misc/wget/
 pause
 goto finish
)

:start
echo Utilisant %using%
echo Obtenant des informations sur la version...
set pageURL=https://www.nvaccess.org/files/nvda/snapshots/
set pageFile=%tmp%\NVDASnapshotsPage.htm
if %using% == wget (
 wget -q %pageURL% -O %pageFile%
 set downloader=wget -q --show-progress -c -N
)
if %using% == curl (
 curl --retry 2 -s %pageURL% -o %pageFile%
 set downloader=curl --retry 2 --ssl -O -L -# -C -
)
if %using% == powershell (
 powershell -command "(New-Object System.Net.WebClient).DownloadFile('%pageURL%', '%pageFile%')"
 set downloader=call :psget
)

if not exist %pageFile% (
 echo Erreur lors de l'obtention des informations de version, veuillez r�essayer ult�rieurement.
 pause
 goto finish
)

set choices=,
for /f "usebackq tokens=2 delims=<>" %%a in (`findstr "<h2>" %pageFile%`) do (set choices=!choices!, %%a)
set choices=!choices:~3!
set /p snapshot=Quelle version de d�veloppement de NVDA voulez-vous? (%choices%): 
set stop=1
for %%a in (%choices%) do (if %snapshot% == %%a set stop=0)
if %stop% == 1 (
 echo %snapshot% n'est pas une version de d�veloppement valide, veuillez r�essayer.
 pause
 goto finish
)

for /f "usebackq tokens=4 delims==" %%a in (`findstr "_%snapshot%" %pageFile%`) do (
 set line=%%a
 set cutline=!line:~0,-6!
 call :confirm !cutline!
 goto finish
)

:confirm
for /f "tokens=3* delims=_" %%a in ("%~n1") do (set version=%%a%%b)
echo La derni�re %snapshot% est %version%
set /p answer=Voulez-vous la t�l�charger? (o/n): 
if %answer% == o goto download
if %answer% == n (
 echo Ah, ok ... � la prochaine fois ^^!
 pause
)
goto :eof

:download
echo T�l�chargement en cours...
if %using% == powershell (echo %using% ne fournit pas d'informations sur le progr�, alors soyez patient...)
%downloader% !cutline!
del %pageFile%
:: last in next line is bell char
echo �PR�T!^^! 
pause
goto :eof

:psget
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%1', '%~dp0%~nx1')"
goto :eof

:finish
chcp %cp%>nul 2>&1
