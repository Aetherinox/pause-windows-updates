@echo       off
title       WPU (Windows Personalization Utility)
goto        comment_end

    This script automatically modifies the registry to disable or enable Windows updates.
    It will also check the standard windows folder where updates are stored, and deletes any
    files or folders within the folder to clean up disk-space. Updates are normally found in:
        c:\windows\softwaredistribution

    Menu List
        menuAdvanced
        menuAppsManage
        menuServicesDebloat
        menuDeleteUser
        menuServicesUpdates
        menuUpdatesCleanFiles
        menuUsersManage
    Task List
        taskAppsInstall
        taskAppsUninstall
        taskCortanaToggle
        taskCrapwareUninstall
        taskDebloatServices
        taskRegistryBackup
        taskTelemetryDisable
        taskUpdatesCleanFiles
        taskUpdatesDisable
        taskUpdatesEnable
        taskUserEnableDisable
        taskUserGetStatus
    Prompt List
        promptAppsInstall
        promptAppsUninstall
    Session List
        sessAdvanced
        sessError
        sessFinish
        sessQuit
    Internal List
        forceQuit
        helperUnquote
        actionProgUpdate

    Windows Packages / Apps
        Powershell:
            @ref                            https://hahndorf.eu/blog/windowsfeatureviacmd

            Install Calculator:             Get-AppxPackage -AllUsers *windowscalculator* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register “$($_.InstallLocation)\AppXManifest.xml”}
            Remove Calculator:              Get-AppxPackage *calculator* | Remove-AppxPackage -AllUsers
            Install Alternative:            Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like "*3dbuilder*"} | Remove-AppxProvisionedPackage -Online
            Uninstall All But MSStore       Get-AppxPackage -AllUsers | Where-Object {$_.name –notlike "*store*"} | Remove-AppxPackage -AllUsers
            List Packages:                  Get-AppxPackage -AllUsers | Select-Object Name, PackageFullName
                                            Get-AppXPackage -AllUsers | Where-Object {$_.InstallLocation -like "*SystemApps*"} | Select-Object Name, PackageFullName
                                            Get-AppXPackage -AllUsers | Where-Object {$_.NonRemovable -eq $False} | Select-Object Name, PackageFullName
                                            Get-AppXPackage -AllUsers | Where-Object {$_.NonRemovable -eq $False} | Select-Object Name, PackageFullName | out-file 'cache.pkg' -encoding utf8
            Search for Package:             Get-AppXPackage -AllUsers | Where-Object {$_.NonRemovable -eq $False} | Select-Object Name, PackageFullName |  findstr /I 549981C3F5F10
                                            Get-AppxPackage -Name *Copilot* | Select-Object Name, InstallLocation, Status | Format-List
            Get Users With App:             (Get-AppxPackage -AllUsers Microsoft.549981C3F5F10).PackageUserInformation | Where-Object {$_.InstallState -eq "Installed"}
            Get Windows Features:           Get-WindowsOptionalFeature -Online
            Get Windows Packages:           Get-WindowsPackage -Online

        Winget:
            Search Installable Packages:    winget search --name copilot
                                            winget search -q 9NHT9RB2F4HD                                           (Copilot)
            Search Installed Packages:      winget list -q "Microsoft.PowerShell"                                   (Powershell 7.x)
            Install Package:                winget install --id 9NHT9RB2F4HD                                        (Copilot)
                                            winget install --id MartiCliment.UniGetUI --silent                      (UniGetUI)
                                            winget install --id MartiCliment.UniGetUI --exact --source winget       (UniGetUI)
            Uninstall Package:              winget uninstall --id 9PJVPMSB6GVH                                      (Interviewer Copilot)
                                            winget uninstall --id MartiCliment.UniGetUI                             (UniGetUI)

        DISM ()
            Get Packages:                   dism /online /get-packages /format:table
            Get Features:                   dism /online /get-features /format:table
            Get Package Info:               dism /online /get-featureinfo /featurename:Recall
            Add Package:                    dism /online /add-package /PackagePath:C:\Cortana
            Disable Package:                dism /online /disable-feature /featurename:Recall
            Enable Package:                 dism /online /enable-Feature /featurename:Recall

:comment_end

:: #
::  @desc           To perform registry edits, we need admin permissions.
::                  Re-launch powershell with admin, and close existing command prompt window
:: #

if not "%1"=="admin" (powershell start -verb runas '%0' admin & exit /b)

net session > nul 2>&1
if %errorlevel% neq 0 (
	echo   %red% Error   %u%         This script requires elevated privileges to run.
	goto :sessError
)

:: #
::  @desc           resize the batch window and adjust the buffer so that text does not get cut off.
:: #

set cols=125
set lines=40
set colsbuff=125
set linesbuff=500

mode con: cols=%cols% lines=%lines%
powershell -command "&{$H=get-host;$W=$H.ui.rawui;$B=$W.buffersize;$B.width=%colsbuff%;$B.height=%linesbuff%;$W.buffersize=$B;}"

:: #
::  @desc           define vars
:: #

:variables
set "dir_home=%~dp0"
set "dir_reg=%dir_home%registryBackup"
set "dir_cache=%dir_home%cache"
set "repo_url=https://github.com/Aetherinox/pause-windows-updates"
set "repo_author=Aetherinox"
set "repo_version=1.5.0"
set "folder_distrb=c:\windows\softwaredistribution"
set "folder_uhssvc=c:\Program Files\Microsoft Update Health Tools"
set "cnt_files=0"
set "cnt_dirs=0"

:: throws extra prints and information
set "appsInitialized=true"
set "noUpdatesState=0x0"
set "AutoUpdate=false"
set "AutoUpdateBool=disabled"
set "AutoUpdateStr=disable"
set "userGuest=Guest"
set "userDefault0=defaultuser0"
set "userGuestState=Enabled"
set "userGuestStateOpp=Disable"
set "osBuild="
set "osCodename="
set "osMajor="
set "osMinor="
set "debugMode=true"

:: colors
set "u=[0m"
set "bold=[1m"
set "under=[4m"
set "inverse=[7m"
set "blink=[5m"
set "cyanl=[96m"
set "cyand=[36m"
set "magental=[95m"
set "magentad=[35m"
set "white=[97m"

:: 256 colors
set "lime=[38;5;154m"
set "brown=[38;5;94m"
set "greenl=[38;5;46m"
set "green=[38;5;40m"
set "greenm=[38;5;42m"
set "greend=[38;5;35m"
set "yellowl=[38;5;226m"
set "yellow=[38;5;220m"
set "bluel=[38;5;45m"
set "blue=[38;5;39m"
set "blued=[38;5;33m"
set "blueb=[38;5;75m"
set "purplel=[38;5;105m"
set "purple=[38;5;99m"
set "fuchsia1=[38;5;1m"
set "fuchsia2=[38;5;162m"
set "peach=[38;5;174m"
set "debug=[38;5;91m"
set "pinkl=[38;5;13m"
set "pink=[38;5;206m"
set "pinkd=[38;5;200m"
set "yellowl=[38;5;228m"
set "yellowm=[38;5;226m"
set "yellowd=[38;5;190m"
set "orangel=[38;5;215m"
set "orange=[38;5;208m"
set "oranged=[38;5;202m"
set "goldl=[38;5;220m"
set "goldm=[38;5;178m"
set "goldd=[38;5;214m"
set "grayb=[38;5;250m"
set "greyl=[38;5;247m"
set "graym=[38;5;244m"
set "grayd=[38;5;238m"
set "grayz=[38;5;237m"
set "redl=[91m"
set "red=[38;5;160m"
set "redd=[38;5;124m"
set "redz=[38;5;88m"

:: add spaces so that service names are in columns
set "spaces=                                       "

:: #
::  define services
::      uhssvc                                      Microsoft Update Health Service
::                                                  Maintains Update Health
::                                                  "C:\Program Files\Microsoft Update Health Tools\uhssvc.exe"
::
::      UsoSvc                                      Update Orchestrator Service
::                                                  Manages Windows Updates. If stopped, your devices will not be able to download and install the latest updates.
::                                                  "C:\Windows\system32\svchost.exe -k netsvcs -p"
::
::      WaaSMedicSvc                                Windows Update Medic Service
::                                                  "C:\Windows\system32\svchost.exe -k wusvcs -p"
::
::      wuauserv                                    Windows Update Service
::                                                  Enables the detection, download, and installation of updates for Windows and other programs. If this service is disabled, users of this computer will not be able to use Windows Update or its automatic updating feature, and programs will not be able to use the Windows Update Agent (WUA) API.
::                                                  "C:\Windows\system32\svchost.exe -k netsvcs -p"
::
::      DiagTrack                                   Connected User Experiences and Telemetry
::      dmwappushservice                            Device Management Wireless Application Protocol (WAP) Push message Routing Service
::      diagsvc                                     Diagnostic Execution Service
::      diagnosticshub.standardcollector.service    Microsoft (R) Diagnostics Hub Standard Collector Service
:: #

:: Windows Update Services
set "servicesUpdates[uhssvc]=Microsoft Update Health Service|uhssvc"
set "servicesUpdates[UsoSvc]=Update Orchestrator Service|UsoSvc"
set "servicesUpdates[WaaSMedicSvc]=Windows Update Medic Service|WaaSMedicSvc"
set "servicesUpdates[wuauserv]=Windows Update Service|WaaSMedicSvc"

:: Windows Telemetry Services
set "servicesTelemetry[DiagTrack]=Connected User Experiences and Telemetry|DiagTrack"
set "servicesTelemetry[dmwappushservice]=Device Management Wireless Application|dmwappushservice"
set "servicesTelemetry[diagsvc]=Diagnostic Execution Service|diagsvc"
set "servicesTelemetry[diagnosticshub.standardcollector.service]=Microsoft (R) Diagnostics Hub|diagnosticshub.standardcollector.service"

:: Windows Services > Debloat
set "servicesUseless[01]=Microsoft Diagnostics Hub Collector|diagnosticshub.standardcollector.service"
set "servicesUseless[02]=Connected User Experiences & Telemetry|DiagTrack"
set "servicesUseless[03]=Device Management WAP Push Message|dmwappushservice"
set "servicesUseless[04]=Geolocation|lfsvc"
set "servicesUseless[05]=Downloaded Maps Manager|MapsBroker"
set "servicesUseless[06]=Net.Tcp Port Sharing|NetTcpPortSharing"
set "servicesUseless[07]=Routing & Remote Access|RemoteAccess"
set "servicesUseless[08]=Remote Registry|RemoteRegistry"
set "servicesUseless[09]=Internet Connection Sharing|SharedAccess"
set "servicesUseless[10]=Distributed Link Tracking Client|TrkWks"
set "servicesUseless[11]=Windows Biometric|WbioSrvc"
set "servicesUseless[12]=Windows Media Player Network Sharing|WMPNetworkSvc"
set "servicesUseless[13]=Xbox Live Auth Manager|XblAuthManager"
set "servicesUseless[14]=Xbox Live Game Save Save|XblGameSave"
set "servicesUseless[15]=Xbox Live Networking|XboxNetApiSvc"
set "servicesUseless[16]=Windows Network Data Usage Monitoring|ndu"

