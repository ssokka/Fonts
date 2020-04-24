@echo off
setlocal
pushd "%~dp0"

:: windows crlf euc-kr



:: check %1 argument = font file
if "%~1" equ "" goto :eof
if /i %~x1 neq .ttf if /i %~x1 neq .ttc goto :eof

:: check /np argument = no pause
for %%i in (%*) do if %%i equ /np set "_np=1"



:: set title
set "_tt=글꼴"

:: set windows bit
set "_bit=64"
if not exist "%ProgramFiles(x86)%" set "_bit=32"

:: set powershell
set "_ps=powershell.exe -NoProfile -Command"

:: set user/system font file path
set "_uf=%LOCALAPPDATA%\Microsoft\Windows\Fonts\%~nx1"
set "_sf=%SystemRoot%\Fonts\%~nx1"

:: set uset/system font registry path
set "_rg=Microsoft\Windows NT\CurrentVersion\Fonts"
set "_ur=HKCU\Software\%_rg%"
set "_sr=HKLM\SOFTWARE\%_rg%"



:: check installed system font
if exist "%_sf%" goto :eof

:: check installed user font
if exist "%_uf%" set "_ui=1" & goto install


:: download font file from github ssokka fonts
call :echo "# %~nx1 %_tt% 다운로드"
call :download "https://raw.github.com/ssokka/Fonts/master/%~nx1" "%temp%\%~nx1"
if %errorlevel% equ 1 call :error & goto :eof



:: install font
:install
call :echo "# %~nx1 %_tt% 설치"
if defined _ui goto install-all

:: install font for user
call :admin powershell.exe "-NoProfile -Command & {(New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere('%temp%\%~nx1')}"
if not exist "%_uf%" call :error & goto :eof

:install-all
:: install font for all user, trick, not official method

:: move font file for system
call :admin cmd.exe "/c move /y '%_uf%' '%_sf%'"
del /f /q "%_uf%" >nul 2>&1
if not exist "%_sf%" call :error & goto :eof

:: get font registry name from current user
for /f "tokens=*" %%f in ('reg query "%_ur%" /f "%~nx1" /t REG_SZ ^| findstr /i "%~nx1"') do set "_rq=%%f"
if not defined _rq call :error & goto :eof
call :replace /text "%_rq%" "(^.*?)\s{4}.*" "$1"
if %errorlevel% equ 1 call :error & goto :eof
if "%_rep%" equ "" call :error & goto :eof
set "_rn=%_rep%"

:: add font registry data for system
call :admin "reg.exe" "add '%_sr%' /v '%_rn%' /t REG_SZ /d '%~nx1' /f"

:: delete font registry data for user
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
set "_dl=0"
if exist "%~2" (
	for /f "tokens=* usebackq" %%f in (`%_ps% "& {if (%_cl% -ne %_pfl%) {Write-Host 1}}"`) do set "_dl=%%f"
) else (
	set "_dl=1"
)
if %_dl% equ 1 %_ps% "& {(New-Object System.Net.WebClient).DownloadFile('%~1', '%~2')}"
set "_el=0"
if exist "%~2" (
	for /f "tokens=* usebackq" %%f in (`%_ps% "& {if (%_cl% -ne %_pfl%) {Write-Host 1}}"`) do set "_el=%%f"
) else (
	exit /b 1
)
goto :eof

:replace
:: %1 = type [/file|/text]
:: %2 = input [file|text]
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
call :echo "* 스크립트를 종료합니다. 아무 키나 누르십시오."
pause >nul
goto :eof
