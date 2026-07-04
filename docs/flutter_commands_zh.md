# Flutter 命令速查

本仓库常用 Flutter CLI 命令速查。均在仓库根目录（`retentio-frontend/`，即 `pubspec.yaml` 所在目录）执行。

🌐 [English](flutter_commands.md) | 中文

## 设备

列出已连接的模拟器与真机：

```bash
flutter devices
```

| 命令 | 用途 |
| ---- | ---- |
| `flutter doctor` | 检查工具链与平台环境 |
| `flutter emulators` | 列出可用模拟器 |
| `flutter emulators --launch <emulator_id>` | 启动模拟器 |

若无可用设备，请先启动 iOS 模拟器或 Android 模拟器，或连接并授权真机。

## 运行

默认 debug 运行（仅一台设备时会自动选中）：

```bash
flutter pub get
flutter run
```

在指定设备上运行（`-d` 可使用 `flutter devices` 输出中的设备 ID 或名称）：

```bash
flutter run -d <device_id>
flutter run -d "iPhone 16 Pro"
flutter run -d emulator-5554
```

| 参数 | 含义 |
| ---- | ---- |
| `--release` | Flutter 正式构建模式（优化、无调试工具） |
| `--dart-define=API_ENV=release` | 连接生产 API（见下文） |
| `--dart-define=API_HOST=<url>` | 覆盖 API 根地址（优先于 `API_ENV`） |

### 常用组合

```bash
# 指定设备 + dev API（debug 运行默认）
flutter run -d <device_id>

# 指定设备 + 生产 API（仍为 debug 构建）
flutter run -d <device_id> --dart-define=API_ENV=release

# 正式构建 + 生产 API
flutter run -d <device_id> --release --dart-define=API_ENV=release

# Android 模拟器连本地后端
flutter run -d emulator-5554 --dart-define=API_ENV=debug

# 自定义主机（如局域网真机）
flutter run -d <device_id> --dart-define=API_HOST=http://192.168.1.10:8080
```

## 构建

```bash
# Android
flutter build apk --release --dart-define=API_ENV=release
flutter build appbundle --release --dart-define=API_ENV=release

# iOS
flutter build ipa --release --dart-define=API_ENV=release
```

正式包指向非生产环境时：

```bash
flutter build ipa --dart-define=API_ENV=dev
```

## 后端环境（`API_ENV`）

通过 `--dart-define` 在编译期选择 API 主机。实现见 `lib/services/env.dart`。

| `API_ENV` | 主机 |
| --------- | ---- |
| `debug` | `http://localhost:8080` |
| `dev` | `https://10.0.0.145:8443` |
| `release` | `https://api.retentio.app:8443` |

未指定 `API_ENV` 时：

- **`flutter run`** 等非 release 构建默认 **`dev`**
- **`--release`** / 正式构建（`flutter build ipa`、Xcode Archive）默认 **`release`**

`API_HOST` 非空时覆盖上表映射。

## iOS 说明

- `ios/Flutter/Generated.xcconfig` 由 Flutter 生成。若 Xcode 提示缺失，打开 `ios/Runner.xcworkspace` 前先执行 `flutter pub get`。
- 若插件报错 `Flutter/Flutter.h` file not found，在构建用 Mac 上执行 `flutter pub get`，再 `cd ios && pod install`。
