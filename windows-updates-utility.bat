@ECHO       OFF
TITLE       Windows Updates Utility
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

:: # #
::  @desc           define vars
:: # #

:variables
set dir_home=%~dp0
set repo_url=https://github.com/Aetherinox/pause-windows-updates
set repo_author=Aetherinox
set repo_version=1.2.0
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
set yellow=[33m
set purple=[35m
set cyan=[96m
set crimson=[91m
set red=[31m
set green=[92m
set blue=[94m
set bluel=[36m
set pink=[95m
set yellowl=[93m
set orange=[38;5;214m
set lime=[38;5;154m
set gray=[90m
set brown=[38;5;94m
set white=[37m

:: add spaces so that service names are in columns
set "spaces=                                       "

:: # #
::  define services
::      uhssvc              Microsoft Update Health Service
::      UsoSvc              Update Orchestrator Service
::      WaaSMedicSvc        Windows Update Medic Service
::      wuauserv            Windows Update Service
:: # #

set lstServices=uhssvc UsoSvc WaaSMedicSvc wuauserv

:: convert service to name for easier identification
set x[uhssvc]=Microsoft Update Health Service
set x[UsoSvc]=Update Orchestrator Service
set x[WaaSMedicSvc]=WaaSMedicSvc
set x[wuauserv]=Windows Update

:: # #
::  @desc           Main
:: # #

:main

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
        set AutoUpdateBool=%green%enabled%u%
        set AutoUpdateStr=%green%!AutoUpdateBool:~0,-1!%u%

    ) else (
        set AutoUpdate=false
        set AutoUpdateBool=%orange%disabled%u%
        set AutoUpdateStr=%orange%!AutoUpdateBool:~0,-1!%u%
    )

    chcp 65001 >nul
    cls
    echo.
    echo.
    echo.
    echo.
    echo.     %bluel%v%repo_version%%u%
    echo.
    echo  %crimson%    ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗███████╗    ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗
    echo      ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔════╝    ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
    echo      ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║███████╗    ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  %u%
    echo  %crimson%    ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║╚════██║    ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝
    echo      ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝███████║    ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗
    echo       ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚══════╝     ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝ %u%
    echo.
    echo %u%                                                Developed by %repo_author%
    echo %u%                                  %gray%%repo_url%
    echo.
    echo %gray%   ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
    echo.

    set q_mnu_main=
    set q_mnu_adv=

    echo.

    echo.   %bluel% Notice  %u%        Windows Updates are currently %AutoUpdateBool%%u%
    echo.   %gray%                 The option to %AutoUpdateStr%%gray% updates again is greyed out, however%u%
    echo.   %gray%                 it can be selected to re-apply the edits again%u%
    echo.

    if /I "%AutoUpdate%" EQU "true" (
        echo       %yellow%^(1^)%u%   Disable Updates
        echo       %gray%^(2^)%gray%   Enable Updates
    ) else (
        echo       %gray%^(1^)%gray%   Disable Updates
        echo       %yellow%^(2^)%u%   Enable Updates
    )

    echo.

    echo       %yellow%^(3^)%u%   Disable Microsoft Telemetry
    echo       %yellow%^(4^)%u%   Remove Update Files
    echo       %yellow%^(5^)%u%   Manage Update Services
    echo.
    echo       %green%^(H^)%green%   Help
    echo       %crimson%^(Q^)%crimson%   Quit

    echo.
    set /p q_mnu_main="%yellow%    Pick Option » %u%"
    echo.

    :: # #
    ::  @desc           Menu > Help
    :: # #

    if /I "!q_mnu_main!" EQU "H" (

        cls

        echo.
        echo %u%  This script allows you to do the following tasks:
        echo.

        if /I "%AutoUpdate%" EQU "true" (
            echo       %yellow%^(1^)%u%   Disable Updates
        ) else (
            echo       %gray%^(1^)%gray%   Disable Updates - %orange%Already disabled
        )
        echo             %gray%Completely disable Windows automatic updates. Once toggled, updates will be
        echo             %gray%halted until you re-enable them.
        echo.
        echo             %gray%All pending update files on your device will be deleted to clean up disk-space.
        echo             %gray%You will have to re-download the files if you re-enable Windows updates later.

        echo.

        if /I "%AutoUpdate%" EQU "true" (
            echo       %gray%^(2^)%gray%   Enable Updates - %orange%Already enabled
        ) else (
            echo       %yellow%^(2^)%u%   Enable Updates
        )
        echo             %gray%Enables windows updates on your system. After this point, your system will begin
        echo             %gray%checking for new updates and they will be installed as normal.

        echo.

        echo       %yellow%^(3^)%u%   Disable Microsoft Telemetry
        echo             %gray%Disables the ability for Microsoft to receive telemetry data from your device.

        echo.

        echo       %yellow%^(4^)%u%   Remove Update Files
        echo             %gray%All pending update files on your device will be deleted to clean up disk-space.
        echo             %gray%You will have to re-download the files if you re-enable Windows updates later.

        echo.
        echo             %gray%This task is automatically performed if you disable Windows Updates from this
        echo             %gray%utility using %yellow%Option 1%u%

        echo.

        echo       %yellow%^(5^)%u%   Manage Update Services
        echo             %gray%This option allows you to view Windows Update's current status, as well as 
        echo             %gray%enable or disable Windows Update system services.
        echo.
        echo             %gray%This task is automatically performed if you disable Windows Updates from this
        echo             %gray%utility using %yellow%Option 1%u%

        echo.

        echo       %crimson%^(R^)%crimson%   Return
    
        echo.
        set /p q_mnu_main="%yellow%    Pick Option » %u%"
        echo.
    )

    if /I "!q_mnu_main!" EQU "R" (
        cls
        goto :main
    )

    :: option > (1) Disable Updates

    if /I "%q_mnu_main%" EQU "1" (
        goto :taskUpdatesDisable
    )

    :: option > (2) Enable Updates

    if /I "%q_mnu_main%" EQU "2" (
        goto :taskUpdatesEnable
    )

    :: option > (3) Disable Telemetry

    if /I "%q_mnu_main%" EQU "3" (
        goto :taskDisableTelemetry
    )

    :: option > (4) Clean windows update dist folder

    if /I "%q_mnu_main%" EQU "4" (
        goto :taskFilesErase
    )

    :: option > (5) Manage Update Services

    if /I "%q_mnu_main%" EQU "5" (
        goto :menuServices
    )

    :: option > (Q) Quit

    if /I "%q_mnu_main%" EQU "Q" (
        goto :sessQuit
    ) else (
        echo.   %red% Error   %u%         Unrecognized Option %yellowl%%q_mnu_main%%u%

        goto :main
    )

:: # #
::  @desc           Menu > Services
:: # #

:menuServices
    cls
    set q_mnu_serv=

    echo.

    echo       %yellow%^(1^)%u%   View Status
    echo       %yellow%^(2^)%u%   Enable Update Services
    echo       %yellow%^(3^)%u%   Disable Update Services
    echo.
    echo       %crimson%^(R^)%crimson%   Return

    echo.
    set /p q_mnu_serv="%yellow%    Pick Option » %u%"
    echo.

    echo.

    :: option > (1) View Service Status
    if /I "%q_mnu_serv%" EQU "1" (

        echo.   %bluel% Notice  %u%        Getting Service Status%u%

        :: loop services and check status
        for %%i in (%lstServices%) do (
            set y=!x[%%i]!
            for /F "tokens=3 delims=: " %%H in ('sc query "%%i" ^| findstr "        STATE"') do (
                set "service=!y! %pink%[%%i] !spaces!"
                set "service=!service:~0,50!"
                if /I "%%H" NEQ "RUNNING" (
                    echo.   %bluel%         %gray%          !service! %red%Not Running%u%
                ) else (
                    echo.   %bluel%         %gray%          !service! %green%Running%u%
                )
            )
        )

        echo.   %bluel% Notice  %u%        Operation complete. Press any key
        pause >nul

        goto :menuServices
    )

    :: option > (2) Enable Update Services
    if /I "%q_mnu_serv%" EQU "2" (
        echo.   %bluel% Notice  %u%        Enabling Windows Update Services ...

        for %%i in (%lstServices%) do (
            set y=!x[%%i]!
            set "service=!y! %pink%[%%i] !spaces!"
            set "service=!service:~0,50!"

            echo.   %bluel%         %gray%          !service! %green%enabled%u%
            sc config %%i start= auto >nul 2>&1
            net start %%i >nul 2>&1
        )

        echo.   %bluel% Notice  %u%        Operation complete. Press any key
        pause >nul
    
        goto :menuServices
    )

    :: option > (3) Disable Update Services
    if /I "%q_mnu_serv%" EQU "3" (
        echo.   %bluel% Notice  %u%        Disabling Windows Update Services ...

        for %%i in (%lstServices%) do (
            set y=!x[%%i]!
            set "service=!y! %pink%[%%i] !spaces!"
            set "service=!service:~0,50!"

            echo.   %bluel%         %gray%          !service! %red%disabled%u%
            net stop %%i >nul 2>&1
            sc config %%i start= disabled >nul 2>&1
            sc failure %%i reset= 0 actions= "" >nul 2>&1
        )

        echo.   %bluel% Notice  %u%        Operation complete. Press any key
        pause >nul
    
        goto :menuServices
    )

    :: option > (R) Return
    if /I "%q_mnu_serv%" EQU "R" (
        goto :main
    ) else (
        echo.   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_serv%%u%, press any key and try again.
        pause >nul

        goto :menuServices
    )

:: # #
::  @desc           Start
:: # #

:taskStart

    echo.
    echo.   %bluel% Notice  %u%        %gray% Scanning        %yellowl% %folder_distrb% %u%

    if exist %folder_distrb%\ (

        for /f %%a in ('dir /s /B /a-d "%folder_distrb%"')  DO (
            set /A cnt_files+=1
        )

        for /f %%a in ('dir /s /B /ad "%folder_distrb%"')  DO (
            set /A cnt_dirs+=1
        )

        echo.   %u%                 %gray% Files%u%           %yellowl% !cnt_files! %u%
        echo.   %u%                 %gray% Folders%u%         %yellowl% !cnt_dirs! %u%

    ) else (
        echo.   %bluel% Notice  %u%        Could not find %gray% %folder_distrb%%u%; nothing to do.
        goto sessFinish
    )

    timeout /t 1 >nul
    echo.

    echo.   %gray% Confirm %yellow%        Would you like to delete the Windows Update distribution files?%u%
    echo.   %u%                  Type %green%Yes to continue%u% or %red%No to return%u%
    echo.
    set /p confirm="%u%                     Delete windows update files? » %u%"

    if /I "%confirm%"=="Yes"   goto taskStart
    if /I "%confirm%"=="yes" goto taskStart
    if /I "%confirm%"=="No"   goto sessFinish
    if /I "%confirm%"=="no"  goto sessFinish

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
        echo.   %bluel% Notice  %u%        Windows Updates folder already clean, skipping %gray% %folder_distrb%%u%
        goto sessFinish
    )

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        An error has occurred while trying to delete files and folders in %gray%%folder_distrb%%u%
    )

    if %errorlevel% EQU 0 (
        echo.   %green% Success %u%        No errors reported while deleting files, continuing.
    )

    :: windows update dist folder found

    if exist %folder_distrb%\ (
        echo.   %red% Error   %u%         Something went wrong, folder still exists: %gray%%folder_distrb%%u%

        set cnt_files=0
        set cnt_dirs=0
        for /f %%a in ('dir /s /B /a-d "%folder_distrb%"')  DO (
            set /A cnt_files+=1
        )

        If NOT "!cnt_files!"=="0" (
            echo.   %red% Error   %u%         Something went wrong, files still exist in %gray%%folder_distrb%%u%
            echo.   %yellow%                  Try navigating to the folder and manually deleting all files and folders.
            goto sessError
        )

        for /f %%a in ('dir /s /B /ad "%folder_distrb%"')  DO (
            set /A cnt_dirs+=1
        )

        If NOT "!cnt_dirs!"=="0" (
            echo.   %red% Error   %u%        Something went wrong, folders still exist in %gray%%folder_distrb%%u%
            echo.   %yellow%                 Try navigating to the folder and manually deleting all files and folders.
            goto sessError
        )

        :: just here as a catch-all for issues
        goto sessError
    ) else (
        echo.   %bluel% Notice  %u%        Validated that all files and folders have been deleted in %gray% %folder_distrb%%u%
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
    echo.   %bluel% Notice  %u%        Disabling Windows Update Services ...%u%
    for %%i in (%lstServices%) do (
        set y=!x[%%i]!
        set "service=!y! %pink%[%%i] !spaces!"
        set "service=!service:~0,50!"

        echo.   %bluel%         %gray%          !service! %red%disabled%u%
        net stop %%i >nul 2>&1
        sc config %%i start= disabled >nul 2>&1
        sc failure %%i reset= 0 actions= "" >nul 2>&1
    )

    :: Windows Update > Dates
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesStartTime" /t REG_SZ /d "2025-01-01T00:00:00Z" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesEndTime" /t REG_SZ /d "2051-12-31T00:00:00Z" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesStartTime" /t REG_SZ /d "2025-01-01T00:00:00Z" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesEndTime" /t REG_SZ /d "2051-12-31T00:00:00Z" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesStartTime" /t REG_SZ /d "2025-01-01T00:00:00Z" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesExpiryTime" /t REG_SZ /d "2051-12-31T00:00:00Z" /f >nul
    reg add "HKLM\Software\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursStart" /t REG_DWORD /d "0x0000000d" /f >nul
    reg add "HKLM\Software\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursEnd" /t REG_DWORD /d "0x00000007" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "FlightSettingsMaxPauseDays" /t REG_DWORD /d "0x00002727" /f >nul

    :: Services\WaaSMedicSvc / disable windows update service
    ::      0 = Boot  '1 = System  '2 = Automatic  3 = Manual  4 = Disabled
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "0x00000004" /f >nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "FailureActions" /t REG_BINARY /d 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 /f >nul

    :: WindowsUpdate\AU
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d "0x00000001" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUShutdownOption" /t REG_DWORD /d "0x00000001" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AlwaysAutoRebootAtScheduledTime" /t REG_DWORD /d "0x00000000" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d "0x00000001" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d "0x00000000" /f >nul

    :: UpdatePolicy\Settings
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureStatus" /t REG_DWORD /d "0x00000001" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityStatus" /t REG_DWORD /d "0x00000001" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityDate" /t REG_SZ /d "2025-01-01T00:00:00Z" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureDate" /t REG_SZ /d "2025-01-01T00:00:00Z" /f >nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%         An error occurred trying to edit your registry%u%
        goto sessError
    )

    if %errorlevel% EQU 0 (
        echo.   %green% Success %u%        Registry has been modified, updates are disabled.
    )

    goto taskFilesErase

:: # #
::  @desc           Enables Windows Updates
:: # #

:taskUpdatesEnable
    echo.   %bluel% Notice  %u%        Enabling Windows Update Services ...%u%

    for %%i in (%lstServices%) do (
        set y=!x[%%i]!
        set "service=!y! %pink%[%%i] !spaces!"
        set "service=!service:~0,50!"

        echo.   %bluel%         %gray%          !service! %green%enabled%u%
        sc config %%i start= auto >nul 2>&1
        net start %%i >nul 2>&1
    )

    :: Windows Update > Dates
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesStartTime" /t REG_SZ /d "" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesEndTime" /t REG_SZ /d "" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesStartTime" /t REG_SZ /d "" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesEndTime" /t REG_SZ /d "" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesStartTime" /t REG_SZ /d "" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesExpiryTime" /t REG_SZ /d "" /f >nul
    reg add "HKLM\Software\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursStart" /t REG_DWORD /d "0x0000000d" /f >nul
    reg add "HKLM\Software\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursEnd" /t REG_DWORD /d "0x00000007" /f >nul
    reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "FlightSettingsMaxPauseDays" /t REG_DWORD /d "0x00002727" /f >nul

    :: Services\WaaSMedicSvc / enables windows update service
    ::      0 = Boot  '1 = System  '2 = Automatic  3 = Manual  4 = Disabled
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d "00000003" /f >nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "FailureActions" /t REG_BINARY /d "840300000000000000000000030000001400000001000000c0d4010001000000e09304000000000000000000" /f >nul

    :: WindowsUpdate\AU
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d "0x00000000" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUShutdownOption" /t REG_DWORD /d "0x00000000" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AlwaysAutoRebootAtScheduledTime" /t REG_DWORD /d "0x00000000" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d "0x00000001" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /t REG_DWORD /d "0x00000001" /f >nul

    :: UpdatePolicy\Settings
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureStatus" /t REG_DWORD /d "0x00000000" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityStatus" /t REG_DWORD /d "0x00000000" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityDate" /t REG_SZ /d "" /f >nul
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureDate" /t REG_SZ /d "" /f >nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        An error occurred trying to edit your registry%u%
        goto sessError
    )

    if %errorlevel% EQU 0 (
        echo.   %green% Success %u%        Registry has been modified, updates are enabled.
    )

    goto sessFinish

:: # #
::  @desc           Disables Windows Telemetry Reporting
:: # #

:taskDisableTelemetry
    echo.   %bluel% Motice  %u%        Disabling telemetry%u%
    reg add "HKLM\SYSTEM\ControlSet001\Services\DiagTrack" /v "Start" /t REG_DWORD /d "0x00000004" /f >nul
    reg add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0x00000000" /f >nul
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0x00000000" /f >nul
    reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d "0x00000000" /f >nul

    if %errorlevel% NEQ 0 (
        echo.   %red% Error   %u%        An error occurred trying to edit your registry%u%
        goto sessError
    )

    if %errorlevel% EQU 0 (
        echo.   %green% Success %u%        Registry has been modified, telemetry has been disabled.
    )

    goto sessFinish

:: # #
::  @desc           Quit
:: # #

:sessQuit
    echo.   %green% Success %u%        Exiting, Press any key to exit%u%
    pause >nul
    Exit /B 0

:: # #
::  @desc           Finish and Exit
:: # #

:sessFinish
    echo.   %bluel% Notice  %u%        Operation completed, Press any key to return%u%
    pause >nul
    goto :main

:: # #
::  @desc           Finish with error and Exit
:: # #

:sessError
    echo.   %red% Error   %u%        This script finished, but with errors. Read the logs above to see the issue.%u%
    pause >nul
    Exit /B 0
