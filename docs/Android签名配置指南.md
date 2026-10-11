# Android 应用签名配置指南

## 一、签名密钥生成

### 1. 生成密钥库

```bash
# 进入 android/app 目录
cd mobile/android/app

# 生成签名密钥
keytool -genkey -v -keystore key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias population-key
```

**参数说明**:
- `key.jks`: 密钥库文件名
- `population-key`: 密钥别名
- `2048`: 密钥长度
- `10000`: 有效期（天）

### 2. 填写密钥信息

执行命令后会提示输入：
- 密钥库密码
- 密钥密码
- 姓名、组织、城市、省份、国家代码

**重要**: 妥善保管密钥库文件和密码！

---

## 二、创建签名配置文件

### 1. 创建 key.properties

在 `mobile/android/` 目录创建 `key.properties` 文件：

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=population-key
storeFile=key.jks
```

**注意**:
- `storeFile` 是相对于 `mobile/android/app/` 的路径
- 不要将 `key.properties` 提交到版本控制

### 2. 更新 .gitignore

在 `mobile/.gitignore` 添加：

```
# Android 签名
android/key.properties
android/app/key.jks
```

---

## 三、配置 Gradle 构建

### 1. 编辑 build.gradle

编辑 `mobile/android/app/build.gradle`：

```gradle
// 在文件开头添加
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... 其他配置
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 四、构建签名 APK

### 使用脚本构建

```bash
# 构建 Release APK
./build_apk.sh --release

# 构建分架构 APK（推荐，体积更小）
./build_apk.sh --split
```

### 手动构建

```bash
cd mobile

# 清理
flutter clean

# 获取依赖
flutter pub get

# 构建 Release APK
flutter build apk --release

# 或构建分架构 APK
flutter build apk --release --split-per-abi
```

---

## 五、输出文件

构建完成后，APK 文件位于：

```
mobile/build/app/outputs/flutter-apk/
├── app-release.apk              # 完整 APK
├── app-armeabi-v7a-release.apk   # ARM 32位
├── app-arm64-v8a-release.apk     # ARM 64位（推荐）
└── app-x86_64-release.apk        # x86 64位
```

**推荐使用分架构 APK**：
- 体积更小（约减少 40-50%）
- 用户自动下载适配版本
- 兼容性更好

---

## 六、密钥安全

### 1. 备份密钥

```bash
# 备份密钥库文件
cp mobile/android/app/key.jks ~/backup/

# 备份配置信息
# 记录以下信息到安全的地方：
# - 密钥库密码
# - 密钥密码
# - 密钥别名
# - 有效期
```

### 2. 环境变量方式（可选）

为了更安全，可以使用环境变量：

```gradle
// build.gradle
signingConfigs {
    release {
        keyAlias System.getenv("KEY_ALIAS")
        keyPassword System.getenv("KEY_PASSWORD")
        storeFile file(System.getenv("KEYSTORE_FILE"))
        storePassword System.getenv("STORE_PASSWORD")
    }
}
```

在 CI/CD 或构建服务器设置环境变量。

---

## 七、常见问题

### 1. 忘记密码

**无法恢复**！必须重新生成密钥并重新发布应用。

### 2. 密钥丢失

**无法更新应用**！Google Play 会验证签名，必须使用相同密钥签名。

建议：
- 多处备份密钥
- 使用密码管理器
- 团队共享时建立安全流程

### 3. 签名不匹配

确保：
- 使用相同的密钥库文件
- 使用相同的密钥别名
- 密码正确

### 4. ProGuard 混淆问题

如果构建后应用崩溃，检查 `proguard-rules.pro`：

```proguard
# Flutter 相关
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
```

---

## 八、应用商店发布

### Google Play Store

1. 构建 App Bundle（推荐）：
   ```bash
   flutter build appbundle --release
   ```

2. 输出文件：
   ```
   mobile/build/app/outputs/bundle/release/app-release.aab
   ```

3. 上传到 Google Play Console

### 国内应用商店

大多数接受 APK 文件：
- 腾讯应用宝
- 华为应用市场
- 小米应用商店
- OPPO 软件商店
- vivo 应用商店

---

## 九、自动化构建（CI/CD）

### GitHub Actions 示例

```yaml
name: Build APK
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.0'
      
      - name: Build APK
        env:
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          KEYSTORE_FILE: ${{ secrets.KEYSTORE_FILE }}
          STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}
        run: |
          flutter pub get
          flutter build apk --release --split-per-abi
      
      - name: Upload APK
        uses: actions/upload-artifact@v2
        with:
          name: release-apk
          path: mobile/build/app/outputs/flutter-apk/*.apk
```

---

## 十、检查清单

部署前确认：

- [ ] 已生成签名密钥
- [ ] 已创建 key.properties
- [ ] 已配置 build.gradle
- [ ] 已备份密钥库文件
- [ ] 已记录密钥信息
- [ ] 已更新 .gitignore
- [ ] 已测试签名构建
- [ ] 已验证 APK 可安装
- [ ] 已检查应用功能
