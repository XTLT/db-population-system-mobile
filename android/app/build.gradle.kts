import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.population.population_mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.population.population_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // 支持Android 4.4+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    // 签名配置
    signingConfigs {
        create("release") {
            // 从环境变量或key.properties文件读取签名配置
            // 生产环境必须配置正式签名
            val keystoreFile = file("../key.properties")
            if (keystoreFile.exists()) {
                val properties = Properties()
                properties.load(keystoreFile.inputStream())
                storeFile = file(properties["storeFile"] as String)
                storePassword = properties["storePassword"] as String
                keyAlias = properties["keyAlias"] as String
                keyPassword = properties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // 启用代码混淆和优化（修复漏洞4、5）
            isMinifyEnabled = true
            isShrinkResources = true
            
            // ProGuard规则
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // 使用release签名配置（修复漏洞6）
            val releaseSignConfig = signingConfigs.findByName("release")
            if (releaseSignConfig != null && releaseSignConfig.storeFile != null) {
                signingConfig = releaseSignConfig
            } else {
                // 如果没有配置release签名，使用debug签名（仅用于测试）
                // ⚠️ 生产环境必须配置正式签名
                signingConfig = signingConfigs.getByName("debug")
            }
        }
        
        debug {
            // Debug版本不混淆
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