:: Disable Users
set "usersDisable[2]=Guest|guest"
set "usersDisable[3]=Administrator|Administrator"
set "usersDisable[4]=Default Account|DefaultAccount"

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
set schtasksDisable[16]=\Microsoft\Office\OfficeTelemetryAgentFallBack
set schtasksDisable[17]=\Microsoft\Office\OfficeTelemetryAgentLogOn

:: Crapware
set crapwareIndexMax=40
set crapware[0]=Microsoft.Getstarted
set crapware[1]=Microsoft.XboxGamingOverlay
set crapware[2]=Microsoft.XboxGameOverlay
set crapware[3]=Microsoft.XboxIdentityProvider
set crapware[4]=Microsoft.XboxSpeechToTextOverlay
set crapware[5]=microsoft.windowscommunicationsapps
set crapware[6]=Microsoft.People
set crapware[7]=Microsoft.Messaging
set crapware[8]=Microsoft.GamingApp
set crapware[9]=Microsoft.ZuneMusic
set crapware[10]=Microsoft.ZuneVideo
set crapware[11]=Microsoft.549981C3F5F10
set crapware[12]=Clipchamp.Clipchamp
set crapware[13]=Microsoft.SkypeApp
set crapware[14]=Microsoft.Advertising.Xaml
set crapware[15]=Microsoft.Getstarted
set crapware[16]=Microsoft.Todos
set crapware[17]=Microsoft.GetHelp
set crapware[18]=MicrosoftTeams
set crapware[19]=Microsoft.BingSearch
set crapware[20]=Microsoft.BingHealthAndFitness
set crapware[21]=Microsoft.BingFoodAndDrink
set crapware[22]=Microsoft.WindowsFeedback
set crapware[23]=Microsoft.BingTranslator
set crapware[24]=Microsoft.BingTravel
set crapware[25]=Microsoft.News
set crapware[26]=Microsoft.Office.OneNote
set crapware[27]=MSTeams
set crapware[28]=Microsoft.Copilot
set crapware[29]=Microsoft.Microsoft3DViewer
set crapware[30]=Microsoft.Print3D
set crapware[31]=MicrosoftCorporationII.QuickAssist
set crapware[32]=Microsoft.Edge
set crapware[33]=Microsoft.MicrosoftSolitaireCollection
set crapware[34]=Microsoft.BingWeather
set crapware[35]=Microsoft.BingSports
set crapware[36]=Microsoft.BingNews
set crapware[37]=Microsoft.BingFinance
set crapware[38]=Microsoft.XboxApp
set crapware[39]=Microsoft.Xbox.TCUI
set crapware[39]=Microsoft.3dbuilder
set crapware[40]=Microsoft.WindowsAlarms
set crapware[41]=Microsoft.YourPhone

:: #
::  @desc           registry
::                  list of registry classes for backing up the registry
:: #

set "registry[1]=HKLM|hklm.reg"
set "registry[2]=HKCU|hkcu.reg"
set "registry[3]=HKCR|hkcr.reg"
set "registry[4]=HKU|hku.reg"
set "registry[5]=HKCC|hkcc.reg"

:: #
::  @desc           manageable packages
::                  list of packages which can be added/removed
:: #

set "apps[01]=7zip|7zip.7zip|winget"
set "apps[02]=Bitwarden|Bitwarden.Bitwarden|winget"
set "apps[03]=Cyberduck|Iterate.Cyberduck|winget"
set "apps[04]=DuckDuckGo Browser|DuckDuckGo.DesktopBrowser|winget"
set "apps[05]=GNU Privacy Guard (GPG)|GnuPG.GnuPG|winget"
set "apps[06]=Google Chrome|Google.Chrome.EXE|winget"
set "apps[07]=jq|jqlang.jq|winget"
set "apps[08]=Microsoft .NET SDK 6.0.427 (x64)|Microsoft.DotNet.SDK.6|winget"
set "apps[09]=Microsoft AppInstaller|Microsoft.AppInstaller|winget"
set "apps[10]=Microsoft DevHome|Microsoft.DevHome|winget"
set "apps[11]=Microsoft Edge|Microsoft.Edge|winget"
set "apps[12]=Microsoft IronPython|Microsoft.IronPython.3|winget"
set "apps[13]=Microsoft OneDrive|Microsoft.OneDrive|winget"
set "apps[14]=Microsoft OpenSSH|Microsoft.OpenSSH.Preview|winget"
set "apps[15]=Microsoft Powershell|Microsoft.PowerShell|winget"
set "apps[16]=Microsoft Powertoys|Microsoft.PowerToys|winget"
set "apps[17]=Microsoft Visual C++ 2005 Redistributable (x32)|Microsoft.VCRedist.2005.x86|winget"
set "apps[18]=Microsoft Visual C++ 2005 Redistributable (x64)|Microsoft.VCRedist.2005.x64|winget"
set "apps[19]=Microsoft Visual C++ 2008 Redistributable (x32)|Microsoft.VCRedist.2008.x86|winget"
set "apps[20]=Microsoft Visual C++ 2008 Redistributable (x64)|Microsoft.VCRedist.2008.x64|winget"
set "apps[21]=Microsoft Visual C++ 2010 Redistributable (x32)|Microsoft.VCRedist.2010.x86|winget"
set "apps[22]=Microsoft Visual C++ 2010 Redistributable (x64)|Microsoft.VCRedist.2010.x64|winget"
set "apps[23]=Microsoft Visual C++ 2012 Redistributable (x32)|Microsoft.VCRedist.2012.x86|winget"
set "apps[24]=Microsoft Visual C++ 2012 Redistributable (x64)|Microsoft.VCRedist.2012.x64|winget"
set "apps[25]=Microsoft Visual C++ 2013 Redistributable (x32)|Microsoft.VCRedist.2013.x86|winget"
set "apps[26]=Microsoft Visual C++ 2013 Redistributable (x64)|Microsoft.VCRedist.2013.x64|winget"
set "apps[27]=Microsoft Visual C++ 2015 UWP Desktop Runtime|Microsoft.VCLibs.Desktop.14|winget"
set "apps[28]=Microsoft Visual C++ 2015-2022 Redistributable (x32)|Microsoft.VCRedist.2015+.x32|winget"
set "apps[29]=Microsoft Visual C++ 2015-2022 Redistributable (x64)|Microsoft.VCRedist.2015+.x64|winget"
set "apps[30]=Microsoft Visual Studio Code|Microsoft.VisualStudioCode|winget"
set "apps[31]=Microsoft Visual Studio Code Insiders|Microsoft.VisualStudioCode.Insiders|winget"
set "apps[32]=Mozilla Firefox|Mozilla.Firefox|winget"
set "apps[33]=NMap|Insecure.Nmap|winget"
set "apps[34]=Opera Browser (Stable)|Opera.Opera|winget"
set "apps[35]=Opera GX Browser (Stable)|Opera.OperaGX|winget"
set "apps[36]=PeaZip|Giorgiotani.Peazip|winget"
set "apps[37]=Tor Browser|TorProject.TorBrowser|winget"
set "apps[38]=Windows Calculator|windowscalculator|powershell"
set "apps[39]=Windows Terminal|Microsoft.WindowsTerminal|winget"
set "apps[40]=WinRAR|RARLab.WinRAR|winget"
set "apps[41]=UnigetUI (WinGetUI)|MartiCliment.UniGetUI|winget"

:: #
::  @desc           define os ver and name
::                  get information about the device operating system
:: #

for /f "usebackq tokens=1,2 delims==|" %%I in (`wmic os get osarchitecture^,name^,version /format:list`) do 2> nul set "%%I=%%J"
for /f "UseBackQ Tokens=1-4" %%A In ( `powershell "$OS=GWmi Win32_OperatingSystem;$UP=(Get-Date)-"^
    "($OS.ConvertToDateTime($OS.LastBootUpTime));$DO='d='+$UP.Days+"^
    "' h='+$UP.Hours+' n='+$UP.Minutes+' s='+$UP.Seconds;Echo $DO"`) do (
        set "%%A"&set "%%B"&set "%%C"&set "%%D"
)

:: #
::  @desc           get version display name (codename)
::  @output         osCodename      24H2
:: #

set "osCodename="
FOR /F "tokens=2* skip=2" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "DisplayVersion"') do (
    set "osCodename=%%b"
)

:: #
::  @desc           get build number from ver command
::  @output         osMajor         10
::                  osMinor         0
::                  osBuild         22631
:: #

for /f "tokens=4-6 delims=. " %%a in ('ver') do (
    set "osMajor=%%a"
    set "osMinor=%%b"
    set "osBuild=%%c"
)

:: #
::  @desc           get build number from registry as an alternative source
::  @output         osBuildBackup   26100
:: #

set "osBuildBackup="
FOR /F "tokens=2* skip=2" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "CurrentBuildNumber"') do (
    set "osBuildBackup=%%b"
)

:: #
::  @desc           in the off chance that we get a nul os build value, assign the backup
::  @output         osBuild         26100
:: #

IF "%osBuild%" == "" (
    echo   %blue% Status   %u%        Assigning backup value to os build%u%
    set "osBuild=%osBuildBackup%"
)

:: #
::  @desc           build numbers dont match, use the most probable
:: #

if "%osBuild%" neq "%osBuildBackup%" (
    echo:
    echo:
    echo   %red% Error   %u%        There are inconsistencies in your operating system build number. Because some features heavily
    echo   %red%         %u%        rely on this build number, we will use the most probable value.
    echo:
    echo   %red%         %u%        This is usually caused by manipulation of the registry windows updates which failed
    echo   %red%         %u%        to install properly.
    echo:
    echo   %red%         %u%        %goldm%Press any key to continue ...%u%
    echo:
    pause > nul
) else (
    echo   %blue% Status   %u%        Identified os build %goldm%%osBuild%%u%
)

:: #
::  @desc           os is older than windows 10; abort
:: #

if %osMajor% lss 10 (
    echo:
    echo:
    echo   %red% Error   %u%        This utility is only for Windows 10 and 11 users. You are using a version older than the
    echo   %red%         %u%        requirement allows. Utility will now abort.
    echo:
    pause > nul
    goto :EOF
)

:: #
::  @desc           since its important to get the version and build display name right; add some redundancy.
::                  we dont need to go any further back than Windows 10 since all others are discontinued
:: #

set "osCodenameBackup="
if %osBuild% geq 26100 (
    set "osCodenameBackup=24H2"
    set "osName=11"
) else if %osBuild% geq 22631 (
    set "osCodenameBackup=23H2"
    set "osName=11"
) else if %osBuild% geq 22621 (
    set "osCodenameBackup=22H2"
    set "osName=11"
) else if %osBuild% geq 22000 (
    set "osCodenameBackup=21H2"
    set "osName=11"
) else if %osBuild% geq 19044 (
    set "osCodenameBackup=21H2"
    set "osName=10"
) else if %osBuild% geq 19043 (
    set "osCodenameBackup=21H1"
    set "osName=10"
) else if %osBuild% geq 19042 (
    set "osCodenameBackup=20H2"
    set "osName=10"
) else if %osBuild% geq 19041 (
    set "osCodenameBackup=2004"
    set "osName=10"
) else if %osBuild% geq 18363 (
    set "osCodenameBackup=1909"
    set "osName=10"
) else if %osBuild% geq 18362 (
    set "osCodenameBackup=1903"
    set "osName=10"
) else if %osBuild% geq 17763 (
    set "osCodenameBackup=1809"
    set "osName=10"
) else if %osBuild% geq 17134 (
    set "osCodenameBackup=1803"
    set "osName=10"
) else if %osBuild% geq 16299 (
    set "osCodenameBackup=1709"
    set "osName=10"
) else if %osBuild% geq 15063 (
    set "osCodenameBackup=1703"
    set "osName=10"
) else if %osBuild% geq 14393 (
    set "osCodenameBackup=1607"
    set "osName=10"
) else if %osBuild% geq 10586 (
    set "osCodenameBackup=1511"
    set "osName=10"
) else if %osBuild% geq 10240 (
    set "osCodenameBackup=FE"
    set "osName=10"
) else (
    set "osCodenameBackup=NA"
    set "osName=NA"
)

