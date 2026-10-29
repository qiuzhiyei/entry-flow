# 薄荷绿记账本 · entry_flow

基于 `design_ref/薄荷绿记账本-App-原型` 重写的 **Flutter 原生本地记账本**。界面全部由 Flutter Widget 构建，没有 HTML/CSS 套壳；账目通过 Hive 持久化在本机。

## 技术栈

| 依赖 | 用途 |
| --- | --- |
| `provider` 6.1 | 账本状态管理、界面实时刷新 |
| `hive` / `hive_flutter` 2.2 / 1.1 | 本地键值数据库 |
| `intl` 0.20 | 金额千分位格式化 |
| `flutter_localizations` | 中文日期选择器、Material 本地化 |

## 已实现

- **主框架**：底部导航（首页 / 统计 / 记一笔 / 我的）、桌面端居中手机画布。
- **首页**：日期问候、本月支出/收入/结余卡片、环比标签、按日分组的交易列表、空状态、悬浮「记一笔」。
- **记一笔**：支出/收入切换、分类选择、自定义数字键盘、日期选择、备注、金额校验、写入 Hive 后自动返回并刷新。
- **本地数据**：`Record` 模型（金额以「分」存储避免浮点误差）、手写 Hive TypeAdapter、Provider 监听 Hive Box 变化。
- **我的**：本月预算进度、记录统计、清空所有记录（带确认）、本地存储说明。
- **统计（首版）**：本月收支概览、按支出分类的占比与金额进度条。环形图和近 6 个月柱状图留待下一轮。
- **测试**：Provider 聚合、月度对比、清空、金额校验、Hive 关闭重开后的持久化回归、首页空态与实时刷新。

## 预览

以下为 Flutter 390×844 实际渲染（Web 目标；真机由系统安全区补充状态栏/底部手势条）。

| 首页 | 记一笔 | 日期选择 |
| --- | --- | --- |
| ![首页](docs/screenshots/home.png) | ![记一笔](docs/screenshots/add-record.png) | ![日期选择](docs/screenshots/date-picker.png) |

## 目录

```text
lib/
├─ main.dart                    # Hive 初始化 + Provider 注入
├─ app.dart                     # MaterialApp / 主 Shell / 路由 / 滚动行为
├─ app_keys.dart                # 全局 SnackBar key（跨路由 toast）
├─ models/
│  ├─ record.dart               # Record 模型 + 手写 Hive TypeAdapter
│  └─ category.dart             # 分类定义与配色、图标
├─ providers/ledger_provider.dart
├─ services/
│  ├─ hive_service.dart         # Box 初始化
│  └─ seed_data.dart            # 首次启动的原型示例数据
├─ screens/
│  ├─ home_screen.dart
│  ├─ add_record_screen.dart
│  ├─ stats_screen.dart
│  ├─ profile_screen.dart
│  └─ startup_failure_screen.dart
├─ theme/app_theme.dart         # 原型设计令牌（颜色/字号/阴影/圆角）
├─ utils/formatters.dart        # 金额、日期、问候语
└─ widgets/
   ├─ app_frame.dart            # 宽屏居中手机画布
   └─ bottom_nav.dart
```

## 运行

```bash
# 拉取依赖
flutter pub get

# 运行（选择已连接的设备/模拟器）
flutter run

# 其他目标
flutter run -d windows
flutter run -d edge
```

本机 Flutter 未加入 `PATH` 时，可使用：

```powershell
& 'D:\Software\Develop\Flutter\bin\flutter.bat' pub get
& 'D:\Software\Develop\Flutter\bin\flutter.bat' run
```

验证：

```bash
flutter analyze
flutter test
flutter build web --release
```

> Windows 桌面端构建含插件的项目需要系统开启「开发者模式」（符号链接支持）；本机已验证 `flutter build web` 与全部测试。Android 构建还需要在 Android SDK 中安装 `cmdline-tools`。

## 本地数据说明

- 数据保存在 Hive 的 `records` Box 中，路径位于应用文档目录下的 `mint_ledger/`。
- 金额字段为 `amountCents`（整数分）；日期以本地 ISO-8601 字符串保存，避免时区切换导致记账日期漂移。
- 首次启动会写入 45 条原型示例数据，便于直接查看完整列表与统计。是否已经灌入示例数据记录在 Hive 的 `meta` Box 中；清空记录后不会再次注入。要使用空账本：
  1. 将 `lib/services/seed_data.dart` 顶部的 `kSeedDemoData` 改为 `false`；
  2. 在「我的 → 清空所有记录」中清空已有示例数据（或清除应用数据后重装）。
- 也可以在「我的」页直接清空全部真实/示例记录；操作前会二次确认。

## 下一轮

1. 统计页：按原型补齐环形图、分类图例、近 6 个月柱状图、按月/按年切换。
2. 我的页：多账本、每日提醒、数据备份、预算设置及其持久化。
3. 交易详情：点击交易查看、编辑、删除。
4. 平台细节：应用名/图标/启动图、Android/iOS 配置与真机回归。
