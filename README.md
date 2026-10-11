# 人口通 - 移动端

人口通系统的移动端仓库（Flutter App）。

> 本仓库由原 `db-population-system` 拆分而来，仅包含移动端；服务端与 Web 前端在 `db-population-system-server`，桌面端在 `db-population-system-desktop`。

## 功能

- 数据统计（人口、补贴、社保、林地面积等）
- 人员/家庭信息查询
- 补贴明细查询（地力补贴、养老保险、低保、特困、残疾人护理补贴、高龄补贴）
- 移动端通过 HTTPS 连接服务端（支持 IPv6）

## 环境要求

- Flutter SDK（≥ 3.x）
- Android SDK（构建 APK）

## 构建

```bash
./build_mobile.sh check      # 检查 Flutter 环境
./build_mobile.sh config https://你的域名:5000   # 配置 API 地址
./build_mobile.sh build release                  # 构建正式版 APK
./build_mobile.sh build debug                    # 调试版
./build_mobile.sh build split                    # 按 CPU 架构分包
```

构建产物：`mobile/build/app/outputs/flutter-apk/`

## 目录结构

```
lib/                    # Flutter 代码（页面/API 客户端/配置）
  config/app_config.dart  # API 地址配置
  pages/                  # 各功能页面
  services/               # API 请求封装
assets/certs/           # 服务端证书（证书扎钉用）
android/                # Android 工程
ios/                    # iOS 工程
docs/                   # 开发指南
```

## 证书说明

移动端使用证书扎钉（Certificate Pinning）验证服务端身份。更换服务端证书后，需将新的 `server.crt` 复制到 `assets/certs/` 并重新构建。

详见 `docs/移动端开发指南.md` 与 `docs/Android签名配置指南.md`。