IF "%osCodename%" == "" (
    echo   %blue% Status   %u%        Assigning backup codename %goldm%%osCodenameBackup%%u%
    set "osCodename=%osCodenameBackup%"
)

echo   %blue% Status   %u%        Identified os codename %goldm%%osCodename%%u%%u%

:: #
::  @desc           Main
::                  Main initial inteface
:: #

:main
    setlocal enabledelayedexpansion
    title WPU (Windows Personalization Utility)

    :: #
    ::  @desc           Check user registry to see if automatic updates are currently enabled or disabled
    ::                  registry will return the following for auto update status
    ::                      0x0         updates are enabled
    :                       0x1         updates are disabled
    :: #

    for /F "usebackq tokens=3*" %%A in (`REG QUERY "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate`) do (
        set "noUpdatesState=%%A"
    )

    if /i "%noUpdatesState%" == "0x0" (
        set "AutoUpdate=true"
        set "AutoUpdateBool=%greenm%enabled%u%"
        set "AutoUpdateStr=%greenm%!AutoUpdateBool:~0,-1!%u%"
    ) else (
        set "AutoUpdate=false"
        set "AutoUpdateBool=%orange%disabled%u%"
        set "AutoUpdateStr=%orange%!AutoUpdateBool:~0,-1!%u%"
    )

    set q_mnu_main=
    set q_mnu_adv=

    chcp 65001 > nul
    cls
    echo:
    echo:
    echo      %goldm%v%repo_version%%u%                              %grayd%Windows Personalization Utility%u%
    echo:
    echo  %fuchsia2%    ██╗    ██╗██████╗ ██╗   ██╗████████╗██╗██╗     ██╗████████╗██╗   ██╗
    echo      ██║    ██║██╔══██╗██║   ██║╚══██╔══╝██║██║     ██║╚══██╔══╝╚██╗ ██╔╝
    echo      ██║ █╗ ██║██████╔╝██║   ██║   ██║   ██║██║     ██║   ██║    ╚████╔╝ 
    echo      ██║███╗██║██╔═══╝ ██║   ██║   ██║   ██║██║     ██║   ██║     ╚██╔╝  
    echo      ╚███╔███╔╝██║     ╚██████╔╝   ██║   ██║███████╗██║   ██║      ██║   
    echo       ╚══╝╚══╝ ╚═╝      ╚═════╝    ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   
    echo:
    echo:
    echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
    echo    %cyand% Author  %grayb%       %repo_author%%u%
    echo    %cyand% Repo    %grayb%       %repo_url%
    echo    %cyand% OS      %grayb%       %osCodename% (%version%) %graym%%name% %osarchitecture%%u%
    echo    %cyand% Uptime  %grayb%       %d% %graym%days%u% %h% %graym%hours%u% %n% %graym%minutes%u% %s% %graym%seconds
    echo    %cyand% Status  %grayb%       Windows Updates %AutoUpdateBool%%u%
    echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
    echo:
    if /I "%AutoUpdate%" equ "true" (
        echo     %goldm%^(1^)%u%   Disable Updates
        echo     %grayd%^(2^)%grayd%   Enable Updates
    ) else (
        echo     %grayd%^(1^)%grayd%   Disable Updates
        echo     %goldm%^(2^)%u%   Enable Updates
    )
    echo:
    echo     %goldm%^(3^)%u%   Backup Registry
    echo     %goldm%^(4^)%u%   Remove Update Files
    echo     %goldm%^(5^)%u%   Manage Update Services
    echo     %goldm%^(6^)%u%   Scan and Repair
    echo:
    echo     %goldm%^(C^)%u%   Customize ^(Tweaks^)
    echo     %goldm%^(D^)%u%   Debloat ^(Advanced^)
    echo:
    echo     %greenm%^(H^)%greenm%   Help
    echo     %blueb%^(S^)%blueb%   Supporters
    echo     %redl%^(Q^)%redl%   Quit
    echo:
    echo:
    set /p q_mnu_main="%goldm%    Pick Option » %u%"
    echo:

    :: #
    ::  @desc           Menu > Help
    ::                  Shows help menu
    :: #

    if /I "!q_mnu_main!" equ "H" (

        cls

        echo:
        echo:
        echo %u%    This utility allows you to do the following tasks:
        echo:

        if /I "%AutoUpdate%" equ "true" (
            echo       %goldm%^(1^)%greenm%   Disable Updates%u%
        ) else (
            echo       %grayd%^(1^)%greend%   Disable Updates%u% %goldd%[Already disabled]%u%
        )
        echo             %grayd%Disable Windows automatic updates. Updates will be halted until re-enabled.
        echo             %grayd%All pending update files on your device will be deleted to clean up disk-space.
        echo             %grayd%Files will be re-downloaded if you enable Windows updates at a later time.
        echo:

        if /I "%AutoUpdate%" equ "true" (
            echo       %grayd%^(2^)%greend%   Enable Updates%u% %goldd%[Already enabled]%u%
        ) else (
            echo       %goldm%^(2^)%greenm%   Enable Updates%u%
        )
        echo             %grayd%Enable windows updates on your system.
        echo:
        echo       %goldm%^(3^)%greenm%   Backup Registry%u%
        echo             %grayd%Create a backup of your registry
        echo:
        echo       %goldm%^(4^)%greenm%   Remove Update Files%u%
        echo             %grayd%Pending update files on your device will be deleted to clean up disk-space.
        echo             %grayd%This task is automatically performed if you select option 1%u%
        echo:
        echo       %goldm%^(5^)%greenm%   Manage Update Services%u%
        echo             %grayd%This option allows you to view Windows Update's current status, as well as 
        echo             %grayd%enable or disable Windows Update system services.
        echo             %grayd%This task is automatically performed if you select option 1%u%
        echo:
        echo       %goldm%^(6^)%greenm%   Scan and Repair%u%
        echo             %grayd%Run system-wide scans which can detect errors related to your operating
        echo             %grayd%system. Any detected errors may be fixed on the spot with little interaction
        echo             %grayd%on the users end%u%
        echo:
        echo       %goldm%^(C^)%greenm%   Customize ^(Tweaks^)%u%
        echo             %grayd%Change the way Windows behaves on-the-fly.
        echo:
        echo       %goldm%^(D^)%greenm%   Debloat ^(Advanced^)%u%
        echo             %grayd%Uninstall unwanted apps/bloat such as Copilot, Cortana, and Recall.
        echo             %grayd%Manage system users. Manage and shut down bloat Windows services.
        echo:
        echo       %goldm%^(S^)%greenm%   Supporters%u%
        echo             %grayd%A list of people who have donated to this project.
        echo:
        echo       %redl%^(R^)%redl%   Return
        echo:
        echo:
        set /p q_mnu_main="%goldm%    Pick Option » %u%"
        echo:
    )

    :: #
    ::  @desc           Menu > Sponsors
    ::                  Shows a list of sponsors
    :: #

    if /I "!q_mnu_main!" equ "S" (

        cls

        echo:
        echo:
        echo %u%    If you wish to support this project, you may drop a donation at %goldd%https://buymeacoffee.com/aetherinox.
        echo %u%    To have your name added, donate and leave a comment which gives us your Github username.
        echo:
        echo %u%    A special thanks to the following for donating:
        echo:
        echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
        echo:
        echo       %greenm%   Chad May%u%
        echo:
        echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
        echo:
        echo   %cyand% Notice  %u%        Press any key to return

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

    :: option > (3) Backup Registry
    if /I "%q_mnu_main%" equ "3" (
        goto :taskRegistryBackup
    )

    :: option > (4) Clean windows update dist folder
    if /I "%q_mnu_main%" equ "4" (
        goto :menuUpdatesCleanFiles
    )

    :: option > (5) Manage Update Services
    if /I "%q_mnu_main%" equ "5" (
        goto :menuServicesUpdates
    )

    :: option > (6) Scan and Fix Errors
    if /I "%q_mnu_main%" equ "6" (
        goto :menuScanFix
    )

    :: option > (C) Customize / Tweaks / Mods
    if /I "!q_mnu_main!" equ "C" (
        goto :menuCustomize
    )

    :: option > (D) Debloat / Advanced
    if /I "!q_mnu_main!" equ "D" (
        goto :menuAdvanced
    )

    :: option > (Q) Quit
    if /I "%q_mnu_main%" equ "Q" (
        goto :sessQuit
    ) else (
        echo   %red% Error   %u%         Unrecognized Option %yellowl%%q_mnu_main%%u%
        pause > nul

        goto :main
    )

    endlocal
goto :EOF

:: #
::  @desc           Menu > Install Apps
::                  allows us to install / uninstall applications; list of apps dynamically generated
::
::                  set "apps[index]=name|package"
::                      Index ............. %%~v
::                      Name .............. %%~w
::                      Package ........... %%~x
:: #

:menuAppsManage
    setlocal enabledelayedexpansion
    cls

    set q_mnu_install=
    set appStatus=Install

    echo:
    if "!appsInitialized!" == "true" (
        echo   %blue% Status   %u%        Please wait while we determine what apps are installed.
        
        if not exist "%dir_cache%" (
            md "%dir_cache%"
        )

        winget list > "%dir_cache%\%~n0.out" 2>&1
    )

    if exist "%dir_cache%\%~n0.out" (
        echo   %blue% Status   %u%        Found cache %orange%%dir_cache%\%~n0.out %u%
    ) else (
        echo   %red% Error   %u%         Could not open app cache %orange%%dir_cache%\%~n0.out%u%, press return and try again.
        pause > nul

        set "appsInitialized=true"
        goto :menuAppsManage
    )

    echo:

    for /f "tokens=2-4* delims=[]|=" %%v in ('set apps[ 2^>nul') do (
        findstr /I "%%~x" "%dir_cache%\%~n0.out" >nul
        if errorlevel 1 (
            set appStatus=%greenl%Install%u%
        ) else (
            set appStatus=%redl%Uninstall%u%
        )
        echo     %yellowd%^(%%~v^)%u%   !appStatus! %%~w
    ) 

    echo:
    echo     %redl%^(R^)%redl%    Return
    echo:
    echo:
    set /p q_mnu_install="%goldm%    Pick Option » %u%"
    echo:

    :: #
    ::  Apps > generate list of selectable options
    :: #

    for /f "tokens=2-4* delims=[]|=" %%v in ('set apps[ 2^>nul') do (
        if /I "%q_mnu_install%" equ "%%~v" (

            set "pkgManager=%%~y"
            set appStatus=Install
            findstr /I "%%~x" "%dir_cache%\%~n0.out" >nul
            if errorlevel 1 (
                set appStatus=Install
            ) else (
                set appStatus=Uninstall
            )

            echo:
            echo   %purplel% Status  %u%        Starting !appStatus! - %green%%%~w %grayd%^(%%~x^)%u% using !pkgManager!%u%

            if /I "!appStatus!"=="Install" call :promptAppsInstall "!pkgManager!" "%%~x"
            if /I "!appStatus!"=="Uninstall" call :promptAppsUninstall "!pkgManager!" "%%~x"
            set "appsInitialized=true"

            goto :menuAppsManage
        )
    ) 

    :: option > (R) Return
    if /I "%q_mnu_install%" equ "R" (
        del "%dir_cache%\%~n0.out" /f > nul 2>&1
        set "appsInitialized=true"
        goto :menuAdvanced
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_install%%u%, press any key and try again.
        pause > nul

        set "appsInitialized=false"
        goto :menuAppsManage
    )

    endlocal
goto :EOF

:: #
::  @desc           Menu > Debloat > Services
::
::                  set "apps[index]=name|package"
::                      Index ............. %%~v
::                      Name .............. %%~w
::                      Package ........... %%~x
:: #

:menuServicesDebloat
    setlocal enabledelayedexpansion
    cls

    set q_mnu_serv=

    echo:
    echo %greyl%    The services controlled from this menu are extra services on Microsoft Windows which most users
    echo %greyl%    deem as unnecessary. These services are not required for normal everyday operation.
    echo:
    echo %greyl%    You can disable all services grouped in this category at once, or re-enable them.
    echo:
    echo %greyl%    Some services require a system reboot after being disabled. Some services may automatically stop
    echo %greyl%    once started; this happens with on-demand services that do not need to run all of the time.
    echo:
    echo     %yellowd%^(1^)%u%   View Service Status
    echo     %yellowd%^(2^)%u%   Enable All Bloat Services
    echo     %yellowd%^(3^)%u%   Disable All Bloat Services
    echo:
    echo:

    for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUseless[ 2^>nul') do (
        for /F "tokens=3 delims=: " %%H in ('sc query "%%~x" ^| findstr "        STATE"') do (
            set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
            set "service=!service:~0,60!"
            if /I "%%H" neq "RUNNING" (
                set appStatus=%greenl%Enable%u%
            ) else (
                set appStatus=%redl%Disable%u%
            )
        )

        echo    %yellowd%^(%%~v^)%u%   !appStatus! %%~w %pink%[%%~x]%u%
    )

    echo:
    echo     %redl%^(R^)%redl%   Return
    echo:
    echo:
    set /p q_mnu_serv="%goldm%    Pick Option » %u%"
    echo:
    echo:

    :: option > (1) View Debloat Service Status
    if /I "%q_mnu_serv%" equ "1" (

        echo   %cyand% Notice  %u%        Getting Service Status%u%

        :: loop services and check status
        for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUseless[ 2^>nul') do (
            for /F "tokens=3 delims=: " %%H in ('sc query "%%~x" ^| findstr "        STATE"') do (
                set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
                set "service=!service:~0,60!"
                if /I "%%H" neq "RUNNING" (
                    echo   %cyand%         %grayd%          !service! %redl%Not Running%u%
                ) else (
                    echo   %cyand%         %grayd%          !service! %greenl%Running%u%
                )
            )
        ) 

        echo   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul

        goto :menuServicesDebloat
    )

    :: option > (2) Enable Debloated Services
    if /I "%q_mnu_serv%" equ "2" (
        echo   %cyand% Notice  %u%        Re-enabling Debloat Windows Services ...

        for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUseless[ 2^>nul') do (
            set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
            set "service=!service:~0,60!"

            echo   %cyand%         %grayd%          !service! %greenl%enabled%u%
            sc config %%~x start= auto > nul 2>&1
            net start %%~x > nul 2>&1
        ) 

        echo   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul
    
        goto :menuServicesDebloat
    )

    :: option > (3) Disable Debloated Services
    if /I "%q_mnu_serv%" equ "3" (
        echo   %cyand% Notice  %u%        Debloated Windows Services ...

        for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUseless[ 2^>nul') do (
            set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
            set "service=!service:~0,60!"

            echo   %cyand%         %grayd%          !service! %redl%disabled%u%
            net stop %%~x > nul 2>&1
            sc config %%~x start= disabled > nul 2>&1
            sc failure %%~x reset= 0 actions= "" > nul 2>&1
        ) 

        echo   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul
    
        goto :menuServicesDebloat
    )

    :: #
    ::  Apps > generate list of selectable options; enable / disable each service
    :: #

    for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUseless[ 2^>nul') do (
        if /I "%q_mnu_serv%" equ "%%~v" (

            set servStatus=Enable
            for /F "tokens=3 delims=: " %%H in ('sc query "%%~x" ^| findstr "        STATE"') do (
                set "service=%grayd%%%~w %pink%[%%~x]!%u%"
                if /I "%%H" neq "RUNNING" (
                    set servStatus=Enabled
                    echo   %purplel% Status  %u%        Service %pink%^(%%~x^)%u% is %redl%Not Running%u% - will be %greenl%!servStatus!%u%
                    sc config %%~x start= auto > nul 2>&1
                    net start %%~x > nul 2>&1
                    echo   %greenl% Success %u%        Service !service! %greenl%!servStatus!%u%
                ) else (
                    set servStatus=Disabled
                    echo   %purplel% Status  %u%        Service %pink%^(%%~x^)%u% is %greenl%Running%u% - will be %redl%!servStatus!%u%
                    net stop %%~x > nul 2>&1
                    sc config %%~x start= disabled > nul 2>&1
                    sc failure %%~x reset= 0 actions= "" > nul 2>&1
                    echo   %greenl% Success %u%        Service !service! %redl%!servStatus!%u%
                )
            )
        
            echo   %cyand% Notice  %u%        Operation complete. Press any key
            pause > nul

            goto :menuServicesDebloat
        )
    ) 

    :: #
    ::  Apps > generate list of selectable options
    :: #

    :: option > (R) Return
    if /I "%q_mnu_serv%" equ "R" (
        del "%dir_cache%\%~n0.out" /f > nul 2>&1
        set "appsInitialized=true"
        goto :menuAdvanced
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_serv%%u%, press any key and try again.
        pause > nul

        set "appsInitialized=false"
        goto :menuServicesDebloat
    )

    endlocal
goto :EOF

:: #
::  @desc           Menu > Manage Users
:: #

:menuUsersManage
    setlocal enabledelayedexpansion
    cls

    set q_mnu_user=

    set "userGuestState=Enabled"
    set "userGuestStateOpp=Disable"

    echo:
    echo %graym%    This section allows you to manage various user accounts within your system.
    echo:
    echo:
    echo     %yellowd%^(1^)%u%   Delete user %blue%!userDefault0!%u%

    for /f "tokens=2-3* delims=[]|=" %%v in ('set usersDisable[ 2^>nul') do (
        call :taskUserGetStatus "%%~w" "%%~x"
        echo     %yellowd%^(%%~v^)%u%   !userGuestStateOpp! user %blue%%%~w%u%
    )

    echo:
    echo     %redl%^(R^)%redl%   Return
    echo:
    echo:
    set /p q_mnu_user="%goldm%    Pick Option » %u%"
    echo:
    echo:

    :: option > (1) Delete defaultuser0
    if /I "%q_mnu_user%" equ "1" (
        call :menuDeleteUser !userDefault0!
        goto :menuUsersManage
    )

    ::  menuUsersManage > Options > Users > Disable
    for /f "tokens=2-3* delims=[]|=" %%v in ('set usersDisable[ 2^>nul') do (
        call :taskUserGetStatus %%~w %%~x
        if /I "%q_mnu_user%" equ "%%~v" (
            call :taskUserEnableDisable "%%~w" "%%~x" !userGuestStateOpp!
            goto :menuUsersManage
        )
    )

    :: option > (R) Return
    if /I "%q_mnu_user%" equ "R" (
        goto :menuAdvanced
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_user%%u%, press any key and try again.
        pause > nul

        goto :menuUsersManage
    )

    endlocal
goto :EOF

:: #
::  @desc           Menu > Users > Get Account Status
::                  returns the active state of a user
:: #

:taskUserGetStatus
    call :helperUnquote userName %1
    call :helperUnquote userId %2

    for /f "tokens=2*" %%a in ('net user "!userId!" 2^>nul ^| findstr /C:"Account active"') do (
        if /I "%%b"=="Yes" (
            set "userGuestState=Enabled"
            set "userGuestStateOpp=Disable"
        ) else (
            set "userGuestState=Disabled"
            set "userGuestStateOpp=Enable"
        )
    )
goto :EOF

:: #
::  @desc           Menu > Users > Delete
::  @ref            https://superuser.com/a/1152800
::                  https://windowsreport.com/anniversary-update-defaultuser0/
::  
::  @arg            str user    "Default Account"
:: #

:menuDeleteUser
    setlocal enabledelayedexpansion
    cls

    call :helperUnquote userId %1

    set q_mnu_user=

    echo:

    If "!userId!"=="!userDefault0!" (
        echo %graym%    The %blue%!userId!%graym% account bug has been haunting Windows users for a long time. Nobody 
        echo %graym%    knows exactly why this account is being created or how users can prevent its creation. The 
        echo %graym%    commonly accepted hypothesis suggests the %blue%!userId!%graym% profile is created when 
        echo %graym%    something goes wrong during the profile creation phase of the main account, and it should 
        echo %graym%    be harmless.
        echo:
        echo %graym%    To read up more on this issue, please visit the links:
        echo %goldm%          https://superuser.com/a/1152800
        echo %goldm%          https://windowsreport.com/anniversary-update-defaultuser0
    ) else (
        echo %graym%    Are you sure you wish to delete the user %blue%!userId!%graym%?
    )
    echo:
    echo:
    echo     %yellowd%^(1^)%u%   Delete user %blue%!userId!%u%
    echo:
    echo     %redl%^(R^)%redl%   Return
    echo:
    echo:
    set /p q_mnu_user="%goldm%    Pick Option » %u%"
    echo:
    echo:

    :: option > (1) Delete Users > Delete DefaultUser0
    if /I "%q_mnu_user%" equ "1" (

        echo   %cyand% Notice  %u%        Deleting user %blue%!userId!%u%

        set "bUserFound=false"
        for /f "tokens=2*" %%a in ('net user !userId! 2^>nul ^| findstr /C:"Account active"') do (
            set "bUserFound=true"
        )

        if /I "!bUserFound!" equ "true" (
            net user !userId! /delete > nul
            echo   %greenl% Success %u%        %redl%Removed%u% user %blue%!userId!%u%
        ) else (
            echo   %red% Error   %u%        Could not find user %blue%!userId!%u%, no user to delete.
        )

        echo   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul

        goto :menuUsersManage
    )

    :: option > (R) Delete Users > Return
    if /I "%q_mnu_user%" equ "R" (
        del "%dir_cache%\%~n0.out" /f > nul 2>&1
        set "appsInitialized=true"
        goto :menuUsersManage
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_user%%u%, press any key and try again.
        pause > nul

        set "appsInitialized=false"
        goto :menuDeleteUser
    )

    endlocal
goto :EOF

:: #
::  @desc           Menu > Users > Disable
::  
::  @arg            str userName    "Default Account"
::  @arg            str userId      "DefaultAccount"
::  @arg            str toState     "Enable" || "Disable"
:: #

:taskUserEnableDisable
    setlocal enabledelayedexpansion
    cls

    call :helperUnquote userName %1
    call :helperUnquote userId %2
    call :helperUnquote toState %3

    set q_mnu_user=

    echo:

    If "!user!"=="!userId!" (
        echo %graym%    The %blue%!userName!%graym% account bug has been haunting Windows users for a long time. Nobody 
        echo %graym%    knows exactly why this account is being created or how users can prevent its creation. The 
        echo %graym%    commonly accepted hypothesis suggests the !userName! profile is created when 
        echo %graym%    something goes wrong during the profile creation phase of the main account, and it should 
        echo %graym%    be harmless.
        echo:
        echo %graym%    To read up more on this issue, please visit the links:
        echo %goldm%          https://superuser.com/a/1152800
        echo %goldm%          https://windowsreport.com/anniversary-update-defaultuser0
    ) else (
        echo %graym%    Are you sure you wish to !toState! the user %blue%!userName!%graym%?
    )
    echo:
    echo:
    echo     %yellowd%^(1^)%u%   !toState! user %blue%!userName!%u%
    echo:
    echo     %redl%^(R^)%redl%   Return
    echo:
    echo:
    set /p q_mnu_user="%goldm%    Pick Option » %u%"
    echo:
    echo:

    :: option > (1) Enable / Disable User
    if /I "%q_mnu_user%" equ "1" (

        echo   %cyand% Notice  %u%        Disabling user %blue%!userName!%u%

        set "bUserFound=false"

        for /f "tokens=2*" %%a in ('net user !userId! ^| findstr /C:"Account active"') do (
            if /I "%%b"=="Yes" (
                echo   %purplel% Status  %u%        User %blue%!userName!%u% currently %greenl%active%u%
                net user !userId! /active:no > nul
                if errorlevel 1 (
                    echo   %red% Error   %u%        Issue occured trying to disable user %blue%!userName!%u%
                ) else (
                    echo   %greenl% Success %u%        %redl%Disabled%u% user %blue%!userName!%u%
                )
            ) else (
                echo   %purplel% Status  %u%        User %blue%!userName!%u% currently %redl%disabled%u%
                net user !userId! /active:yes > nul
                if errorlevel 1 (
                    echo   %red% Error   %u%        Issue occured trying to enable user %blue%!uuserNameser!%u%
                ) else (
                    echo   %greenl% Success %u%        %greenl%Enabled%u% user %blue%!userName!%u%
                )
            )
        )

        echo   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul

        goto :menuUsersManage
    )

    :: #
    ::  defaultuser0 > return
    :: #

    :: option > (R) Return
    if /I "%q_mnu_user%" equ "R" (
        del "%dir_cache%\%~n0.out" /f > nul 2>&1
        set "appsInitialized=true"
        goto :menuUsersManage
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_user%%u%, press any key and try again.
        pause > nul

        set "appsInitialized=false"
        goto :menuDeleteUser
    )

    endlocal
goto :EOF

:: #
::  @desc           Menu > Debloat / Advanced
:: #

:menuAdvanced
    setlocal enabledelayedexpansion
    cls
    title WPU (Windows Personalization Utility) Advanced Options

    :: set states
    set q_mnu_adv=

    echo:
    echo:
    echo     %goldm%^(1^)%u%   Disable Microsoft Telemetry
    echo     %goldm%^(2^)%u%   Manage Cortana, Copilot, Recall
    echo     %goldm%^(3^)%u%   Remove Crapware
    echo     %goldm%^(4^)%u%   Manage Apps
    echo     %goldm%^(5^)%u%   Manage Services
    echo     %goldm%^(6^)%u%   Manage Users
    echo:
    echo     %redl%^(R^)%redl%   Return
    echo:
    echo:
    set /p q_mnu_adv="%goldm%    Pick Option » %u%"
    echo:
    echo:

    :: option > (1) > Debloat > Disable Microsoft Telemetry
    if /I "%q_mnu_adv%" equ "1" (
        goto :taskTelemetryDisable
    )

    :: option > (2) > Debloat > Enable/Disable Cortana
    if /I "%q_mnu_adv%" equ "2" (
        goto :menuServicesAi
    )

    :: option > (3) > Debloat > Remove Crapware
    if /I "%q_mnu_adv%" equ "3" (
        call :taskCrapwareUninstall
        goto :menuAdvanced
    )

    :: option > (4) > Debloat > Manage Apps
    if /I "%q_mnu_adv%" equ "4" (
        goto :menuAppsManage
    )

    :: option > (5) > Debloat > Manage Services
    if /I "%q_mnu_adv%" equ "5" (
        goto :menuServicesDebloat
    )

    :: option > (6) > Debloat > Manage Users
    if /I "%q_mnu_adv%" equ "6" (
        goto :menuUsersManage
    )

    :: option > (R) > Debloat > Return
    if /I "%q_mnu_adv%" equ "R" (
        goto :main
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_adv%%u%, press any key and try again.
        pause > nul

        goto :menuAdvanced
    )

    endlocal
goto :EOF

:: #
::  @desc           Menu > Customize (Tweaks)
:: #

:menuCustomize
    setlocal enabledelayedexpansion
    cls
    title WPU (Windows Personalization Utility) Customization Options

    :: set states
    set q_mnu_cus=

    echo:
    echo:
    echo     %goldm%^(1^)%u%   Coming Soon
    echo:
    echo     %redl%^(R^)%redl%   Return
    echo:
    echo:
    set /p q_mnu_cus="%goldm%    Pick Option » %u%"
    echo:
    echo:

    :: option > (1)
    if /I "%q_mnu_cus%" equ "1" (
        goto :menuCustomize
    )

    :: option > (R) > Debloat > Return
    if /I "%q_mnu_cus%" equ "R" (
        goto :main
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_cus%%u%, press any key and try again.
        pause > nul

        goto :menuCustomize
    )

    endlocal
goto :EOF

:: #
::  @desc           Menu > Services > Scan and Fix Errors
::                  runs sfc and dism resoration
:: #

:menuScanFix
    setlocal enabledelayedexpansion
    cls

    set q_mnu_clean=

    echo:
    echo %graym%    This process will take a few moments to complete. The following actions will be
    echo %graym%    performed on your system:
    echo:
    echo %goldm%          - dism /Online /Cleanup-Image /RestoreHealth
    echo %goldm%          - sfc /scannow
    echo:
    echo:
    echo     %goldm%^(y^)%u%   Start Repair%u%
    echo:
    echo     %redl%^(R^)%redl%   Return
    echo:
    echo:
    set /p q_mnu_clean="%goldm%    Pick Option » %u%"
    echo:
    echo:

    if /I "%q_mnu_clean%" equ "y" (
        echo   %purplel% Status  %u%        Starting command %goldm%dism /Online /Cleanup-Image /RestoreHealth%u%
        dism /Online /Cleanup-Image /RestoreHealth /NoRestart

        echo    Status          Starting command sfc /scannow, please wait
        sfc /scannow

        echo:
        echo:
        echo    Status          Process has been completed. Press any key to continue ...
        echo:
        echo:
        pause > nul

        goto :main
    )

    :: option > (R) > Windows Update Services > Return
    if /I "%q_mnu_clean%" equ "R" (
        goto :main
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_clean%%u%, press any key and try again.
        pause > nul

        goto :menuScanFix
    )
    endlocal
goto :EOF

:: #
::  @desc           Menu > Services > Update
::                  user can control windows update services
:: #

:menuServicesUpdates
    setlocal enabledelayedexpansion
    cls

    set q_mnu_serv=

    echo:
    echo     %yellowd%^(1^)%u%   View Status
    echo     %yellowd%^(2^)%u%   Enable All Update Services
    echo     %yellowd%^(3^)%u%   Disable All Update Services
    echo:
    echo     %redl%^(R^)%redl%   Return
    echo:
    echo:
    set /p q_mnu_serv="%goldm%    Pick Option » %u%"
    echo:
    echo:

    :: option > (1) > Windows Update Services > View Service Status
    if /I "%q_mnu_serv%" equ "1" (

        echo   %cyand% Notice  %u%        Getting Service Status%u%

        :: loop services and check status
        for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUpdates[ 2^>nul') do (
            for /F "tokens=3 delims=: " %%H in ('sc query "%%~x" ^| findstr "        STATE"') do (
                set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
                set "service=!service:~0,60!"
                if /I "%%H" neq "RUNNING" (
                    echo   %cyand%         %grayd%          !service! %redl%Not Running%u%
                ) else (
                    echo   %cyand%         %grayd%          !service! %greenl%Running%u%
                )
            )
        ) 

        echo   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul

        goto :menuServicesUpdates
    )

    :: option > (2) > Windows Update Services > Enable Update Services
    if /I "%q_mnu_serv%" equ "2" (
        echo   %cyand% Notice  %u%        Enabling Windows Update Services ...

        for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUpdates[ 2^>nul') do (
            set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
            set "service=!service:~0,60!"

            echo   %cyand%         %grayd%          !service! %greenl%enabled%u%
            sc config %%~x start= auto > nul 2>&1
            net start %%~x > nul 2>&1
        ) 

        echo   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul
    
        goto :menuServicesUpdates
    )

    :: option > (3) > Windows Update Services > Disable Update Services
    if /I "%q_mnu_serv%" equ "3" (
        echo   %cyand% Notice  %u%        Disabling Windows Update Services ...

        for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUpdates[ 2^>nul') do (
            set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
            set "service=!service:~0,60!"

            echo   %cyand%         %grayd%          !service! %redl%disabled%u%
            net stop %%~x > nul 2>&1
            sc config %%~x start= disabled > nul 2>&1
            sc failure %%~x reset= 0 actions= "" > nul 2>&1
        ) 

        echo   %cyand% Notice  %u%        Operation complete. Press any key
        pause > nul
    
        goto :menuServicesUpdates
    )

    :: option > (R) > Windows Update Services > Return
    if /I "%q_mnu_serv%" equ "R" (
        goto :main
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%%q_mnu_serv%%u%, press any key and try again.
        pause > nul

        goto :menuServicesUpdates
    )
    endlocal
goto :EOF

:: #
::  @desc           Menu > Services > Manage AI
:: #

:menuServicesAi
    setlocal enabledelayedexpansion
    cls

    echo:

    set q_mnu_serv=

    echo   %cyand% Notice  %u%        Checking which apps you currently have installed%u%

    :: generate powershell AppXPackage List
    powershell -c "Get-AppXPackage -AllUsers | Where-Object {$_.NonRemovable -eq $False} | Select-Object Name, PackageFullName | out-file '%dir_cache%\%~n0.pkg' -encoding utf8"

    :: ----------------------------------------------------------------------------------------------------
    :: Get Status > Copilot
    :: run powershell command to get list of apps and send to /cache/ file
    :: must append -encoding utf8 to the powershell out-file; otherwise findstr will not work properly
    :: ----------------------------------------------------------------------------------------------------
    findstr /I "Copilot" "%dir_cache%\%~n0.pkg" >nul
    set "appStatusCopilot=Install"
    if errorlevel 1 (
        set appStatusCopilot=Install
    ) else (
        set appStatusCopilot=Uninstall
    )

    :: ----------------------------------------------------------------------------------------------------
    :: Get Status > Cortana
    :: Get-AppXPackage -AllUsers | Where-Object {$_.NonRemovable -eq $False} | Select-Object Name, PackageFullName | findstr /I "549981C3F5F10"
    :: ----------------------------------------------------------------------------------------------------
    findstr /I "Microsoft.549981C3F5F10" "%dir_cache%\%~n0.pkg" >nul
    set "appStatusCortana=Install"
    set "appStatusCortanaMenu="
    if errorlevel 1 (
        set appStatusCortana=Install
    ) else (
        set appStatusCortana=Uninstall
    )

    if /I "%appStatusCortana%" == "Install" (
        set "appStatusCortanaMenu=%graym%%appStatusCortana% Cortana %redl%^(Discontinued^)%u%"
    ) else (
        set "appStatusCortanaMenu=%appStatusCortana% Cortana%u%"
    )

    :: ----------------------------------------------------------------------------------------------------
    :: Get Status > Recall
    :: ----------------------------------------------------------------------------------------------------
    set "appStatusRecall=Install"
    set "appStatusRecallMenu="
    for /f "tokens=2 delims=: " %%b in ('DISM /Online /Get-FeatureInfo /FeatureName:Recall ^| findstr State') do (
        if /I "%%b" neq "Disabled" (
            set "appStatusRecall=Uninstall"
        )
    )

    if %osBuild% lss 26100 (
        set "appStatusRecallMenu=%graym%%appStatusRecall% Recall %redl%^(Requires 24H2^)%u%"
    ) else (
        set "appStatusRecallMenu=%appStatusRecall% Recall%u%"
    )

    echo:
    echo %graym%    This %blue%AI / Automation%graym% menu allows you to install and uninstall Windows features 
    echo %graym%    that have been deemed to utilize a lot of system resources, invade privacy, or the user
    echo %graym%    generally decides to not want these installed.
    echo:
    echo %graym%    The menu will auto-detect if you already have these features installed. If so, you will
    echo %graym%    be given an uninstall option. If each item in the menu says that you can install it; then
    echo %graym%    you currently do not have the package on your system.
    echo:
    echo %graym%    The options below are very aggressive when it comes to uninstalling. This means that
    echo %graym%    you may see your start menu disappear briefly as this utility restarts processes
    echo %graym%    such as explorer.exe. None of your core system files will be modified.
    echo:

    echo:
    echo     %goldm%^(1^)%u%   %appStatusCopilot% Copilot
    echo     %goldm%^(2^)%u%   %appStatusCortanaMenu%
    echo     %goldm%^(3^)%u%   %appStatusRecallMenu%%u%
    echo:
    echo     %redl%^(R^)%redl%   Return
    echo:
    echo:
    set /p q_mnu_serv="%goldm%    Pick Option » %u%"
    echo:
    echo:

    :: option > (1) > AI > Copilot
    if /I "!q_mnu_serv!" equ "1" (
        echo   %cyand% Notice  %u%        Starting Windows Copilot Wizard%u%

        call :taskCopilotToggle %appStatusCopilot%
        goto :menuServicesAi
    )

    :: option > (2) > AI > Cortana
    if /I "!q_mnu_serv!" equ "2" (
        echo   %cyand% Notice  %u%        Starting Windows Cortana Wizard%u%

        call :taskCortanaToggle %appStatusCortana%
        goto :menuServicesAi
    )

    :: option > (2) > AI > Cortana (Force)
    if /I "!q_mnu_serv!" == "2^!" (
        echo   %cyand% Notice  %u%        Forcing Windows Cortana Wizard to uninstall%u%

        call :taskCortanaToggle uninstall
        goto :menuServicesAi
    )

    :: option > (3) > AI > Recall
    if /I "!q_mnu_serv!" equ "3" (
        echo   %cyand% Notice  %u%        Starting Windows Recall Wizard%u%

        if %osBuild% lss 26100 (
            echo:
            echo   %red% Error   %u%        You are not running a compatible version of Windows and do not require this option.
            echo   %red%         %u%        You must be running at least %goldm%Windows 11 24H2 ^(26100^)%u%
            echo:
            echo   %red%         %u%        %goldm%Press any key to continue ...%u%
            echo:
            pause > nul
        ) else (
            call :taskRecallToggle %appStatusRecall%
            goto :menuServicesAi
        )
    
        goto :menuServicesAi
    )

    :: option > (R) > AI > Return
    if /I "!q_mnu_serv!" equ "R" (
        goto :menuAdvanced
    ) else (
        echo   %red% Error   %u%        Unrecognized Option %yellowl%!q_mnu_serv!%u%, press any key and try again.
        pause > nul

        goto :menuServicesAi
    )
    endlocal
goto :EOF

:: #
::  @desc           Copilot > Toggle
::                  decides whether copilot should be installed or uninstalled
::  
::  @arg            str action    "Enable", "Install" || "Disable", "Uninstall"
:: #

:taskCopilotToggle
    setlocal
    set action=%1
    set actionLabel=!action:~0!ing

    echo   %cyand% Notice  %u%        !actionLabel! Windows Copilot

    If /I "!action!" == "Enable" (
        call :taskCopilotInstall
    ) else if /I "!action!" == "Install" (
        call :taskCopilotInstall
    ) else if /I "!action!" == "Disable" (
        call :taskCopilotUninstall
    ) else if /I "!action!" == "Uninstall" (
        call :taskCopilotUninstall
    ) else (
        echo   %red% Error   %u%        Unknown action %yellowl%!action!%u%; nothing will be done to Windows Copilot
    )

    echo   %cyand% Notice  %u%        Operation complete. Press any key
    pause > nul
    endlocal
goto :EOF

:: #
::  @desc           Copilot > Install
::  @arg            null
:: #

:taskCopilotInstall
    setlocal
        call :taskAppsInstall winget 9NHT9RB2F4HD
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "DeviceHistoryEnabled" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "HistoryViewEnabled" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "AllowSearchToUseLocation" /t REG_DWORD /d "0x00000001" /f > nul
    endlocal
goto :EOF

:: #
::  @desc           Copilot > Uninstall
::  @arg            null
:: #

:taskCopilotUninstall
    setlocal
        call :taskAppsUninstall powershell copilot
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "DeviceHistoryEnabled" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "HistoryViewEnabled" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "AllowSearchToUseLocation" /t REG_DWORD /d "0x00000000" /f > nul
    endlocal
goto :EOF

:: #
::  @desc           Cortana > Toggle
::                  decides whether cortana should be installed or uninstalled
::  
::  @arg            str action    "Enable", "Install" || "Disable", "Uninstall"
:: #

:taskCortanaToggle
    setlocal
    set action=%1
    set actionLabel=!action:~0!ing

    echo   %cyand% Notice  %u%        !actionLabel! Windows Cortana

    If /I "!action!" == "Enable" (
        call :taskCortanaInstall
    ) else if /I "!action!" == "Install" (
        call :taskCortanaInstall
    ) else if /I "!action!" == "Disable" (
        call :taskCortanaUninstall
    ) else if /I "!action!" == "Uninstall" (
        call :taskCortanaUninstall
    ) else (
        echo   %red% Error   %u%        Unknown action %yellowl%!action!%u%; nothing will be done to Windows Cortana
    )

    echo   %cyand% Notice  %u%        Operation complete. Press any key
    pause > nul
    endlocal
goto :EOF

:: #
::  @desc           Cortana > Install
::  @arg            null
:: #

:taskCortanaInstall
    setlocal

        echo:
        echo   %red% Error   %u%        Windows Cortana was discontinued in late 2023 and is not available to install
        echo   %red%         %u%        via the normal methods. You are only able to uninstall Cortana from this utility.
        echo:
        echo   %red%         %u%        Windows Cortana has been replaced by Microsoft Copilot.
        echo:
        echo   %red%         %u%        %goldm%Press any key to continue ...%u%
        echo:
        pause > nul

        goto :menuServicesAi

        :: Cortana replaced by Microsoft Copilot in 2023
        :: nothing below this line will be called anymore
        call :taskAppsInstall powershell Microsoft.549981C3F5F10

        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaEnabled" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d "0x00000001" /f > nul
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t REG_DWORD /d "0x00000001" /f> nul
    endlocal
goto :EOF

:: #
::  @desc           Cortana > Uninstall
::  @arg            null
:: #

:taskCortanaUninstall
    setlocal

        if not exist "C:\Windows\System32\takeown.exe" (
            echo   %red% Error   %u%        Cannot take ownership of path %goldm%"C:\Program Files\WindowsApps"%u% because %goldm%sfc / takeown.exe%u% is missing
        ) else (
            echo   %purplel% Status  %u%        Running %goldm%takedown%u% on folder%goldm% "C:\Program Files\WindowsApps"%u%
            %windir%\System32\takeown.exe /F "C:\Program Files\WindowsApps" /A > nul
        )

        if not exist "C:\Windows\System32\icacls.exe" (
            echo   %red% Error   %u%        Cannot take ownership of path %goldm%"C:\Program Files\WindowsApps"%u% because %goldm%sfc / icacls.exe%u% is missing
        ) else (
            echo   %purplel% Status  %u%        Running %goldm%icacls /remove[:g] %Username%%u% on folder%goldm% "C:\Program Files\WindowsApps" %u%
            %windir%\System32\icacls.exe "C:\Program Files\WindowsApps" /remove[:g] %Username% > nul

            echo   %purplel% Status  %u%        Running %goldm%icacls /grant[:r] %Username%%u% on folder%goldm% "C:\Program Files\WindowsApps" %u%
            %windir%\System32\icacls.exe "C:\Program Files\WindowsApps" /grant[:r] %Username%:"(OI)(CI)F" > nul
        )

        :: *Microsoft.549981C3F5F10*
        :: Get-AppXPackage -AllUsers | Select-Object Name, PackageFullName | findstr /I "Microsoft.549981C3F5F10"
        call :taskAppsUninstall powershell Microsoft.549981C3F5F10
        call :taskAppsUninstall powershell Microsoft.549981C3F5F10_4.2308.1005.0_x64__8wekyb3d8bbwe
        call :taskAppsUninstall winget Microsoft.549981C3F5F10
        call :taskAppsUninstall winget Microsoft.549981C3F5F10_8wekyb3d8bbwe 
        call :taskAppsUninstall winget 9NFFX4SZZ23L

        powershell -command "Get-AppxPackage *Microsoft.549981C3F5F10* | Remove-AppxPackage -AllUsers"
        powershell -command "Get-AppxPackage Microsoft.549981C3F5F10_4.2308.1005.0_x64__8wekyb3d8bbwe | Remove-AppxPackage -AllUsers"

        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortanaAboveLock" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaEnabled" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d "0x00000000" /f > nul
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t REG_DWORD /d "0x00000000" /f> nul
    endlocal
goto :EOF

:: #
::  @desc           Recall > Toggle
::                  decides whether Recall should be installed or uninstalled
::  
::  @arg            str action    "Enable", "Install" || "Disable", "Uninstall"
:: #

:taskRecallToggle
    setlocal
    set action=%1
    set actionLabel=!action:~0!ing

    echo   %cyand% Notice  %u%        !actionLabel! Windows Recall

    If /I "!action!" == "Enable" (
        call :taskRecallInstall
    ) else if /I "!action!" == "Install" (
        call :taskRecallInstall
    ) else if /I "!action!" == "Disable" (
        call :taskRecallUninstall
    ) else if /I "!action!" == "Uninstall" (
        call :taskRecallUninstall
    ) else (
        echo   %red% Error   %u%        Unknown action %yellowl%!action!%u%; nothing will be done to Windows Recall
    )

    echo   %cyand% Notice  %u%        Operation complete. Press any key
    pause > nul
    endlocal
goto :EOF

:: #
::  @desc           Recall > Install
::  @arg            null
:: #

:taskRecallInstall
    setlocal
        dism.exe /online /enable-feature /featurename:Recall /all /norestart >nul 2>&1
        if %errorlevel% neq 0 (
            echo:
            echo   %red% Error   %u%        Windows Recall could not be enabled and this operation will now
            echo   %red%         %u%        abort. Please ensure that you are running Windows 11 24H2.
            echo:
            echo   %red%         %u%        %goldm%Press any key to continue ...%u%
            echo:
            pause > nul

            goto :menuServicesAi
        )

        reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d "0x00000001" /f> nul
        reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d "0x00000000" /f> nul
        reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /t REG_DWORD /d "0x00000000" /f> nul
    endlocal
goto :EOF

:: #
::  @desc           Recall > Uninstall
::  @arg            null
:: #

:taskRecallUninstall
    setlocal
        "%WINDIR%\system32\Dism.exe" /Online /Disable-Feature /FeatureName:Recall /Quiet /Remove /NoRestart
        reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d "0x00000000" /f> nul
        reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d "0x00000001" /f> nul
        reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /t REG_DWORD /d "0x00000001" /f> nul
    endlocal
goto :EOF

:: #
::  @desc           Toggle > App > Install
::                  This func directly installs a package, should not be called directly, call using prompt func promptAppsInstall
::
::  @arg            str manager     "powershell" || "winget"
::  @arg            str package     "Microsoft.Package.Example"
::  @arg            str source      "winget"
:: #

:taskAppsInstall
    setlocal

    call :helperUnquote manager %1
    call :helperUnquote package %2
    call :helperUnquote source %3

    if /I "%manager%" == "powershell" (
        if /I "%debugMode%" equ "true" echo   %debug% Debug   %graym%        Installing app %goldd%%package%%graym% with package manager %goldd%Powershell%u% & echo:
        powershell -command "Get-AppXPackage -AllUsers -Name *%package%* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register ($_.InstallLocation + '\AppXManifest.xml')}"
    ) else if /I "%manager%" == "winget" (
        if /I "%debugMode%" equ "true" echo   %debug% Debug   %graym%        Installing app %goldd%%package%%graym% with package manager %goldd%Winget%u% & echo:

        winget list | findstr /i %package% >nul
        if errorlevel 1 (
            echo   %cyand% Notice  %u%        Package %yellowl%%package%%u% not installed, now installing%u%
            if "%source%" == "" (
                winget install --id %package% --accept-source-agreements --accept-package-agreements --silent
            ) else (
                winget install --id %package% --source %source% --accept-source-agreements --accept-package-agreements --silent
            )
            if errorlevel 1 (
                echo   %red% Error   %u%         Failed to install %yellowl%%package%%u%, you will need to install it manually.
                pause > nul
            ) else (
                echo   %greenl% Success %u%        Installed package %grayd%%package%%u%
                timeout /t 3 > nul
            )
        ) else (
            echo   %cyand% Notice  %u%        Package %yellowl%%package%%u% already installed, skipping
            timeout /t 3 > nul
        )
    )
    endlocal
goto :EOF

:: #
::  @desc           Toggle > App > Uninstall
::                  This func directly uninstalls a package, should not be called directly, call using prompt func taskAppsUninstall
::
::  @arg            str manager    "powershell" || "winget"
::  @arg            str package    "Microsoft.Package.Example"
:: #

:taskAppsUninstall
    setlocal

    call :helperUnquote manager %1
    call :helperUnquote package %2
    call :helperUnquote source %3

    if /i "%manager%" == "powershell" (
        if /I "%debugMode%" equ "true" echo   %debug% Debug   %graym%        Uninstalling app %goldd%%package%%graym% with package manager %goldd%Powershell%u% & echo:
        powershell -command "Get-AppxPackage *%package%* | Remove-AppxPackage -AllUsers"
    ) else if /i "%manager%" == "winget" (
        if /I "%debugMode%" equ "true" echo   %debug% Debug   %graym%        Uninstalling app %goldd%%package%%graym% with package manager %goldd%Winget%u% & echo:

        winget list | findstr /i %package% >nul
        if errorlevel 1 (
            echo   %cyand% Notice  %u%        No package %yellowl%%package%%u% found, skipping%u%
            timeout /t 3 > nul
        ) else (
            echo   %cyand% Notice  %u%        Found package %yellowl%%package%%u%, uninstallling ...
            winget uninstall --id %package%

            if %errorlevel% neq 0 (
                echo   %red% Error   %u%        There was an issue uninstalling %grayd%%package%%u%. Press any key to continue.
                pause > nul
            ) else if %errorlevel% equ 0 (
                echo   %greenl% Success %u%        Uninstalled package %grayd%%package%%u%
                timeout /t 1 > nul
            )
        )
    )

    endlocal
goto :EOF

:: #
::  @desc           Toggle > App > Install Prompt
::                  provides the prompt for installing a new package, does not actually install unless user presses Y
::
::  @arg            str manager    "powershell" || "winget"
::  @arg            str package    "Microsoft.Package.Example"
:: #

:promptAppsInstall
    setlocal

    call :helperUnquote manager %1
    call :helperUnquote package %2
    call :helperUnquote source %3

    echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
    echo:
    echo       %green%^(y^)%green%   Yes     %graym%Install %package%%u%
    echo       %orange%^(n^)%orange%   No      %graym%Do not install %package%%u%
    echo       %redl%^(A^)%redl%   Abort   %graym%Return to main menu%u%
    echo:

    set /p confirm="%goldm%    Install %package%? %graym%(y/n/abort)%goldm% » %u%"
    echo:

    If /I "%confirm%" == "y"    call :taskAppsInstall %manager% %package% %source%
    If /I "%confirm%" == "a"    goto :menuAdvanced

    endlocal
goto :EOF

:: #
::  @desc           Toggle > App > Uninstall Prompt
::                  provides the prompt for uninstalling a package, does not actually uninstall unless user presses Y
::
::  @arg            str manager    "powershell" || "winget"
::  @arg            str package    "Microsoft.Package.Example"
:: #

:promptAppsUninstall
    setlocal

    call :helperUnquote manager %1
    call :helperUnquote package %2
    call :helperUnquote source %3

    echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
    echo:
    echo       %green%^(y^)%green%   Yes     %graym%Uninstall%u%
    echo       %orange%^(n^)%orange%   No      %graym%Keep%u%
    echo       %redl%^(a^)%redl%   Abort   %graym%Return to main menu%u%
    echo:

    set /p confirm="%goldm%    Uninstall %package%? %graym%(y/n/abort)%goldm% » %u%"
    echo:

    If /I "%confirm%" == "y"    call :taskAppsUninstall %manager% %package% %source%
    If /I "%confirm%" == "a"    goto :menuAdvanced

    endlocal
goto :EOF

:: #
::  @desc           Toggle > Uninstall Crapware
::                  gives the user a series of dialog confirmation prompts as to which apps they want to
::                  keep and remove.
::
::                  these are apps that Microsoft includes with Windows that nobody asked for
:: #

:taskCrapwareUninstall
    setlocal

    set crapwareProg=0
    set crapwareNow=1

    set /A crapwareTotal=%crapwareIndexMax%+1
    call :actionProgUpdate 0 "Uninstall Crapware [1/!crapwareTotal!]"

    for /l %%n in (0,1,!crapwareIndexMax!) do (
        set package=!crapware[%%n]!
        set /a crapwareNow+=1
        call :promptAppsUninstall "powershell" "!package!"
        call :actionProgUpdate !crapwareProg! "Uninstall Crapware [!crapwareNow!/!crapwareTotal!]"

        :: stupid workaround for batch not supporting floating points
        If !crapwareNow! gtr 30 (
            set /a crapwareProg+=4
        ) else (
            set /a crapwareProg+=2
        )
    )

    call :actionProgUpdate 100 "Crapware Uninstall Complete"
    echo   %cyand% Notice  %u%        Operation complete. Press any key
    pause > nul
    endlocal
goto :EOF

:: #
::  @desc           Backup Registry
::                  backs up the registry before any major changes are made
:: #

:taskRegistryBackup
    setlocal disabledelayedexpansion

    echo   %purplel% Status  %u%        Starting registry backup, this may take a few moments%u%

    call :actionProgUpdate 10 "Creating new file %dir_reg%"

    if not exist "%dir_reg%" (
        md "%dir_reg%"
    )

    set registryProg=0
    for /f "tokens=2-3* delims=[]|=" %%v in ('set registry[ 2^>nul') do (
        if exist "%dir_reg%\%%~x" (
            erase "%dir_reg%\%%~x"
        )

        echo   %purplel% Status  %u%        Backing up %purplel%%%~w%u% to file %goldm%"%%~x"%u%

        call :actionProgUpdate !registryProg! "Export %%~w from registry to file %%~x"
        reg export HKLM "%dir_reg%\%%~x" > nul
    
        set /a registryProg+=20

        if %errorlevel% neq 0 (
            echo   %red% Error   %u%        Error occurred backing up %grayd%"%dir_reg%\%%~x"%u%
        ) else if %errorlevel% equ 0 (
            setlocal enabledelayedexpansion
            echo   %greenl% Success %u%        %green%(!registryProg!%%^^^)%u% Backed up %grayd%"%dir_reg%\%%~x"%u%
            setlocal disabledelayedexpansion
        )

        call :actionProgUpdate !registryProg! "Completed %%~w"
    ) 

    call :actionProgUpdate 100 "Export Complete"
    echo   %greenl% Success %u%        Registry backuped up to %goldm%"%dir_reg%"%u%

    endlocal
goto :sessFinish

:: #
::  @desc           Start Erase Task
::                  removes any lingering files left over from previous windows update runs
:: #

:menuUpdatesCleanFiles
    setlocal

    echo:
    echo %grayd%   ────────────────────────────────────────────────────────────────────────────────────────────────────────── %u%
    echo:

    echo:
    echo   %cyand% Notice  %u%        %grayl%Scanning %blue%%folder_distrb% %u%

    if exist %folder_distrb%\ (

        for /f %%a in ('dir /s /B /a-d "%folder_distrb%" 2^>nul') do (
            set /A cnt_files+=1
        )

        for /f %%a in ('dir /s /B /ad "%folder_distrb%" 2^>nul') do (
            set /A cnt_dirs+=1
        )

        echo   %u%                 %graym%Files%u%           %yellowl%!cnt_files!%u%
        echo   %u%                 %graym%Folders%u%         %yellowl%!cnt_dirs!%u%
    ) else (
        echo   %cyand% Notice  %u%        Could not find %grayd%%folder_distrb%%u%; nothing to do.
        goto sessFinish
    )

    timeout /t 1 > nul

    echo:
    echo   %goldm% Confirm         %goldm%Would you like to delete the Windows Update distribution files?%u%
    echo   %u%                 Type %greenm%Yes to delete files%u% or %redl%No to return%u%
    echo:

    set /p confirm="%goldm%    Delete files? %graym%(y/n)%goldm% » %u%"

    If /I "%confirm%" == "y" goto taskUpdatesCleanFiles
    If /I "%confirm%" == "yes" goto taskUpdatesCleanFiles

    If /I "%confirm%" == "n" goto main
    If /I "%confirm%" == "no" goto main

    endlocal
goto :EOF

:: #
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
:: #

:taskUpdatesCleanFiles
    setlocal

    if exist %folder_distrb%\ (
        erase /s /f /q %folder_distrb%\*.* && rmdir /s /q %folder_distrb%
    ) else (
        echo   %cyand% Notice  %u%        Windows Updates folder already clean, skipping %grayd%%folder_distrb%%u%
        goto sessFinish
    )

    if %errorlevel% neq 0 (
        echo   %red% Error   %u%        An error has occurred while trying to delete files and folders in %grayd%%folder_distrb%%u%
    ) else if %errorlevel% equ 0 (
        echo   %greenl% Success %u%        No errors reported while deleting files, continuing.
    )

    :: windows update dist folder found
    if exist %folder_distrb%\ (
        echo   %red% Error   %u%        Something went wrong, folder still exists: %grayd%%folder_distrb%%u%

        set cnt_files=0
        set cnt_dirs=0
        for /f %%a in ('dir /s /B /a-d "%folder_distrb%"') do (
            set /A cnt_files+=1
        )

        If not "!cnt_files!"=="0" (
            echo   %red% Error   %u%        Something went wrong, files still exist in %grayd%%folder_distrb%%u%
            echo   %yellowd%                 Try navigating to the folder and manually deleting all files and folders.

            pause > nul
            goto :main
        )

        for /f %%a in ('dir /s /B /ad "%folder_distrb%"') do (
            set /A cnt_dirs+=1
        )

        If not "!cnt_dirs!"=="0" (
            echo   %red% Error   %u%        Something went wrong, folders still exist in %grayd%%folder_distrb%%u%
            echo   %yellowd%                 Try navigating to the folder and manually deleting all files and folders.
        )
    ) else (
        echo   %cyand% Notice  %u%        Validated that all files and folders have been deleted in %grayd% %folder_distrb%%u%
    )

    pause > nul
    goto :main

    endlocal
goto :EOF

:: #
::  @desc           Windows Updates > Disable
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
:: #

:taskUpdatesDisable
    setlocal

    echo   %cyand% Notice  %u%        Disabling Windows Update Services ...%u%

    for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUpdates[ 2^>nul') do (
        set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
        set "service=!service:~0,60!"

        echo   %cyand%         %grayd%          !service! %redl%disabled%u%
        net stop %%~x > nul 2>&1
        sc config %%~x start= disabled > nul 2>&1
        sc failure %%~x reset= 0 actions= "" > nul 2>&1
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

    if %errorlevel% neq 0 (
        echo   %red% Error   %u%         An error occurred trying to edit your registry%u%
        goto sessError
    )

    if %errorlevel% equ 0 (
        echo   %greenl% Success %u%        Registry has been modified, updates are disabled.
    )

    goto taskUpdatesCleanFiles
    endlocal
goto :EOF

:: #
::  @desc           Windows Updates > Enable
:: #

:taskUpdatesEnable
    setlocal
    echo   %cyand% Notice  %u%        Enabling Windows Update Services ...%u%

    for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUpdates[ 2^>nul') do (
        set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
        set "service=!service:~0,60!"

        echo   %cyand%         %grayd%          !service! %greenl%enabled%u%
        sc config %%~x start= auto > nul 2>&1
        net start %%~x > nul 2>&1
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

    if %errorlevel% neq 0 (
        echo   %red% Error   %u%        An error occurred trying to edit your registry%u%
        goto sessError
    )

    if %errorlevel% equ 0 (
        echo   %greenl% Success %u%        Registry has been modified
    )

    goto sessFinish
    endlocal
goto :EOF

:: #
::  @desc           Disables Windows Telemetry Reporting
:: #

:taskTelemetryDisable
    setlocal

    echo   %cyand% Motice  %u%        Disable %goldm%Microsoft Windows%u% telemetry and tracking%u%
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
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "SqmLoggerRunning" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "DisableOptinExperience" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Reliability" /v "SqmLoggerRunning" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Reliability" /v "CEIPEnable" /t REG_DWORD /d "0x00000000" /f > nul
	reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0" /v "NoActiveHelp" /t REG_DWORD /d "0x00000001" /f > nul
	reg add "HKCU\SOFTWARE\Policies\Microsoft\Assistance\Client\1.0" /v "NoExplicitFeedback" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "MicrosoftEdgeDataOptIn" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "LimitEnhancedDiagnosticDataWindowsAnalytics" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowCommercialDataPipeline" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowDeviceNameInTelemetry" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d "0x00000001" /f > nul
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

    if %errorlevel% neq 0 (
        echo   %red% Error   %u%        Error occurred trying to edit your registry%u%
        goto sessError
    )

    echo   %cyand% Motice  %u%        Disable %goldm%Microsoft Office%u% Telemetry Settings
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

    echo   %purplel% Status  %u%        Disable %goldm%Inking / Typing Personalization%u%
    reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection " /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts " /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\Software\Microsoft\Personalization\Settings" /v "AcceptedPrivacyPolicy  " /t REG_DWORD /d "0x00000000" /f > nul

    echo   %purplel% Status  %u%        Disable %goldm%Input  Typing Personalization%u% Telemetry
    reg add "HKCU\Software\Microsoft\Input" /v "IsInputAppPreloadEnabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\Software\Microsoft\Input\Settings" /v "VoiceTypingEnabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\Software\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKCU\Software\Microsoft\Input\Settings" /v "InsightsEnabled" /t REG_DWORD /d "0x00000000" /f > nul

    echo   %purplel% Status  %u%        Disable %goldm%Automatic Cloud%u% Telemetry
    reg add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v "DisableOneSettingsDownloads" /t "REG_DWORD" /d "0x00000001" /f > nul

    echo   %purplel% Status  %u%        Disable %goldm%Windows App%u% Tracking
    reg add "HKCU\Software\Policies\Microsoft\Windows\EdgeUI" /v "DisableMFUTracking" /t "REG_DWORD" /d "0x00000001" /f > nul

    echo   %purplel% Status  %u%        Disable %goldm%Windows Error Reporting%u% Data Collection
    reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t "REG_DWORD" /d "0x00000001" /f > nul
    reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting" /v "ChangeDumpTypeByTelemetryLevel" /t "REG_DWORD" /d "0x00000000" /f > nul
    reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultConsent" /t REG_DWORD /d "0x00000000" /f > nul
    reg add "HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultOverrideBehavior" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d "0x00000001" /f > nul
    reg add "HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting" /v "DoReport" /t REG_DWORD /d "0x00000000" /f > nul

    echo   %purplel% Status  %u%        Erasing %goldm%%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*.etl%u%
	erase "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*.etl" > nul 2>&1
    if %errorlevel% neq 0 (
        echo   %red% Error   %u%        Error occurred deleting the files %redl%%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*.etl%u%
    )

    echo   %purplel% Status  %u%        Erasing %goldm%%ProgramData%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\*.etl%u%
    erase "%ProgramData%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\*.etl" > nul 2>&1
    if %errorlevel% neq 0 (
        echo   %red% Error   %u%        Error occurred deleting the files %redl%%ProgramData%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\*.etl%u%
    )

    echo   %purplel% Status  %u%        Clearing %goldm%Autologger Diagtrack Listener%u%
	echo "" > "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl"

    :: #
    ::  Windows Media Player Usage Telemetry
    :: #

    echo   %purplel% Status  %u%        Disable %goldm%Windows Media Player%u% Telemetry
	reg add "HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences" /v "UsageTracking" /t REG_DWORD /d "0x00000000" /f > nul
    if %errorlevel% neq 0 (
        echo   %red% Error   %u%        Error trying to edit registry entry %redl%HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences\UsageTracking%u%
        goto sessError
    )

    :: #
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
    :: #

    for /l %%n in (0,1,11) do (
        set task=!schtasksDisable[%%n]!
        echo   %purplel% Status  %u%        Disable task %goldm%!task! %u%
	    schtasks /Change /TN "!task!" /DISABLE > nul 2>&1
    )

    :: #
    ::  disable compat telemetry runner
    ::  This process connects to Microsoft's servers to share diagnostics and feedback about how you use Microsoft Windows
    :: #

    echo   %purplel% Status  %u%        Disable process %blue%%windir%\System32\CompatTelRunner.exe %u%
	takeown /F %windir%\System32\CompatTelRunner.exe > nul 2>&1
	icacls %windir%\System32\CompatTelRunner.exe /grant %username%:F > nul 2>&1
	del %windir%\System32\CompatTelRunner.exe /f > nul 2>&1

    :: #
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
    :: #

    for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesTelemetry[ 2^>nul') do (
        set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
        set "service=!service:~0,80!"

        echo   %cyand%         %grayd%          !service! %red%disabled%u%
        net stop %%~x > nul 2>&1
        sc config %%~x start= disabled > nul 2>&1
        sc failure %%~x reset= 0 actions= "" > nul 2>&1
    )

    goto sessFinish
    endlocal
goto :EOF

:: #
::  @desc           Disables Useless Windows Services
:: #

:taskDebloatServices
    setlocal

    echo   %cyand% Motice  %u%        %goldm%Disabling / debloat%u% Windows services%u%

    for /f "tokens=2-3* delims=[]|=" %%v in ('set servicesUseless[ 2^>nul') do (
        set "service=%u%%%~w %pink%[%%~x] !spaces!%u%"
        set "service=!service:~0,80!"

        echo   %cyand%         %grayd%          !service! %red%disabled%u%
        net stop %%~x > nul 2>&1
        sc config %%~x start= disabled > nul 2>&1
        sc failure %%~x reset= 0 actions= "" > nul 2>&1
    )

    goto sessAdvanced
    endlocal
goto :EOF

:: #
::  @desc           Quit
:: #

:sessQuit
    setlocal
    echo   %greenl% Success %u%        Exiting, Press any key to exit%u%
    pause > nul
    endlocal
exit /B 0

:: #
::  @desc           Finish and Exit
:: #

:sessFinish
    setlocal
    echo   %cyand% Notice  %u%        Operation completed, Press any key to return%u%
    pause > nul
    endlocal
goto :main

:: #
::  @desc           Finish and Return to Advanced
:: #

:sessAdvanced
    setlocal
    echo   %cyand% Notice  %u%        Operation completed, Press any key to return%u%
    pause > nul
    endlocal
goto :menuAdvanced

:: #
::  @desc           Finish with error and Exit
:: #

:sessError
    setlocal
    echo   %red% Error   %u%        This utility finished, but with errors. Read the logs above to see the issue.%u%
    pause > nul
    endlocal
goto :EOF

:: #
::  @desc           Finish with error and Exit
:: #

:forceQuit
	(goto) 2>nul || (
		type nul>nul
		exit /B %~1
	)

:: #
::  @desc           Progress bar
:: #

:actionProgUpdate
    setlocal enabledelayedexpansion

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

:: #
::  @desc           Removes quotation marks from strings
:: #

:helperUnquote
    set "%1=%~2"
goto :EOF
