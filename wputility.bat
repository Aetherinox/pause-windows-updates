@ECHO       OFF
TITLE       WPU (Windows Personalization Utility)
SETLOCAL    ENABLEDELAYEDEXPANSION
MODE        con:cols=125 lines=40
MODE        125,40
GOTO        comment_end

    This script automatically modifies the registry to disable or enable Windows updates.
    It will also check the standard windows folder where updates are stored, and deletes any
    files or folders within the folder to clean up disk-space. Updates are normally found in:
        c:\windows\softwaredistribution

:comment_end

:: # #
::  @desc           To perform registry edits, we need admin permissions.
::                  Re-launch powershell with admin, and close existing command prompt window
:: # #

if not "%1"=="admin" (powershell start -verb runas '%0' admin & exit /b)

net session > nul 2>&1
if %errorlevel% NEQ 0 (
	echo.   %red% Error   %u%         This script requires elevated privileges to run.
	goto :sessError
)

:: # #
::  @desc           define vars
:: # #

:variables
set dir_home=%~dp0
set dir_reg=%dir_home%registryBackup
set repo_url=https://github.com/Aetherinox/pause-windows-updates
set repo_author=Aetherinox
set repo_version=1.3.0
set "folder_distrb=c:\windows\softwaredistribution"
set "folder_uhssvc=c:\Program Files\Microsoft Update Health Tools"
set cnt_files=0
set cnt_dirs=0

set noUpdatesState="0x0"
set AutoUpdate=false
set AutoUpdateBool=disabled
set AutoUpdateStr=disable

