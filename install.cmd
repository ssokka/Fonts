@echo off
setlocal
pushd "%~dp0"

rem windows ansi cp949 euc-kr crlf

set _pn=글꼴

set _bit=64
if not exist "%ProgramFiles(x86)%" set _bit=32

rem %1 = font file
if "%~1" equ "" goto :eof
if /i "%~x1" neq ".ttf" if /i "%~x1" neq ".ttc" goto :eof

rem set font registry key
set _rk=Microsoft\Windows NT\CurrentVersion\Fonts

rem check installed font
reg.exe query "HKLM\SOFTWARE\%_rk%" /f "%~nx1" /d /t REG_SZ | findstr /i "%~nx1" >nul 2>&1
if %errorlevel% equ 0 goto :eof

call :echo "# %~nx1 다운로드"
call :download "https://github.com/ssokka/Fonts/blob/master/%~1?raw=true" "%temp%\%~nx1"
if %errorlevel% equ 1 goto :eof

call :echo "# %~nx1 글꼴 설치"

rem install font for current user
call :admin "powershell.exe" "-Command & {(New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere('%temp%\%~nx1')}"
if not exist "%LOCALAPPDATA%\Microsoft\Windows\Fonts\%~nx1" (
	call :error
	goto :eof
)

rem install font for all user = not official method

rem get font display name
for /f "tokens=*" %%f in ('reg query "HKCU\Software\%_rk%" /f "%~nx1" /t REG_SZ ^| findstr /i "%~nx1"') do set _rq=%%f
if not defined _rq (
	call :error
	goto :eof
)
call :replace "text" "%_rq%" "(^.*?)\s{4}.*" "$1"
if not defined _rep (
	call :error
	goto :eof
)
if "%_rep%" equ "" (
	call :error
	goto :eof
)
set _rn=%_rep%

rem move font file for all users
call :admin "cmd.exe" "/c move /y \""%LOCALAPPDATA%\Microsoft\Windows\Fonts\%~nx1\"" \""%SystemRoot%\Fonts\%~nx1\"""
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Fonts\%~nx1" >nul 2>&1
if not exist "%SystemRoot%\Fonts\%~nx1" (
	call :error
	goto :eof
)

rem add font registry data for all users
call :admin "reg.exe" "add \""HKLM\SOFTWARE\%_rk%\"" /v \""%_rn%\"" /t REG_SZ /d \""%~nx1\"" /f"

rem delete font registry data for current user
reg.exe delete "HKCU\Software\%_rk%" /v "%_rn%" /f >nul 2>&1

rem delete download font file
del /f /q "%temp%\%~nx1" >nul 2>&1

goto :eof

:admin
rem %1 = process
rem %2 = argument
if "%~1" equ "" exit /b 1
if "%~2" equ "" exit /b 1
if "%~n1" equ "powershell" (
	set "_arg=\"%2\""
) else (
	set "_arg='%~2'"
)
powershell.exe -Command "& {Start-Process -FilePath '%~1' -ArgumentList %_arg% -Verb RunAs -WindowStyle Hidden -Wait}"
goto :eof

:download
rem %1 = url
rem %2 = output file
if "%~1" equ "" exit /b 1
if "%~2" equ "" exit /b 1
powershell.exe -Command "& {(New-Object System.Net.WebClient).DownloadFile('%~1', '%~2')}"
if not exist "%~2" call :error
goto :eof

:replace
rem %1 = type [file|text]
rem %2 = input [file|text]
rem %3 = search string
rem %4 = replace string
rem %5 = output file
if "%~1" equ "" exit /b 1
if "%~2" equ "" exit /b 1
if "%~3" equ "" exit /b 1
if "%~4" equ "" exit /b 1
if "%~1" neq "file" if "%~1" neq "text" exit /b 1
if "%~1" equ "file" (
	if "%~5" equ "" exit /b 1
	powershell.exe -Command "& {(Get-Content '%~2') -Replace '%~3', '%~4' | Set-Content -Path '%~5'}"
	goto :eof
)
if "%~1" equ "text" (
	for /f "tokens=* usebackq" %%f in (`powershell.exe -Command "& {(('%~2') -Replace '%~3', '%~4').Trim()}"`) do set _rep=%%f
	goto :eof
)
goto :eof

:echo
if "%~1" equ "" goto :eof
echo.
echo %~1
goto :eof

:error
echo ! 오류가 발생했습니다.
goto exit
exit /b 1
goto :eof

:exit
call :echo "* 스크립트를 종료합니다. 아무 키나 누르십시오."
pause >nul
goto :eof





