<div align="center">
<h6>No updates until 12-31-2051</h6>
<h1>♾️ Pause Windows Update ♾️</h1>

<br />

<p>A registry tweak and batch utility which allows you to pause Windows updates up until 12-31-2051.</p>

<br />

</div>

<div align="center">

<!-- prettier-ignore-start -->
[![Version][github-version-img]][github-version-uri]
[![Downloads][github-downloads-img]][github-downloads-uri]
[![Size][github-size-img]][github-size-img]
[![Last Commit][github-commit-img]][github-commit-img]
<!-- prettier-ignore-end -->

</div>

<br />

---

<br />

- [About](#about)
  - [Registry Scripts](#registry-scripts)
  - [All-in-one Batch Utility](#all-in-one-batch-utility)
- [Notice](#notice)
- [Install](#install)
- [Re-enabling Updates](#re-enabling-updates)
  - [Option 1 (unpause.reg)](#option-1-unpausereg)
  - [Option 2 (manual)](#option-2-manual)
- [Preview](#preview)
- [Contributors](#contributors)

<br />

---

<br />

## About

This repository provides two different ways to pause windows updates. 

The [All-In-One Batch method](#all-in-one-batch-utility) gives you a few more features that you can pick from in order to disable Windows Updates, as well as disabling Microsoft Telemetry. 

The [Registry Scripts method](#registry-scripts) only allows you to enable or disable windows updates.

<br />

You can pick which one you wish to use from the list below (pick one):

1. [Registry Scripts](#registry-scripts)
     - `windows-updates-pause.reg`
     - `windows-updates-unpause.reg`
2. [All-in-One Batch Utility](#all-in-one-batch-utility)
     - `windows-updates-utility.bat`

<br />

### Registry Scripts

If you decide to go with the **registry** patch, you simply need to download the `.reg` file, and then double-click on the file depending on if you want to pause or unpause windows updates.

<br />

### All-in-one Batch Utility

Simply double-click the batch `.bat` file and you will be presented and numerous options that you can choose from:

1. Enable Windows Updates
2. Disable Windows Updates
3. Disable Windows Telemetry
4. Clean Updates Folder

<br />

> [!NOTE]
> When launching the `.bat` file, you will be asked to allow the utility to have administrative permissions. Unfortunately, this script requires these permissions in order to change registry settings.
>
> If you do not feel comfortable with this, you may opt to use the [Registry Files Method](#registry-scripts) listed above

<br />

---

<br />

## Notice

While this repository allows you to disable Windows Updates, we recommend you manually run Windows Updates every few months to ensure that your system has the latest patches. By completely refusing to install Windows Updates, you may be exposed to potential security vulnerabilities.

This script is meant to stop Windows from updating and then automatically restarting your system when you least expect it, and puts you back in control.

<br />

---

<br />

## Install
This repo contains two files in the [Releases](https://github.com/Aetherinox/Windows-Update-Killer/releases) section. Download the included `.reg` files to your local system.

| Filename | Description |
| --- | --- |
| `windows-updates-pause.reg` | Pauses all updates until 2051 |
| `windows-updates-unpause.reg` | Re-enables windows updates |

<br />

> [!NOTE]
> Depending on your machine's configuration, you may be able to double-click the `.reg` file and auto-install it.

<br />

- Download the `.reg` file to your computer.
- Right click on the file and select `Open With`
  ![](https://github.com/user-attachments/assets/ac56d320-a712-433c-813f-4bbcf7132b84)

- Select `Registry Editor`
- Click `Yes` when prompted if you're sure you wish to continue

<br />

> [!NOTE]
> As of 08/03/2024, you no longer have to view the Windows Update window. Updates are automatically paused as soon as the registry tweak is applied. However, the instructions are still provided below:

<br />

- In Windows, click `Start` -> `Run` -> type `control update` and press ENTER.
  - You can also access the Windows Update window by clicking your start menu, selecting **Run**, and typing:
   ```shell
    ms-settings:windowsupdate
   ```
- Near the `Pause Updates` section, click the dropdown and select how long you want updates to pause for.
- Keep the script somewhere in case you need to reinstall / wipe your machine.

<br />

---

<br />

## Re-enabling Updates
You can re-enable Windows updates by performing one of the following:
- Option 1 - unpause.reg [view](#option-1-unpausereg)
- Option 2 - manual [view](#option-2-manual)

<br />

### Option 1 (unpause.reg)
This repository includes two scripts:
- `windows-updates-pause.reg`
- `windows-updates-unpause.reg`

<br />

Download and run the script `windows-updates-unpause.reg`. Windows updates will be re-activated, but you'll be able to re-pause updates whenever you want and for any duration.

<br />

### Option 2 (manual)
To start Windows updates once again, open your start menu, type `Windows Update Settings`.

<br />

<div align="center">

<img src="https://github.com/user-attachments/assets/71bbb55d-076e-4b52-83b9-cc9bdf7f60df" width="330">

</div>

<br />

At the top of the Windows Update interface, click **Resume Updates**.

<div align="center">

<img src="https://github.com/user-attachments/assets/85310c9b-4117-4cbf-9e2a-2003c93e842c" width="530">

</div>

<br />

To pause updates again, re-run the `.reg` file in this repo.

<br />

---

<br />

## Preview

<div align="center">

<img src="https://github.com/user-attachments/assets/f8c2ef68-cfb1-4428-a07a-88ce314356a5" width="530">

</div>

<br />

## Contributors

![Alt](https://repobeats.axiom.co/api/embed/fec3c11bcd253185c455fdd2bc60c8dc13d3ced8.svg "Repobeats analytics image")

<br />
<br />

<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- BADGE > GENERAL -->
  [general-npmjs-uri]: https://npmjs.com
  [general-nodejs-uri]: https://nodejs.org
  [general-npmtrends-uri]: http://npmtrends.com/windows-update-killer

<!-- BADGE > VERSION > GITHUB -->
  [github-version-img]: https://img.shields.io/github/v/tag/Aetherinox/Windows-Update-Killer?logo=GitHub&label=Version&color=ba5225
  [github-version-uri]: https://github.com/Aetherinox/Windows-Update-Killer/releases

<!-- BADGE > VERSION > NPMJS -->
  [npm-version-img]: https://img.shields.io/npm/v/windows-update-killer?logo=npm&label=Version&color=ba5225
  [npm-version-uri]: https://npmjs.com/package/windows-update-killer

<!-- BADGE > VERSION > PYPI -->
  [pypi-version-img]: https://img.shields.io/pypi/v/windows-update-killer-plugin
  [pypi-version-uri]: https://pypi.org/project/windows-update-killer-plugin/

<!-- BADGE > LICENSE > MIT -->
  [license-mit-img]: https://img.shields.io/badge/MIT-FFF?logo=creativecommons&logoColor=FFFFFF&label=License&color=9d29a0
  [license-mit-uri]: https://github.com/Aetherinox/Windows-Update-Killer/blob/main/LICENSE

<!-- BADGE > GITHUB > DOWNLOAD COUNT -->
  [github-downloads-img]: https://img.shields.io/github/downloads/Aetherinox/Windows-Update-Killer/total?logo=github&logoColor=FFFFFF&label=Downloads&color=376892
  [github-downloads-uri]: https://github.com/Aetherinox/Windows-Update-Killer/releases

<!-- BADGE > NPMJS > DOWNLOAD COUNT -->
  [npmjs-downloads-img]: https://img.shields.io/npm/dw/%40aetherinox%2Fmkdocs-link-embeds?logo=npm&&label=Downloads&color=376892
  [npmjs-downloads-uri]: https://npmjs.com/package/windows-update-killer

<!-- BADGE > GITHUB > DOWNLOAD SIZE -->
  [github-size-img]: https://img.shields.io/github/repo-size/Aetherinox/Windows-Update-Killer?logo=github&label=Size&color=59702a
  [github-size-uri]: https://github.com/Aetherinox/Windows-Update-Killer/releases

<!-- BADGE > NPMJS > DOWNLOAD SIZE -->
  [npmjs-size-img]: https://img.shields.io/npm/unpacked-size/windows-update-killer/latest?logo=npm&label=Size&color=59702a
  [npmjs-size-uri]: https://npmjs.com/package/windows-update-killer

<!-- BADGE > CODECOV > COVERAGE -->
  [codecov-coverage-img]: https://img.shields.io/codecov/c/github/Aetherinox/Windows-Update-Killer?token=MPAVASGIOG&logo=codecov&logoColor=FFFFFF&label=Coverage&color=354b9e
  [codecov-coverage-uri]: https://codecov.io/github/Aetherinox/Windows-Update-Killer

<!-- BADGE > ALL CONTRIBUTORS -->
  [contribs-all-img]: https://img.shields.io/github/all-contributors/Aetherinox/Windows-Update-Killer?logo=contributorcovenant&color=de1f6f&label=contributors
  [contribs-all-uri]: https://github.com/all-contributors/all-contributors

<!-- BADGE > GITHUB > BUILD > NPM -->
  [github-build-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/Windows-Update-Killer/npm-release.yml?logo=github&logoColor=FFFFFF&label=Build&color=%23278b30
  [github-build-uri]: https://github.com/Aetherinox/Windows-Update-Killer/actions/workflows/npm-release.yml

<!-- BADGE > GITHUB > BUILD > Pypi -->
  [github-build-pypi-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/Windows-Update-Killer/release-pypi.yml?logo=github&logoColor=FFFFFF&label=Build&color=%23278b30
  [github-build-pypi-uri]: https://github.com/Aetherinox/Windows-Update-Killer/actions/workflows/pypi-release.yml

<!-- BADGE > GITHUB > TESTS -->
  [github-tests-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/Windows-Update-Killer/npm-tests.yml?logo=github&label=Tests&color=2c6488
  [github-tests-uri]: https://github.com/Aetherinox/Windows-Update-Killer/actions/workflows/npm-tests.yml

<!-- BADGE > GITHUB > COMMIT -->
  [github-commit-img]: https://img.shields.io/github/last-commit/Aetherinox/Windows-Update-Killer?logo=conventionalcommits&logoColor=FFFFFF&label=Last%20Commit&color=313131
  [github-commit-uri]: https://github.com/Aetherinox/Windows-Update-Killer/commits/main/

<!-- prettier-ignore-end -->
<!-- markdownlint-restore -->