set u=[0m
set bold=[1m
set under=[4m
set inverse=[7m
set blink=[5m
set cyanl=[96m
set cyand=[36m
set magental=[95m
set magentad=[35m
set white=[97m

:: 256 colors
set lime=[38;5;154m
set brown=[38;5;94m
set greenl=[38;5;46m
set green=[38;5;40m
set greenm=[38;5;42m
set greend=[38;5;35m
set yellowl=[38;5;226m
set yellow=[38;5;220m
set bluel=[38;5;45m
set blue=[38;5;39m
set blued=[38;5;33m
set blueb=[38;5;75m
set purplel=[38;5;105m
set purple=[38;5;99m
set fuchsia1=[38;5;1m
set fuchsia2=[38;5;162m
set peach=[38;5;148m
set pinkl=[38;5;13m
set pink=[38;5;206m
set pinkd=[38;5;200m
set yellowl=[38;5;228m
set yellowm=[38;5;226m
set yellowd=[38;5;190m
set orangel=[38;5;215m
set orange=[38;5;208m
set oranged=[38;5;202m
set goldl=[38;5;220m
set goldm=[38;5;178m
set goldd=[38;5;214m
set grayb=[38;5;250m
set greyl=[38;5;247m
set graym=[38;5;244m
set grayd=[38;5;238m
set grayz=[38;5;237m
set redl=[91m
set red=[38;5;160m
set redd=[38;5;124m
set redz=[38;5;88m

:: progress bar
set PROGRESS_BAR_WIDTH=50
set PROGRESS_BAR_CHAR=#

:: add spaces so that service names are in columns
set "spaces=                                       "

:: # #
::  define services
::      uhssvc                                      Microsoft Update Health Service
::      UsoSvc                                      Update Orchestrator Service
::      WaaSMedicSvc                                Windows Update Medic Service
::      wuauserv                                    Windows Update Service
::      
::      DiagTrack                                   Connected User Experiences and Telemetry
::      dmwappushservice                            Device Management Wireless Application Protocol (WAP) Push message Routing Service
::      diagsvc                                     Diagnostic Execution Service
::      diagnosticshub.standardcollector.service    Microsoft (R) Diagnostics Hub Standard Collector Service
:: # #

set servicesUpdates=uhssvc UsoSvc WaaSMedicSvc wuauserv
set servicesTelemetry=DiagTrack dmwappushservice diagsvc diagnosticshub.standardcollector.service

:: Update Service IDs to Names
set servicesUpdatesNames[uhssvc]=Microsoft Update Health Service
set servicesUpdatesNames[UsoSvc]=Update Orchestrator Service
set servicesUpdatesNames[WaaSMedicSvc]=WaaSMedicSvc
set servicesUpdatesNames[wuauserv]=Windows Update

:: Telemetry Service IDs to Names
set servicesTelemetryNames[DiagTrack]=Connected User Experiences and Telemetry
set servicesTelemetryNames[dmwappushservice]=Device Management Wireless Application
set servicesTelemetryNames[diagsvc]=Diagnostic Execution Service
set servicesTelemetryNames[diagnosticshub.standardcollector.service]=Microsoft (R) Diagnostics Hub

:: Disable tasks
set schtasksDisable[0]=\Microsoft\Windows\Application Experience\AITAgent
set schtasksDisable[1]=\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser
set schtasksDisable[2]=\Microsoft\Windows\Application Experience\ProgramDataUpdater
set schtasksDisable[3]=\Microsoft\Windows\Customer Experience Improvement Program\Consolidator
set schtasksDisable[4]=\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask
set schtasksDisable[5]=\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip
set schtasksDisable[6]=\Microsoft\Office\OfficeTelemetryAgentFallBack
set schtasksDisable[7]=\Microsoft\Office\OfficeTelemetryAgentLogOn
set schtasksDisable[8]=\Microsoft\Office\OfficeTelemetryAgentFallBack2016
set schtasksDisable[9]=\Microsoft\Office\OfficeTelemetryAgentLogOn2016
set schtasksDisable[10]=\Microsoft\Office\Office 15 Subscription Heartbeat
set schtasksDisable[11]=\Microsoft\Office\Office 16 Subscription Heartbeat
set schtasksDisable[12]=\Microsoft\Windows\Maintenance\WinSAT
set schtasksDisable[13]=\Microsoft\Windows\CloudExperienceHost\CreateObjectTask
set schtasksDisable[14]=\Microsoft\Windows\NetTrace\GatherNetworkInfo
set schtasksDisable[15]=\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector

:: # #
::  @desc           define os ver and name
:: # #

for /f "usebackq tokens=1,2 delims==|" %%I in (`wmic os get osarchitecture^,name^,version /format:list`) do 2> nul set "%%I=%%J"
for /f "UseBackQ Tokens=1-4" %%A In ( `powershell "$OS=GWmi Win32_OperatingSystem;$UP=(Get-Date)-"^
    "($OS.ConvertToDateTime($OS.LastBootUpTime));$DO='d='+$UP.Days+"^
    "' h='+$UP.Hours+' n='+$UP.Minutes+' s='+$UP.Seconds;Echo $DO"`) do (
        set "%%A"&set "%%B"&set "%%C"&set "%%D"
)

:: # #
::  @desc           Main
:: # #

:main

    setlocal

    :: # #
    ::  @desc           Check user registry to see if automatic updates are currently enabled or disabled
    ::                  registry will return the following for auto update status
    ::                      0x0         updates are enabled
    :                       0x1         updates are disabled
    :: # #

    FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate`) DO (
        set noUpdatesState=%%A
    )

    if /i "%noUpdatesState%" == "0x0" (
        set AutoUpdate=true
        set AutoUpdateBool=%greenm%enabled%u%
        set AutoUpdateStr=%greenm%!AutoUpdateBool:~0,-1!%u%

    ) else (
        set AutoUpdate=false
        set AutoUpdateBool=%orange%disabled%u%
        set AutoUpdateStr=%orange%!AutoUpdateBool:~0,-1!%u%
    )

    title WPU (Windows Personalization Utility)

    set q_mnu_main=
    set q_mnu_adv=

    chcp 65001 > nul
    cls
    echo.
    echo.
    echo.     %goldm%v%repo_version%%u%                               %grayd%Windows Personalization Utility%u%
    echo.
    echo  %fuchsia2%    ██╗    ██╗██████╗ ██╗   ██╗████████╗██╗██╗     ██╗████████╗██╗   ██╗
    echo      ██║    ██║██╔══██╗██║   ██║╚══██╔══╝██║██║     ██║╚══██╔══╝╚██╗ ██╔╝
    echo      ██║ █╗ ██║██████╔╝██║   ██║   ██║   ██║██║     ██║   ██║    ╚████╔╝ 
    echo      ██║███╗██║██╔═══╝ ██║   ██║   ██║   ██║██║     ██║   ██║     ╚██╔╝  
    echo      ╚███╔███╔╝██║     ╚██████╔╝   ██║   ██║███████╗██║   ██║      ██║   
    echo       ╚══╝╚══╝ ╚═╝      ╚═════╝    ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   
    echo.
    echo.
    echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%

    echo.    %cyand% Author  %grayb%       %repo_author%%u%
    echo.    %cyand% Repo    %grayb%       %repo_url%
    echo.    %cyand% OS      %grayb%       %version% %graym%(%name% %osarchitecture%)%u%
    echo.    %cyand% Uptime  %grayb%       %d% %graym%days%u% %h% %graym%hours%u% %n% %graym%minutes%u% %s% %graym%seconds
    echo.    %cyand% Status  %grayb%       Windows Updates %AutoUpdateBool%%u%

    echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
    echo.

    if /I "%AutoUpdate%" EQU "true" (
        echo.     %goldm%^(1^)%u%   Disable Updates
        echo.     %grayd%^(2^)%grayd%   Enable Updates
    ) else (
        echo.     %grayd%^(1^)%grayd%   Disable Updates
        echo.     %goldm%^(2^)%u%   Enable Updates
    )

    echo.

    echo.     %goldm%^(3^)%u%   Disable Microsoft Telemetry
    echo.     %goldm%^(4^)%u%   Remove Update Files
    echo.     %goldm%^(5^)%u%   Manage Update Services
    echo.     %goldm%^(6^)%u%   Backup Registry
    echo.
    echo.     %goldm%^(A^)%u%   Advanced
    echo.
    echo.     %greenm%^(H^)%greenm%   Help
    echo.     %blueb%^(S^)%blueb%   Supporters
    echo.     %redl%^(Q^)%redl%   Quit

    echo.
    echo.
    set /p q_mnu_main="%goldm%    Pick Option » %u%"
    echo.

    :: # #
    ::  @desc           Menu > Help
    :: # #

    if /I "!q_mnu_main!" EQU "H" (

        cls

        echo.
        echo.
        echo %u%    This utility allows you to do the following tasks:
        echo.

        if /I "%AutoUpdate%" EQU "true" (
            echo       %goldm%^(1^)%greenm%   Disable Updates%u%
        ) else (
            echo       %grayd%^(1^)%greend%   Disable Updates%u% %goldd%[Already disabled]%u%
        )
        echo             %grayd%Disable Windows automatic updates. Updates will be halted until re-enabled.
        echo             %grayd%All pending update files on your device will be deleted to clean up disk-space.
        echo             %grayd%Files will be re-downloaded if you enable Windows updates at a later time.

        echo.

        if /I "%AutoUpdate%" EQU "true" (
            echo       %grayd%^(2^)%greend%   Enable Updates%u% %goldd%[Already enabled]%u%
        ) else (
            echo       %goldm%^(2^)%greenm%   Enable Updates%u%
        )
        echo             %grayd%Enable windows updates on your system.

        echo.

        echo       %goldm%^(3^)%greenm%   Disable Microsoft Telemetry%u%
        echo             %grayd%Disables the ability for Microsoft to receive telemetry data from your device.

        echo.

        echo       %goldm%^(4^)%greenm%   Remove Update Files%u%
        echo             %grayd%Pending update files on your device will be deleted to clean up disk-space.
        echo             %grayd%This task is automatically performed if you select option 1%u%

        echo.

        echo       %goldm%^(5^)%greenm%   Manage Update Services%u%
        echo             %grayd%This option allows you to view Windows Update's current status, as well as 
        echo             %grayd%enable or disable Windows Update system services.
        echo             %grayd%This task is automatically performed if you select option 1%u%

        echo.

        echo       %goldm%^(6^)%greenm%   Backup Registry%u%
        echo             %grayd%Create a backup of your registry

        echo.

        echo       %goldm%^(S^)%greenm%   Supporters%u%
        echo             %grayd%A list of people who have donated to this project.

        echo.

        echo       %redl%^(R^)%redl%   Return
    
        echo.
        echo.
        set /p q_mnu_main="%goldm%    Pick Option » %u%"
        echo.
    )

    :: # #
    ::  @desc           Menu > Sponsors
    :: # #

    if /I "!q_mnu_main!" EQU "S" (

        cls

        echo.
        echo.

        echo %u%    If you wish to support this project, you may drop a donation at %goldd%https://buymeacoffee.com/aetherinox.
        echo %u%    To have your name added, donate and leave a comment which gives us your Github username.
        echo.
        echo %u%    A special thanks to the following for donating:

        echo.
        echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
        echo.

        echo       %greenm%   Chad May%u%

        echo.
        echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
        echo.

        echo.   %cyand% Notice  %u%        Press any key to return
        pause > nul
    )

    if /I "!q_mnu_main!" equ "R" (
        cls
        goto :main
    )

    :: option > (1) Disable Updates
    if /I "%q_mnu_main%" equ "1" (
        goto :taskUpdatesDisable
    )

    :: option > (2) Enable Updates
    if /I "%q_mnu_main%" equ "2" (
        goto :taskUpdatesEnable
    )

    :: option > (3) Disable Telemetry
    if /I "%q_mnu_main%" equ "3" (
        goto :taskDisableTelemetry
    )

    :: option > (4) Clean windows update dist folder
    if /I "%q_mnu_main%" equ "4" (
        goto :taskStartErase
    )

    :: option > (5) Manage Update Services
    if /I "%q_mnu_main%" equ "5" (
        goto :menuServices
    )

    :: option > (6) Backup Registry
    if /I "%q_mnu_main%" equ "6" (
        goto :taskBackupRegistry
    )

    :: option > (A) Advanced
    if /I "!q_mnu_main!" equ "A" (
        goto :menuAdvanced
    )

    :: option > (Q) Quit
    if /I "%q_mnu_main%" equ "Q" (
        goto :sessQuit
    ) else (
        echo.   %red% Error   %u%         Unrecognized Option %yellowl%%q_mnu_main%%u%

        goto :main
    )

    endlocal
goto :EOF

:: # #
::  @desc           Menu > Advanced
:: # #

:menuAdvanced
    setlocal
    cls

    :: set states
    set stateCortanaDword=0x0
    set stateCortanaOpp=Disable
    for /F "usebackq tokens=3*" %%A in (`reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" 2^>nul`) do (
        set stateCortanaDword=%%A
    )
    if /I "%stateCortanaDword%"=="0x0" set stateCortanaOpp=Enable

    set q_mnu_adv=

    echo.
    echo.

    echo      %yellowd%^(1^)%u%   %stateCortanaOpp% Cortana
    echo      %yellowd%^(2^)%u%   Uninstall Crapware
    echo.
    echo      %redl%^(R^)%redl%   Return

    echo.
    echo.
    set /p q_mnu_adv="%goldm%    Pick Option » %u%"
    echo.

    echo.

    :: option > (1) Disable Cortana
    if /I "%q_mnu_adv%" equ "1" (
        call :taskToggleCortana %stateCortanaOpp%
        goto :menuAdvanced
    )

    :: option > (2) Uninstall Crapware
    if /I "%q_mnu_adv%" equ "2" (
        call :taskUninstallCrapware
        goto :menuAdvanced
    )

    :: option > (R) Return
    if /I "%q_mnu_adv%" equ "R" (
        goto :main
    ) else (
        echo.   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_adv%%u%, press any key and try again.
        pause > nul

        goto :menuAdvanced
    )

    endlocal
goto :EOF

:: # #
::  @desc           Menu > Services
:: # #

:menuServices
    setlocal
    cls
    set q_mnu_serv=

    echo.

    echo       %yellowd%^(1^)%u%   View Status
    echo       %yellowd%^(2^)%u%   Enable Update Services
    echo       %yellowd%^(3^)%u%   Disable Update Services
    echo.
    echo       %redl%^(R^)%redl%   Return

    echo.
    echo.
    set /p q_mnu_serv="%goldm%    Pick Option » %u%"
    echo.

    echo.

    :: option > (1) View Service Status
    if /I "%q_mnu_serv%" EQU "1" (

        echo.   %cyand% Notice  %u%        Getting Service Status%u%

        :: loop services and check status
        for %%i in (%servicesUpdates%) do (
            set y=!servicesUpdatesNames[%%i]!
            for /F "tokens=3 delims=: " %%H in ('sc query "%%i" ^| findstr "        STATE"') do (
                set "service=!y! %pink%[%%i] !spaces!"
                set "service=!service:~0,50!"
                if /I "%%H" NEQ "RUNNING" (
                    echo.   %cyand%         %grayd%          !service! %red%Not Running%u%
                ) else (
                    echo.   %cyand%         %grayd%          !service! %greenl%Running%u%
                )
            )
        )

        echo.   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul

        goto :menuServices
    )

    :: option > (2) Enable Update Services
    if /I "%q_mnu_serv%" EQU "2" (
        echo.   %cyand% Notice  %u%        Enabling Windows Update Services ...

        for %%i in (%servicesUpdates%) do (
            set y=!servicesUpdatesNames[%%i]!
            set "service=!y! %pink%[%%i] !spaces!"
            set "service=!service:~0,50!"

            echo.   %cyand%         %grayd%          !service! %greenl%enabled%u%
            sc config %%i start= auto > nul 2>&1
            net start %%i > nul 2>&1
        )

        echo.   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul
    
        goto :menuServices
    )

    :: option > (3) Disable Update Services
    if /I "%q_mnu_serv%" EQU "3" (
        echo.   %cyand% Notice  %u%        Disabling Windows Update Services ...

        for %%i in (%servicesUpdates%) do (
            set y=!servicesUpdatesNames[%%i]!
            set "service=!y! %pink%[%%i] !spaces!"
            set "service=!service:~0,50!"

            echo.   %cyand%         %grayd%          !service! %red%disabled%u%
            net stop %%i > nul 2>&1
            sc config %%i start= disabled > nul 2>&1
            sc failure %%i reset= 0 actions= "" > nul 2>&1
        )

        echo.   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul
    
        goto :menuServices
    )

    :: option > (R) Return
    if /I "%q_mnu_serv%" EQU "R" (
        goto :main
    ) else (
        echo.   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_serv%%u%, press any key and try again.
        pause > nul

        goto :menuServices
    )
    endlocal
goto :EOF

:: # #
::  @desc           Backup Registry
:: # #

:taskBackupRegistry

    setlocal

    echo.   %purplel% Status  %u%        Starting registry backup, this may take a few moments%u%

    call :progressUpdate 10 "Creating new file %dir_reg%"

    if NOT exist "%dir_reg%" (
        md "%dir_reg%"
    )

    if exist "%dir_reg%\HKLM.reg" (
        erase "%dir_reg%\HKLM.reg"
    )
    call :progressUpdate 20 "Export HKLM from registry to file HKLM.reg"
    reg export HKLM "%dir_reg%\HKLM.reg" > nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        Error occurred backing up %grayd%%dir_reg%\HKLM.reg%u%
    ) else if %errorlevel% EQU 0 (
        echo.   %greenl% Success %u%        Backed up %grayd%%dir_reg%\HKLM.reg%u%
    )

    if exist "%dir_reg%\HKCU.reg" (
        erase "%dir_reg%\HKCU.reg"
    )
    call :progressUpdate 40 "Export HKCU from registry to file HKCU.reg"
    reg export HKCU "%dir_reg%\HKCU.reg" > nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        Error occurred backing up %grayd%%dir_reg%\HKCU.reg%u%
    ) else if %errorlevel% EQU 0 (
        echo.   %greenl% Success %u%        Backed up %grayd%%dir_reg%\HKCU.reg%u%
    )

    if exist "%dir_reg%\HKCR.reg" (
        erase "%dir_reg%\HKCR.reg"
    )
    call :progressUpdate 60 "Export HKCR from registry to file HKCR.reg"
    reg export HKCR "%dir_reg%\HKCR.reg" > nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        Error occurred backing up %grayd%%dir_reg%\HKCR.reg%u%
    ) else if %errorlevel% EQU 0 (
        echo.   %greenl% Success %u%        Backed up %grayd%%dir_reg%\HKCR.reg%u%
    )

    if exist "%dir_reg%\HKU.reg" (
        erase "%dir_reg%\HKU.reg"
    )
    call :progressUpdate 80 "Export HKU from registry to file HKU.reg"
    reg export HKU "%dir_reg%\HKU.reg" > nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        Error occurred backing up %grayd%%dir_reg%\HKU.reg%u%
    ) else if %errorlevel% EQU 0 (
        echo.   %greenl% Success %u%        Backed up %grayd%%dir_reg%\HKU.reg%u%
    )

    if exist "%dir_reg%\HKCC.reg" (
        erase "%dir_reg%\HKCC.reg"
    )
    call :progressUpdate 100 "Export HKCC from registry to file HKCC.reg"
    reg export HKCC "%dir_reg%\HKCC.reg" > nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        Error occurred backing up %grayd%%dir_reg%\HKCC.reg%u%
    ) else if %errorlevel% EQU 0 (
        echo.   %greenl% Success %u%        Backed up %grayd%%dir_reg%\HKCC.reg%u%
    )

    call :progressUpdate 100 "Export Complete"
    echo.   %greenl% Success %u%        Registry backuped up to %goldm%%dir_reg%%u%

    endlocal

    goto :sessFinish

:: # #
::  @desc           Start
:: # #

:taskStart

    setlocal
    echo.
    echo.   %cyand% Notice  %u%        %grayd% Scanning        %yellowl% %folder_distrb% %u%

    if exist %folder_distrb%\ (

        for /f %%a in ('dir /s /B /a-d "%folder_distrb%"')  DO (
            set /A cnt_files+=1
        )

        for /f %%a in ('dir /s /B /ad "%folder_distrb%"')  DO (
            set /A cnt_dirs+=1
        )

        echo.   %u%                 %grayd% Files%u%           %yellowl% !cnt_files! %u%
        echo.   %u%                 %grayd% Folders%u%         %yellowl% !cnt_dirs! %u%

    ) else (
        echo.   %cyand% Notice  %u%        Could not find %grayd% %folder_distrb%%u%; nothing to do.
        goto sessFinish
    )

    timeout /t 1 > nul
    echo.

    echo.   %grayd% Confirm %yellowd%        Would you like to delete the Windows Update distribution files?%u%
    echo.   %u%                  Type %greenl%Yes to continue%u% or %red%No to return%u%
    echo.
    set /p confirm="%u%                     Delete windows update files? » %u%"

    if /I "%confirm%"=="Yes"   goto taskStart
    if /I "%confirm%"=="yes" goto taskStart
    if /I "%confirm%"=="No"   goto sessFinish
    if /I "%confirm%"=="no"  goto sessFinish
    endlocal
goto :EOF

:: # #
::  @desc           Removes all downloaded windows update files
::  @args               /p                      Prompts for confirmation before deleting the specified file.
::                      /f                      Forces deletion of read-only files.
::                      /s                      Deletes specified files from the current directory and all subdirectories.
::                                              Displays the names of the files as they are being deleted.
::                      /q                      Specifies quiet mode. You are not prompted for delete confirmation.
::                      /                       Deletes files based on the following file attributes:
::                      a[:]<attributes>            r Read-only files
::                                                  h Hidden files
::                                                  i Not content indexed files
::                                                  s System files
::                                                  a Files ready for archiving
::                                                  l Reparse points
::                                                  - Used as a prefix meaning 'not'
::  @ref            https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/erase
:: # #

:taskFilesErase
    if exist %folder_distrb%\ (
        erase /s /f /q %folder_distrb%\*.* && rmdir /s /q %folder_distrb%
    ) else (
        echo.   %cyand% Notice  %u%        Windows Updates folder already clean, skipping %grayd% %folder_distrb%%u%
        goto sessFinish
    )

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        An error has occurred while trying to delete files and folders in %grayd%%folder_distrb%%u%
    ) else if %errorlevel% EQU 0 (
        echo.   %greenl% Success %u%        No errors reported while deleting files, continuing.
    )

    :: windows update dist folder found

    if exist %folder_distrb%\ (
        echo.   %red% Error   %u%         Something went wrong, folder still exists: %grayd%%folder_distrb%%u%

        set cnt_files=0
        set cnt_dirs=0
        for /f %%a in ('dir /s /B /a-d "%folder_distrb%"')  DO (
            set /A cnt_files+=1
        )

        If NOT "!cnt_files!"=="0" (
            echo.   %red% Error   %u%         Something went wrong, files still exist in %grayd%%folder_distrb%%u%
            echo.   %yellowd%                  Try navigating to the folder and manually deleting all files and folders.
            goto sessError
        )

        for /f %%a in ('dir /s /B /ad "%folder_distrb%"')  DO (
            set /A cnt_dirs+=1
        )

        If NOT "!cnt_dirs!"=="0" (
            echo.   %red% Error   %u%        Something went wrong, folders still exist in %grayd%%folder_distrb%%u%
            echo.   %yellowd%                 Try navigating to the folder and manually deleting all files and folders.
            goto sessError
        )

        :: just here as a catch-all for issues
        goto sessError
    ) else (
        echo.   %cyand% Notice  %u%        Validated that all files and folders have been deleted in %grayd% %folder_distrb%%u%
        goto sessFinish
    )

:: # #
::  @desc           Disables Windows Updates
::  @usage          [ QUERY | ADD | DELETE | COPY | SAVE | LOAD | UNLOAD | RESTORE | COMPARE | EXPORT | IMPORT | FLAGS ]
::
::                  Return Code: (Except for REG COMPARE)
::                      0 - Successful
::                      1 - Failed
::
::                  ADD
::                      /v                      The value name, under the selected Key, to add.
::                      /t                      RegKey data types
::                      /s                      Specify one character that you use as the separator in your data
::                                                  string for REG_MULTI_SZ. If omitted, use "\0" as the separator.
::                                              [ REG_SZ | REG_MULTI_SZ | REG_EXPAND_SZ | REG_DWORD | REG_QWORD | REG_BINARY | REG_NONE ]
::                                                  If omitted, REG_SZ is assumed.
::                      /d                      The data to assign to the registry ValueName being added.
::                      /f                      Force overwriting the existing registry entry without prompt.
::                      /reg:32                 Specifies the key should be accessed using the 32-bit registry view.
::                      /reg:64                 Specifies the key should be accessed using the 64-bit registry view.
:: # #

:taskUpdatesDisable
    echo.   %cyand% Notice  %u%        Disabling Windows Update Services ...%u%

    for %%i in (%servicesUpdates%) do (
        set y=!servicesUpdatesNames[%%i]!
        set "service=!y! %pink%[%%i] !spaces!"
        set "service=!service:~0,50!"

        echo.   %cyand%         %grayd%          !service! %red%disabled%u%
        net stop %%i > nul 2>&1
        sc config %%i start= disabled > nul 2>&1
        sc failure %%i reset= 0 actions= "" > nul 2>&1
    )

    :: Windows Update > Dates
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesStartTime" /t REG_SZ /d "2025-01-01T00:00:00Z" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesEndTime" /t REG_SZ /d "2051-12-31T00:00:00Z" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesStartTime" /t REG_SZ /d "2025-01-01T00:00:00Z" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesEndTime" /t REG_SZ /d "2051-12-31T00:00:00Z" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesStartTime" /t REG_SZ /d "2025-01-01T00:00:00Z" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesExpiryTime" /t REG_SZ /d "2051-12-31T00:00:00Z" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursStart" /t REG_DWORD /d "0x0000000d" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursEnd" /t REG_DWORD /d "0x00000007" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "FlightSettingsMaxPauseDays" /t REG_DWORD /d "0x00002727" /f > nul

    :: Services\WaaSMedicSvc / disable windows update service
    ::      0 = Boot  '1 = System  '2 = Automatic  3 = Manual  4 = Disabled
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "0x00000004" /f > nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "FailureActions" /t REG_BINARY /d 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 /f > nul

    :: WindowsUpdate\AU
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUShutdownOption" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AlwaysAutoRebootAtScheduledTime" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d "0x00000000" /f > nul

    :: UpdatePolicy\Settings
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureStatus" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityStatus" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityDate" /t REG_SZ /d "2025-01-01T00:00:00Z" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureDate" /t REG_SZ /d "2025-01-01T00:00:00Z" /f > nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%         An error occurred trying to edit your registry%u%
        goto sessError
    )

    if %errorlevel% EQU 0 (
        echo.   %greenl% Success %u%        Registry has been modified, updates are disabled.
    )

    goto taskFilesErase

:: # #
::  @desc           Enables Windows Updates
:: # #

:taskUpdatesEnable
    echo.   %cyand% Notice  %u%        Enabling Windows Update Services ...%u%

    for %%i in (%servicesUpdates%) do (
        set y=!servicesUpdatesNames[%%i]!
        set "service=!y! %pink%[%%i] !spaces!"
        set "service=!service:~0,50!"

        echo.   %cyand%         %grayd%          !service! %greenl%enabled%u%
        sc config %%i start= auto > nul 2>&1
        net start %%i > nul 2>&1
    )

    :: Windows Update > Dates
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesStartTime" /t REG_SZ /d "" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesEndTime" /t REG_SZ /d "" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesStartTime" /t REG_SZ /d "" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesEndTime" /t REG_SZ /d "" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesStartTime" /t REG_SZ /d "" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesExpiryTime" /t REG_SZ /d "" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursStart" /t REG_DWORD /d "0x0000000d" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursEnd" /t REG_DWORD /d "0x00000007" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "FlightSettingsMaxPauseDays" /t REG_DWORD /d "0x00002727" /f > nul

    :: Services\WaaSMedicSvc / enables windows update service
    ::      0 = Boot  '1 = System  '2 = Automatic  3 = Manual  4 = Disabled
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "00000003" /f > nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "FailureActions" /t REG_BINARY /d "840300000000000000000000030000001400000001000000c0d4010001000000e09304000000000000000000" /f > nul

    :: WindowsUpdate\AU
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUShutdownOption" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AlwaysAutoRebootAtScheduledTime" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d "0x00000001" /f > nul

    :: UpdatePolicy\Settings
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureStatus" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityStatus" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityDate" /t REG_SZ /d "" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureDate" /t REG_SZ /d "" /f > nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        An error occurred trying to edit your registry%u%
        goto sessError
    )

    if %errorlevel% EQU 0 (
        echo.   %greenl% Success %u%        Registry has been modified
    )

    goto sessFinish

:: # #
::  @desc           Disables Windows Telemetry Reporting
:: # #

:taskDisableTelemetry
    echo.   %cyand% Motice  %u%        Modifying registry to disable %goldm%Microsoft Windows%u% telemetry and tracking%u%

	reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUAU" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKLM\SOFTWARE\Microsoft\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v "DontRetryOnError" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v "IsCensusDisabled" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v "TaskEnableRun" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\SQMLogger" /v "Start" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Strings" /v "DiagnosticErrorText" /t REG_SZ /d "" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Strings" /v "DiagnosticLinkText" /t REG_SZ /d "" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" /v "DiagnosticErrorText" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SYSTEM\ControlSet001\Services\DiagTrack" /v "Start" /t REG_DWORD /d "0x00000004" /f > nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener" /v "Start" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice" /v "Start" /t REG_DWORD /d "0x00000004" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableThirdPartySuggestions" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\Software\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\activity" /v "Value" /t REG_SZ /d "Deny" /f > nul
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\cellularData" /v "Value" /t REG_SZ /d "Deny" /f > nul
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\gazeInput" /v "Value" /t REG_SZ /d "Deny" /f > nul
    reg add "HKLM\SYSTEM\DriverDatabase\Policies\Settings" /v "DisableSendGenericDriverNotFoundToWER" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\IE" /v "SqmLoggerRunning" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0x00000000" /f
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "SqmLoggerRunning" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "DisableOptinExperience" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Reliability" /v "SqmLoggerRunning" /t REG_DWORD /d "0x00000000" /f
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Reliability" /v "CEIPEnable" /t REG_DWORD /d "0x00000000" /f
	reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0" /v "NoActiveHelp" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKCU\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0" /v "NoExplicitFeedback" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "MicrosoftEdgeDataOptIn" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "LimitEnhancedDiagnosticDataWindowsAnalytics" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowCommercialDataPipeline" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowDeviceNameInTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DoReport" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowTailoredExperiencesWithDiagnosticData" /v "value" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\LimitDiagnosticLogCollection" /v "value" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\LimitDumpCollection" /v "value" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\LimitEnhancedDiagnosticDataWindowsAnalytics" /v "value" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\DisableDiagnosticDataViewer" /v "value" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\ScriptedDiagnosticsProvider\Policy" /v "EnableDiagnostics" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v "NoGenTicket" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v "AllowWindowsEntitlementReactivation" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseGlobal" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl\StorageTelemetry" /v "DeviceDumpEnabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Tracing\SCM\Regular" /v "TracingDisabled" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\MSDeploy\3" /v "EnableTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowDesktopAnalyticsProcessing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowUpdateComplianceProcessing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowWUfBCloudProcessing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "LimitDumpCollection" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "EnableExtendedBooksTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "LimitDiagnosticLogCollection" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowDesktopAnalyticsProcessing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowUpdateComplianceProcessing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowWUfBCloudProcessing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "LimitDumpCollection" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "EnableExtendedBooksTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "LimitDiagnosticLogCollection" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowDesktopAnalyticsProcessing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowUpdateComplianceProcessing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowWUfBCloudProcessing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "LimitDumpCollection" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "EnableExtendedBooksTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "LimitDiagnosticLogCollection" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowTelemetry" /v "value" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Steps-Recorder" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Program-Telemetry" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Program-Inventory" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Program-Compatibility-Troubleshooter" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Program-Compatibility-Assistant/Trace" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Program-Compatibility-Assistant/Compatibility-Infrastructure-Debug" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Program-Compatibility-Assistant/Analytic" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Application-Experience/Program-Compatibility-Assistant" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\SOFTWARE\Microsoft\Tracing\WPPMediaPerApp\Skype\ETW" /v "TraceLevelThreshold" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\SOFTWARE\Microsoft\Tracing\WPPMediaPerApp\Skype" /v "EnableTracing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\SOFTWARE\Microsoft\Tracing\WPPMediaPerApp\Skype\ETW" /v "EnableTracing" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\SOFTWARE\Microsoft\Tracing\WPPMediaPerApp\Skype" /v "WPPFilePath" /t REG_SZ /d "%%SYSTEMDRIVE%%\TEMP\Tracing\WPPMedia" /f > nul
    reg add "HKCU\SOFTWARE\Microsoft\Tracing\WPPMediaPerApp\Skype\ETW" /v "WPPFilePath" /t REG_SZ /d "%%SYSTEMDRIVE%%\TEMP\WPPMedia" /f > nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        Error occurred trying to edit your registry%u%
        goto sessError
    )

    echo.   %cyand% Motice  %u%        Modifying registry to disable %goldm%Microsoft Office%u% telemetry settings%u%

	reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Common" /v "QMEnable" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Common\Feedback" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Calendar" /v "EnableCalendarLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Mail" /v "EnableLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\15.0\Word\Options" /v "EnableLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Common" /v "QMEnable" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry" /v "DisableTelemetry" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry" /v "VerboseLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Common\Feedback" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Calendar" /v "EnableCalendarLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Mail" /v "EnableLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\16.0\Word\Options" /v "EnableLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry" /v "DisableTelemetry" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry" /v "VerboseLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM" /v "EnableLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM" /v "EnableUpload" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM" /v "EnableLogging" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM" /v "EnableUpload" /t REG_DWORD /d "0x00000000" /f > nul

    echo.   %purplel% Status  %u%        Erasing %blue%%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*.etl%u%
	erase "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*.etl" > nul 2>&1

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        Error occurred deleting the files %blue%%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*.etl%u%
    )

    echo.   %purplel% Status  %u%        Erasing %blue%%ProgramData%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\*.etl%u%
	erase "%ProgramData%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\*.etl" > nul 2>&1

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        Error occurred deleting the files %blue%%ProgramData%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\*.etl%u%
    )

	echo "" > "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl"

    :: # #
    ::  Windows Media Player Usage Telemetry
    :: # #

    echo.   %purplel% Status  %u%        Disable telemetry for %goldm%Windows Media Player%u%
	reg add "HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences" /v "UsageTracking" /t REG_DWORD /d "0x00000000" /f > nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        Error occurred trying to edit your registry%blue%UsageTracking%u%
        goto sessError
    )

    :: # #
    ::  disable diagnostics and telemetry apps
    ::  
    ::  schtasks parameter List:
    ::      /Create                 Creates a new scheduled task.
    ::      /Delete                 Deletes the scheduled task(s).
    ::      /Query                  Displays all scheduled tasks.
    ::      /Change                 Changes the properties of scheduled task.
    ::      /Run                    Runs the scheduled task on demand.
    ::      /End                    Stops the currently running scheduled task.
    ::      /ShowSid                Shows the security identifier corresponding to a scheduled task name.
    ::
    ::      /TN         taskname    Specifies the path\name of the task to change.
    ::      /ENABLE                 Enables the scheduled task.
    ::      
    ::      /DISABLE                Disables the scheduled task.
    ::  
    ::      /Z                      Marks the task for deletion after its final run.
    :: # #

    for /l %%n in (0,1,11) do (
        set task=!schtasksDisable[%%n]!
        echo.   %purplel% Status  %u%        Disable task %blue%!task! %u%
	    schtasks /Change /TN "!task!" /DISABLE > nul 2>&1
    )

    :: # #
    ::  disable compat telemetry runner
    ::  This app connects to Microsoft's servers to share diagnostics and feedback about how you use Microsoft Windows
    :: # #

    echo.   %purplel% Status  %u%        Disable process %blue%%windir%\System32\CompatTelRunner.exe %u%
	takeown /F %windir%\System32\CompatTelRunner.exe > nul 2>&1
	icacls %windir%\System32\CompatTelRunner.exe /grant %username%:F > nul 2>&1
	del %windir%\System32\CompatTelRunner.exe /f > nul 2>&1

    :: # #
    ::  Disable Telemetry Services
    :: 
    ::  DiagTrack (Connected User Experiences and Telemetry)
    ::      The Connected User Experiences and Telemetry service enables features that support in-application and connected user experiences.
    ::      Additionally, this service manages the event driven collection and transmission of diagnostic and usage information 
    ::      (used to improve the experience and quality of the Windows Platform) when the diagnostics and usage privacy option settings are
    ::      enabled under Feedback and Diagnostics.
    ::  
    ::  dmwappushservice
    ::      Routes Wireless Application Protocol (WAP) Push messages received by the device and synchronizes Device Management sessions
    :: # #

    for %%i in (%servicesTelemetry%) do (
        set y=!servicesTelemetryNames[%%i]!
        set "service=!y! %pink%[%%i] !spaces!"
        set "service=!service:~0,80!"

        echo.   %cyand%         %grayd%          !service! %red%disabled%u%
        net stop %%i > nul 2>&1
        sc config %%i start= disabled > nul 2>&1
        sc failure %%i reset= 0 actions= "" > nul 2>&1
    )

    goto sessFinish

:: # #
::  @desc           Quit
:: # #

:sessQuit
    setlocal
    echo.   %greenl% Success %u%        Exiting, Press any key to exit%u%
    pause > nul
    endlocal
exit /B 0

:: # #
::  @desc           Finish and Exit
:: # #

:sessFinish
    setlocal
    echo.   %cyand% Notice  %u%        Operation completed, Press any key to return%u%
    pause > nul
    endlocal
goto :main

:: # #
::  @desc           Finish with error and Exit
:: # #

:sessError
    setlocal
    echo.   %red% Error   %u%        This utility finished, but with errors. Read the logs above to see the issue.%u%
    pause > nul
    endlocal
goto :EOF

:: # #
::  @desc           Finish with error and Exit
:: # #

:forceQuit
	(goto) 2>nul || (
		type nul>nul
		exit /B %~1
	)

:: # #
::  @desc           Progress bar
:: # #

:progressUpdate
    setlocal ENABLEDELAYEDEXPANSION
    set progPercent=%1
    set /A progNumBars=%progPercent%/2
    set /A progNumSpaces=50-%progNumBars%
    set progMeter=
    for /L %%A IN (%progNumBars%,-1,1) do set progMeter=!progMeter!I
    for /L %%A IN (%progNumSpaces%,-1,1) do set progMeter=!progMeter! 
    call :helperUnquote progGitle %2
    title Working:  [%progMeter%]  %progPercent%%% - %progGitle%
    endlocal
goto :EOF

:: # #
::  @desc           Removes quotation marks from strings
:: # #

:helperUnquote
    set %1=%~2
goto :EOF