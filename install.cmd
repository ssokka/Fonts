@echo off
setlocal
pushd "%~dp0"

:: windows crlf euc-kr

:: https://github.com/ssokka/Fonts

:: tested
::   windows 10 Pro 1909 64bit

:: useage default
::   install.cmd "font file" [/np]
::     /np = no pause

:: example command line
::   powershell.exe -NoProfile -Command "& {(New-Object System.Net.WebClient).DownloadFile('https://raw.github.com/ssokka/Fonts/master/install.cmd', '%temp%\install.cmd')}" && "%temp%\install.cmd" "D2Coding.ttc"

:: example script
::   powershell.exe -NoProfile -Command "& {(New-Object System.Net.WebClient).DownloadFile('https://raw.github.com/ssokka/Fonts/master/install.cmd', '%temp%\fi.cmd')}"
::   call "%temp%\fi.cmd" "D2Coding.ttc" /np



:: check argument %1 = font file
if "%~1" equ "" goto :eof
if /i %~x1 neq .ttf if /i %~x1 neq .ttc goto :eof

:: check argument /np = no pause
for %%i in (%*) do if %%i equ /np set "_np=1"

:: set title
set "_tt=글꼴"

:: set windows bit
set "_bit=64"
if not exist "%ProgramFiles(x86)%" set "_bit=32"

:: set error process
set "_er=call :error & goto :eof"

:: set powershell
set "_ps=powershell.exe -NoProfile -Command"

:: set font file
set "_uf=%LOCALAPPDATA%\Microsoft\Windows\Fonts\%~nx1"
set "_sf=%SystemRoot%\Fonts\%~nx1"

:: set font registry
set "_fr=Microsoft\Windows NT\CurrentVersion\Fonts"
set "_ur=HKCU\Software\%_fr%"
set "_sr=HKLM\SOFTWARE\%_fr%"

:: check installed font file
if exist "%_sf%" goto :eof
if exist "%_uf%" set "_ui=1" & goto install

:: download font file from https://raw.github.com/ssokka/Fonts/master
call :echo "# %~nx1 %_tt% 다운로드"
call :download "https://raw.github.com/ssokka/Fonts/master/%~nx1" "%temp%\%~nx1"
if %errorlevel% equ 1 %_er%

:install
call :echo "# %~nx1 %_tt% 설치"
if defined _ui goto system

:: install font for user
call :admin powershell.exe "-NoProfile -Command & {(New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere('%temp%\%~nx1')}"
if not exist "%_uf%" %_er%

:: install font for system = trick, not official method
:system

:: move user font file to system font file
call :admin cmd.exe "/c move /y '%_uf%' '%_sf%'"
del /f /q "%_uf%" >nul 2>&1
if not exist "%_sf%" %_er%

:: get font registry name from installed user font
for /f "tokens=*" %%f in ('reg query "%_ur%" /f "%~nx1" /t REG_SZ ^| findstr /i "%~nx1"') do set "_rq=%%f"
if not defined _rq %_er%
call :replace /text "%_rq%" "(^.*?)\s{4}.*" "$1"
if %errorlevel% equ 1 %_er%
if "%_rep%" equ "" %_er%
set "_rn=%_rep%"

:: add font registry data for system
call :admin "reg.exe" "add '%_sr%' /v '%_rn%' /t REG_SZ /d '%~nx1' /f"

:: delete user font registry data
reg.exe delete "%_ur%" /v "%_rn%" /f >nul 2>&1

:: delete downloaded font file
:: del /f /q "%temp%\%~nx1" >nul 2>&1

goto end & goto :eof



:admin
:: %1 = process
:: %2 = argument
if "%~2" equ "" exit /b 1
if "%~n1" equ "powershell" (
	set "_al=\"%2\""
) else (
	setlocal EnableDelayedExpansion
	set "_al=%~2"
	set "_al='!_al:'=\""!'"
	setlocal DisableDelayedExpansion
)
%_ps% "& {Start-Process -FilePath '%~1' -ArgumentList %_al% -Verb RunAs -WindowStyle Hidden -Wait}"
goto :eof

:download
:: %1 = url
:: %2 = output file
if "%~2" equ "" exit /b 1
set "_pcl=([System.Net.WebRequest]::Create('%~1')).GetResponse().Headers.GetValues('Content-Length')"
set "_pfl=(Get-Item '%~2').Length"
for /f "tokens=* usebackq" %%f in (`%_ps% "& {%_pcl%}"`) do set "_cl=%%f"
if not defined _cl exit /b 1
set _for=for /f "tokens=* usebackq" %%f in (`%_ps% "& {if (%_cl% -And %_cl% -eq %_pfl%) {Write-Host 0}}"`) do
set "_dl=1"
if exist "%~2" %_for% set "_dl=%%f"
if %_dl% equ 1 %_ps% "& {(New-Object System.Net.WebClient).DownloadFile('%~1', '%~2')}"
if exist "%~2" %_for% exit /b %%f
exit /b 1
goto :eof

:replace
:: %1 = input type /file or /text
:: %2 = input file or text
:: %3 = search string
:: %4 = replace string
:: %5 = output file
if %~1 neq /file if %~1 neq /text if "%~4" equ "" exit /b 1
if %~1 equ /file (
	if "%~5" equ "" exit /b 1
	%_ps% "& {(Get-Content '%~2') -Replace '%~3', '%~4' | Set-Content -Path '%~5'}"
)
if %~1 equ /text (
	for /f "tokens=* usebackq" %%f in (`%_ps% "& {(('%~2') -Replace '%~3', '%~4').Trim()}"`) do set "_rep=%%f"
	if not defined _rep exit /b 1
)
goto :eof

:echo
echo.
if "%~1" neq "" echo %~1
goto :eof

:error
echo ! 오류가 발생했습니다.
goto end
exit /b 1

:end
if defined _np goto :eof
call :echo "* 스크립트를 종료합니다. 아무 키나 누르십시오." & pause >nul
goto :eof
