# Flutter安全配置
# 用于代码混淆和优化

# 保留Flutter引擎相关类
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保留Dart反射相关
-keep class * extends java.lang.reflect.** { *; }

# 保留序列化相关
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 移除调试日志
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# 移除print调试输出
-assumenosideeffects class java.io.PrintStream {
    public void println(...);
    public void print(...);
}

# 保留第三方库的必要类
-keep class com.squareup.okhttp.** { *; }
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }

# 保留SharedPreferences相关
-keep class * extends android.content.SharedPreferences { *; }

# 保留安全存储相关
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.it_nomads.flutter_secure_storage.** { *; }

# 保留Dio HTTP客户端
-keep class com.dio.** { *; }

# 防止路径泄露 - 移除文件路径字符串
-adaptclassstrings
-keepparameternames
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# 保留注解
-keepattributes *Annotation*

# Google Play Core SplitCompat (Flutter动态分发功能，不使用但需要保留引用)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
