# 人口通 - 移动端（Android App）

人口通系统的移动端仓库（Flutter App），通过 HTTPS 连接服务端使用。

> 本仓库由原 `db-population-system` 拆分而来；服务端与 Web 前端在 `db-population-system-server`，桌面端在 `db-population-system-desktop`。

## 功能

### 数据统计

- 人口、补贴、社保卡、林地面积等统计总览

### 人员 / 家庭

- 人员信息查询：详情页展示全部字段（含残疾类型 / 等级、社保卡多来源、小组）
- 家庭成员列表与添加：**新增家庭成员自动带出同户地址与小组**（空值才填充，不覆盖已输入；输入户号后自动带出）
- **与户主关系标准下拉**：依据公安部户口簿规范 + GB 4761-1984 家庭关系代码 + 民法典近亲属，提供 45 项标准关系；存量非标准值自动并入选项兜底不丢失
- 每户唯一户主校验、换户主整户关系重建（服务端统一处理，三端生效）

### 补贴查询

- 地力补贴、养老保险、低保、特困、残疾人护理补贴、高龄补贴明细查询

### 社保卡

- 同一人存在多个不同社保卡时展示最多 3 个，每个卡标注来源

### 更新与安全

- **自动更新**：检查更新（服务器主源 + SHA256 校验）→ 下载安装
- HTTPS 连接服务端（支持 IPv6），证书扎钉（Certificate Pinning）验证服务端身份

## 环境要求

- Flutter SDK（≥ 3.x）
- Android SDK（构建 APK）

## 构建（android-arm64 APK）

```bash
./build_mobile.sh check      # 检查 Flutter 环境
./build_mobile.sh config https://你的域名:5000   # 配置 API 地址
./build_mobile.sh build release --target-platform android-arm64   # 构建正式版 APK
```

直接构建（推荐 arm64，体积小、兼容主流安卓手机）：

```bash
flutter build apk --release --target-platform android-arm64
```

构建产物：`build/app/outputs/flutter-apk/app-release.apk`

## 目录结构

```
lib/                    # Flutter 代码（页面 / API 客户端 / 配置）
  config/app_config.dart  # API 地址配置
  pages/                  # 各功能页面
  services/               # API 请求封装
  constants/              # 公共常量（如关系标准列表）
assets/certs/           # 服务端证书（证书扎钉用）
android/                # Android 工程
ios/                    # iOS 工程
docs/                   # 开发指南
```

## 证书说明

移动端使用证书扎钉（Certificate Pinning）验证服务端身份。更换服务端证书后，需将新的 `server.crt` 复制到 `assets/certs/` 并重新构建。

详见 `docs/移动端开发指南.md` 与 `docs/Android签名配置指南.md`。
