# 证书固定部署说明

此目录用于存放服务端的 SSL 证书文件，实现证书固定（Certificate Pinning）。

## 部署步骤

### 1. 获取服务端证书

服务端证书位置：`server/certs/server.crt`

### 2. 复制证书到此目录

```bash
# 从服务端复制证书到 Mobile 客户端
cp ../../server/certs/server.crt ./server.crt
```

### 3. 重新构建 APP

```bash
cd mobile
flutter build apk
```

## 安全说明

- **有证书文件**：启用证书固定，仅信任此证书
- **无证书文件**：跳过证书验证（不安全，仅限开发环境）

## 注意事项

- 证书文件会打包到 APP 中，无法动态更新
- 如需更换证书，需要重新发布 APP 版本
