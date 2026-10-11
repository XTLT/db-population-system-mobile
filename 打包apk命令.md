# 打包 APK 命令

> 手机端基于 Flutter，需要先安装 Flutter SDK（含 Android 工具链）。
> 打包命令本身很简单，但首次构建会遇到两个环境问题（见下文「首次环境修复」），修过一次以后就不用再管。

## 零、首次环境修复（只做一次）

首次在这台机器上打包会报两个错，按顺序执行以下命令修好，以后就不用再做了：

```bash
# 1. 安装 sdkmanager（如果还没有）
sudo apt install -y sdkmanager

# 2. 接受所有 Android SDK 许可证（解决 NDK License not accepted 报错）
yes | sudo sdkmanager --licenses --sdk_root=/usr/lib/android-sdk

# 3. 把 SDK 目录所有权改成当前用户（解决 "SDK directory is not writable" 报错）
sudo chown -R $USER:$USER /usr/lib/android-sdk
```

> 报错现象对应关系：
> - `LicenceNotAcceptedException: ... ndk;28.2.13676358` → 执行第 2 步
> - `InstallFailedException: The SDK directory is not writable` → 执行第 3 步

## 一、打包前准备

### 1. 配置服务器地址（必须）

打包前先修改 `mobile/lib/config/app_config.dart` 里的 `apiBaseUrl`，指向要连接的服务器：

```dart
static String apiBaseUrl = 'https://your-domain.com:5000';
```

也可用脚本配置（会自动备份原文件）：

```bash
cd /mnt/data/rj/population-system
./build_mobile.sh config https://your-domain.com:5000
```

> 注意：`AppConfig.getApiUrl()` 是死代码（它加了 `/api/v1` 前缀，但服务器没有 `/api/v1`）。
> 实际所有 API 调用都直接用 `AppConfig.apiBaseUrl` + `/api/...` 路径，改 `apiBaseUrl` 即可。

### 2. 检查 Flutter 环境

```bash
flutter doctor            # 查看 SDK / Android 工具链状态
cd /mnt/data/rj/population-system
./build_mobile.sh check   # 或用脚本检查
```

## 二、打包 APK

### 常用：打包 release 版本

```bash
cd /mnt/data/rj/population-system/mobile && flutter pub get && flutter build apk --release
```

打包完成后 APK 在：
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

### 按架构分包（体积更小）

```bash
cd /mnt/data/rj/population-system/mobile && flutter build apk --release --split-per-abi
```
会生成 `app-armeabi-v7a-release.apk`、`app-arm64-v8a-release.apk` 等文件。

### 只打单个常用架构

```bash
cd /mnt/data/rj/population-system/mobile && flutter build apk --release --target-platform android-arm64
```

### debug 版本（带日志，用于调试）

```bash
cd /mnt/data/rj/population-system/mobile && flutter build apk --debug
```
输出：`mobile/build/app/outputs/flutter-apk/app-debug.apk`

### 清理后重新打包（解决缓存类问题）

```bash
cd /mnt/data/rj/population-system/mobile && flutter clean && flutter pub get && flutter build apk --release
```

## 三、使用 build_mobile.sh 脚本（推荐）

项目根目录的 `build_mobile.sh` 封装了完整流程：

```bash
cd /mnt/data/rj/population-system

./build_mobile.sh check                                      # 检查 Flutter 环境
./build_mobile.sh config https://your-domain.com:5000        # 配置 API 地址
./build_mobile.sh deps                                       # 获取依赖
./build_mobile.sh test                                       # 运行单元测试
./build_mobile.sh analyze                                    # 静态代码分析
./build_mobile.sh build release                              # 构建 release APK
./build_mobile.sh build debug                                # 构建 debug APK
./build_mobile.sh build split                                # 分架构打包
./build_mobile.sh clean                                      # 清理构建
./build_mobile.sh all https://your-domain.com:5000           # 完整流程（配置+依赖+测试+分析+构建）
```

## 四、测试与分析

发布前建议跑一遍测试和分析（避免打包出新版带 bug）：

```bash
cd /mnt/data/rj/population-system/mobile
flutter test                 # 单元 + widget 测试
flutter analyze              # 静态分析
```

测试文件在 `mobile/test/`，覆盖 validators、models、network cache、pagination 等。

## 五、三个客户端说明

- **桌面客户端**：PyQt6，`desktop/`，用 `./start_desktop.sh` 启动
- **手机 app 端**：Flutter，`mobile/`，即本文档打包的对象
- **电脑网页端**：Vanilla JS，`server/web_static/`，由 Flask 直接 serve

## 六、推送到 GitHub

```bash
cd /mnt/data/rj/population-system
git add -A
git commit -m "修复创建用户308重定向：手机端API路径补末尾斜杠"
git push origin master
```

> commit message 按实际改动写，示例仅为格式。

## 七、打包后部署到服务器

重启服务器让新代码生效（仅当改了服务端代码时需要，本次只改手机端，服务器无需重启）：

```bash
# 如果用 systemd：
sudo systemctl restart population-system
# 如果用 start_server.sh：
cd /mnt/data/rj/population-system
./start_server.sh restart
# 如果手动运行的 gunicorn：
kill -HUP <gunicorn_master_pid>   # 热重载 worker
```

## 八、修复记录

### 2026-09-25：打包环境修复 + 创建用户 308

**打包报错**：首次打包 `flutter build apk` 失败，两个原因：

1. **NDK 许可证未接受** → `LicenceNotAcceptedException: ndk;28.2.13676358`
   - 原因：`/usr/lib/android-sdk/licenses/` 里缺少 NDK 的许可证哈希
   - 修复：`yes | sudo sdkmanager --licenses --sdk_root=/usr/lib/android-sdk`

2. **SDK 目录不可写** → `InstallFailedException: The SDK directory is not writable`
   - 原因：`/usr/lib/android-sdk` 归 root，gradle 以普通用户运行无法写入 NDK
   - 修复：`sudo chown -R $USER:$USER /usr/lib/android-sdk`

这两步只做一次，以后直接打包即可。

**创建用户 308**：手机 app 创建用户返回 308，其他功能正常。
- 根因：服务端 `users.py` 路由 `@bp.route('/')` + prefix `/api/users` = 实际路径 `/api/users/`（带斜杠），
  手机端请求 `/api/users`（不带斜杠），Flask 对「路由带斜杠、请求不带」返回 308 Permanent Redirect。
  - GET 重定向 Dio 自动跟随（无 body），用户列表看起来正常，只是多一次往返。
  - POST 重定向时 Dio 会丢请求体/认证头，导致创建失败。
- 修复：`mobile/lib/api/user_api.dart` 第 11、32 行，GET/POST 路径补末尾斜杠 `/api/users/`。
- 其他模块（编辑、删除、重置密码）走 `/api/users/$userId` 等带参路径，服务端不带斜杠、手机端也不带，不受影响。

重新打包 APK 即可验证创建用户按钮。
