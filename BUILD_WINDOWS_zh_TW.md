# Windows x64 編譯指南（繁體中文）

適用於 `fat-so/Sandboxie` fork、Intel／AMD x64 Windows，以及 Visual Studio 2022。本指南涵蓋核心、Plus 介面與執行目錄的建置。ARM64 需使用不同的架構設定與 Qt 套件，請參考 [CI 流程](.github/workflows/main.yml)。

## 1. 安裝必要工具

安裝 Visual Studio 2022 Community、Professional 或 Enterprise。在 Visual Studio Installer 中選擇「使用 C++ 的桌面開發」，並確認安裝下列個別元件：

- MSVC v143 的 x64／x86 C++ 建置工具。
- C++ MFC 的 x64／x86 元件，供 Classic 核心解決方案中的應用程式使用。
- Windows Driver Kit 的 Visual Studio 整合元件。
- MSVC v142 建置工具，以及 Windows 10 SDK `10.0.19041.0`，供 SbieShell 使用。

另外安裝：

- 支援 VS 2022 的 Windows SDK 與 Windows Driver Kit（WDK）。從 [Microsoft 支援版本表](https://learn.microsoft.com/en-us/windows-hardware/drivers/other-wdk-downloads) 選擇 VS 2022 對應的一組 SDK／WDK；兩者的 build number 必須相同。版本配對規則見 [WDK 安裝說明](https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk#kit-versioning)。SbieShell 所需的 `19041` SDK 可與核心建置使用的 SDK 並存。
- Git for Windows，並將 Git 加入 PATH。
- 7-Zip，安裝於 `C:\Program Files\7-Zip`。

Qt 與 Jom 會由專案腳本下載。Qt、OpenSSL 等版本由 [Installer/buildVariables.cmd](Installer/buildVariables.cmd) 決定，無須自行改寫版本號。

`qmake_plus.cmd` 與 `copy_build.cmd` 會透過 [Installer/setup_vs.cmd](Installer/setup_vs.cmd) 與 Visual Studio Installer 的 `vswhere.exe` 自動尋找 VS 2022，支援不同版本與自訂安裝目錄，不需要手動將 Enterprise 路徑改成 Community。查找方式參考 [Microsoft vswhere 文件](https://github.com/microsoft/vswhere/wiki/Find-VC)。

## 2. 下載或更新原始碼

開啟開始功能表中的 **Developer Command Prompt for VS 2022**。本指南的指令為 CMD 語法。

首次下載時執行：

```bat
if not exist C:\src mkdir C:\src
cd /d C:\src
git clone https://github.com/fat-so/Sandboxie.git
cd Sandboxie
git log -1 --oneline
```

若已下載至 `C:\src\Sandboxie`，確認工作區沒有未處理的修改後更新：

```bat
cd /d C:\src\Sandboxie
git status --short
git pull --ff-only origin master
```

下列步驟以 `C:\src\Sandboxie` 為專案根目錄。若使用其他路徑，請調整 `cd` 指令；現有下載與建置腳本包含未加引號的路徑，請使用不含空白的目錄。

## 3. 確認建置環境

```bat
cd /d C:\src\Sandboxie
call Installer\setup_vs.cmd x64
where cl
where msbuild
"C:\Program Files\7-Zip\7z.exe" i
```

上述指令應能找到編譯器、MSBuild 與 7-Zip。以下建置指令請逐行執行；若某一步出現錯誤，先修正該步驟，再繼續下一步。

## 4. 編譯核心與驅動

先建置 Win32 DLL／服務元件，再建置 x64 核心與驅動，順序與 CI 相同：

```bat
cd /d C:\src\Sandboxie
msbuild Sandboxie\SandboxDll.sln /t:Build /p:Configuration=SbieRelease /p:Platform=Win32 /m:8
msbuild Sandboxie\Sandbox.sln /t:Build /p:Configuration=SbieRelease /p:Platform=x64 /m:8
msbuild Sandboxie\SandboxDrv.sln /t:Build /p:Configuration=SbieRelease /p:Platform=x64 /m:8
```

保留專案檔指定的 toolset，無須將所有專案重新指定版本，也無須手動加入 WDK include 路徑。

## 5. 下載 Qt、Jom 並編譯 Plus

```bat
cd /d C:\src\Sandboxie
call SandboxiePlus\install_qt.cmd x64
call SandboxiePlus\install_jom.cmd
call SandboxiePlus\qmake_plus.cmd x64 build_qt6
cd /d C:\src\Sandboxie
```

Qt 與 Jom 會安裝在儲存庫旁的 `C:\src\Qt` 目錄。`qmake_plus.cmd` 會切換目前目錄，最後一行會將命令提示字元切回專案根目錄。

## 6. 編譯 Shell 與工具

```bat
cd /d C:\src\Sandboxie
msbuild SandboxiePlus\SbieShell\SbieShell.sln /t:Restore,Build /p:RestorePackagesConfig=true /p:Configuration=Release /p:Platform=x64 /m:8
msbuild SandboxieTools\SandboxieTools.sln /t:Build /p:Configuration=Release /p:Platform=x64 /m:8
```

## 7. 收集相依檔案並組合執行目錄

```bat
cd /d C:\src\Sandboxie
call Installer\fix_qt5_languages.cmd x64 build_qt6
call Installer\get_openssl.cmd
call Installer\get_7zip.cmd
call Installer\copy_build.cmd x64 build_qt6
```

主要產物位置：

| 產物 | 相對於儲存庫根目錄的位置 |
| --- | --- |
| Win32 注入 DLL | `Sandboxie\Bin\Win32\SbieRelease\SbieDll.dll` |
| x64 注入 DLL | `Sandboxie\Bin\x64\SbieRelease\SbieDll.dll` |
| x64 驅動 | `Sandboxie\Bin\x64\SbieRelease\SbieDrv.sys` |
| Plus 介面 | `SandboxiePlus\Bin\x64\Release\SandMan.exe` |
| 組合後的執行目錄 | `Installer\SbiePlus_x64` |

這些指令完成執行目錄的建置。若需要安裝程式，還需依 [Installer/Sandboxie-Plus.iss](Installer/Sandboxie-Plus.iss) 的設定進行 Inno Setup 打包。

## 8. 執行測試與 proxy 驗證

本 fork 已移除一般 SOCKS5 代理設定與連線的支持者憑證要求。重新編譯後仍須提供可連通的 SOCKS5 伺服器、連接埠及必要的帳號密碼。DNS 功能與實驗性的代理執行緒模式仍保留原有授權條件。

自行編譯的驅動與使用者模式程式涉及 Windows 驅動簽章及 Sandboxie 自身的簽章驗證。請依 [Plus 建置說明](SandboxiePlus/ReadMe.md) 在獨立測試環境設定測試簽章與部署；編譯完成本身不會替程式取得正式簽章。

部署後驗證：

- 沙箱啟動、停止、程式建立與檔案復原。
- 在沙箱選項的 Internet Proxy 頁設定 SOCKS5 代理並使用 Test Proxy。
- 分別使用沙箱內的 32 位元與 64 位元程式測試 TCP 連線，確認實際出口 IP。
- 停止代理伺服器，確認需要代理且不在繞過清單中的 TCP 連線會失敗。

介面的 Test Proxy 測試使用 Qt 的代理功能；測試通過後，仍須以沙箱程式確認 SbieDll 的實際轉送路徑。目前沒有 SOCKS5 UDP 轉送實作，DNS 經代理解析也未作為一般功能啟用。

## 9. 常見錯誤

| 訊息或現象 | 處理方式 |
| --- | --- |
| 找不到 Visual Studio 2022 或 C++ build tools | 在 Visual Studio Installer 補裝 VS 2022 與 x64／x86 C++ 工具；確認有 `vswhere.exe`。 |
| `msbuild` 不是內部或外部命令 | 使用 VS 2022 Developer Command Prompt。 |
| 找不到 `WindowsKernelModeDriver10.0` | 確認已安裝 WDK、其 VS 整合元件，以及 build number 相同的 SDK。 |
| 找不到 MFC 標頭或程式庫 | 補裝適用於 x64／x86 的 C++ MFC 元件。 |
| `sbieiniserver.cpp` 的 `C4819`／`C2220`，提到字碼頁 950 | 先更新 fork；此檔案已加上 UTF-8 BOM，讓 MSVC 正確辨識編碼。保持 `/WX`，並確認編輯器儲存時保留 BOM。 |
| SbieShell 找不到 `v142` 或 `10.0.19041.0` | 補裝 MSVC v142 與 Windows 10 SDK `10.0.19041.0`。 |
| 找不到 `qmake.exe` 或 `jom.exe` | 確認下載腳本成功、7-Zip 位於指定位置，並檢查儲存庫旁的 `Qt` 目錄。 |
| `copy_build.cmd` 找不到來源檔案 | 確認前面的核心、Plus、Shell、工具及相依套件步驟皆已成功。 |

`C2220` 表示某個警告被當成錯誤，仍須查看同一份輸出的 `warning Cxxxx`／`警告 Cxxxx` 才能確定原因。`C4819` 的編碼問題與處理方式見 [Microsoft 文件](https://learn.microsoft.com/en-us/cpp/error-messages/compiler-warnings/compiler-warning-level-1-c4819?view=msvc-170)。

已 clone 的使用者可在自己的儲存庫根目錄更新並重試 Win32 建置（以下使用此問題回報中的路徑）：

```bat
cd /d C:\Users\User1\Sandboxie
git pull --ff-only origin master
msbuild Sandboxie\SandboxDll.sln /t:Build /p:Configuration=SbieRelease /p:Platform=Win32 /m:8
```

回報錯誤時，提供執行的指令、第一個錯誤及其前後約 20 行輸出。

本指南已對照儲存庫的專案檔與 CI；本次編輯未在 Windows 上執行完整建置與連線測試。
