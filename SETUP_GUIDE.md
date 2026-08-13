# Windows Setup Guide

This file was created because this computer is missing some required tools or PATH entries.

## Environment Check Result

Run from `C:\Users\ADMIN\Downloads\AppTheoDoiCSVC` on 2026-06-10:

| Tool | Command | Result |
| --- | --- | --- |
| Git | `git --version` | Installed: `git version 2.50.0.windows.1` |
| Flutter SDK | `C:\Users\ADMIN\develop\flutter\bin\flutter.bat --version` | Installed, but not on PATH |
| Dart | `C:\Users\ADMIN\develop\flutter\bin\dart.bat --version` | Installed with Flutter, but not on PATH |
| Android Studio | local folder check | Found `C:\Program Files\Android\Android Studio` |
| Android SDK | local folder check | Found `C:\Users\ADMIN\AppData\Local\Android\Sdk` |
| Node.js | `node -v` | Installed: `v24.15.0` |
| npm | `cmd /c npm -v` | Installed: `11.12.1` |
| Firebase CLI | `cmd /c firebase --version` | Missing |
| FlutterFire CLI | `cmd /c flutterfire --version` | Missing |

PowerShell also blocked `npm -v` because script execution is disabled. Use `cmd /c npm -v` or fix the execution policy below.

## 1. Add Flutter SDK to PATH

Flutter is already extracted here:

```text
C:\Users\ADMIN\develop\flutter
```

Add this folder to your user PATH:

```text
C:\Users\ADMIN\develop\flutter\bin
```

Steps:

1. Press `Windows`, search `Environment Variables`.
2. Open `Edit the system environment variables`.
3. Click `Environment Variables`.
4. Under your user variables, select `Path`, then click `Edit`.
5. Add:
   `C:\Users\ADMIN\develop\flutter\bin`
4. Close and reopen PowerShell.
5. Check:
   ```powershell
   flutter --version
   dart --version
   flutter doctor
   ```

## 2. Configure Android Studio and Android SDK

1. Open Android Studio.
2. Go to `More Actions > SDK Manager`.
3. Install:
   - Android SDK Platform 35 or newer
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
4. Go to `More Actions > Virtual Device Manager` and create an Android emulator.
5. Run:
   ```powershell
   flutter doctor
   flutter doctor --android-licenses
   flutter doctor
   ```

Current `flutter doctor` says Android SDK command-line tools are missing. In Android Studio, install:

- `Android SDK Command-line Tools`
- Android SDK Platform 36 or newest stable platform
- Android SDK Build-Tools

## 3. Fix npm in PowerShell

Option A, use Command Prompt style commands:

```powershell
cmd /c npm -v
cmd /c npm install -g firebase-tools
```

Option B, allow local scripts for the current Windows user:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Close and reopen PowerShell, then run:

```powershell
npm -v
```

## 4. Install Firebase CLI

```powershell
cmd /c npm install -g firebase-tools
firebase --version
firebase login
```

## 5. Install FlutterFire CLI

After Flutter is installed:

```powershell
dart pub global activate flutterfire_cli
flutterfire --version
```

If `flutterfire` is still not found, add this folder to PATH:

```text
%LOCALAPPDATA%\Pub\Cache\bin
```

## 6. Commands to Run After Installing Tools

From the app folder:

```powershell
cd C:\Users\ADMIN\Downloads\AppTheoDoiCSVC\facility_report_app
flutter doctor
flutter pub get
flutterfire configure
flutter analyze
flutter run
```
