# CamCardReplica 1.0 构建信息

| 项目 | 值 |
|---|---|
| 产物 | `CamCardReplica-1.0-iOS-Simulator.zip` |
| App 版本 | 1.0 (1) |
| Bundle Identifier | `shinn.CamCardReplica` |
| Configuration | Release |
| SDK | iPhone Simulator 26.4 |
| 最低系统 | iOS 26.4 |
| 架构 | arm64、x86_64 |
| 源码版本 | `d3dc38f` |
| 构建时间 | 2026-11-03 11:18（Asia/Shanghai） |
| 压缩包大小 | 5,430,181 bytes |
| SHA-256 | `abc38ad97c173e463b9cc8aa0b9c01a004163182935cb0f302c49d8d57992a7c` |
| 验证 | 解压、模拟器安装和启动均成功 |

## 校验

```bash
cd Artifacts
shasum -a 256 -c SHA256SUMS
unzip -t CamCardReplica-1.0-iOS-Simulator.zip
```

## 安装

```bash
unzip CamCardReplica-1.0-iOS-Simulator.zip
xcrun simctl install booted CamCardReplica.app
xcrun simctl launch booted shinn.CamCardReplica
```

该产物仅适用于 iOS 26.4 模拟器，不能安装到真机。真机版本需要开发者证书和描述文件签名。
