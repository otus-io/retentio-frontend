# 测试报告摘要

**日期：** 2026-02-11
**结果：** 145 通过，22 失败（共 167 项）

---

## 失败的测试

### 1. `test/widget_test.dart` — Counter increments smoke test

**状态：** 失败（已有测试，非新增测试套件）

**错误信息：**
```
Bad state: No ProviderScope found
```

**根本原因：**
`MyApp` 是一个 `ConsumerStatefulWidget`（Riverpod），需要一个 `ProviderScope` 作为祖先组件。测试中直接调用了 `tester.pumpWidget(const MyApp())`，但没有用 `ProviderScope` 包裹。

**位置：**
- 测试文件：`test/widget_test.dart`，第 16 行
- 源文件：`lib/main.dart`，第 65 行（`_MyAppState.build`）

**修复建议：**
开发者需要在测试中用 `ProviderScope` 包裹 `MyApp`：

```dart
await tester.pumpWidget(
  ProviderScope(
    child: const MyApp(),
  ),
);
```

---

### 2. `test/models/deck_test.dart` — Deck fromJson 系列（6 项失败）

**失败的测试：**
- `parses deck with owner as object`
- `parses deck with owner as string`
- `parses templates as nested list [[0], [1]]`
- `parses templates as flat list [0, 1]`
- `uses field when fields is missing`
- `parses createdAt and updatedAt`

**根本原因：** `Deck.fromJson` 存在 3 个缺陷：

#### 缺陷 A：不支持扁平 templates 列表

**位置：** `lib/models/deck.dart`，第 100-101 行

```dart
templates: List<List<int>>.from(
  json["templates"].map((x) => List<int>.from(x.map((x) => x))),
),
```

**问题：** 当 API 返回扁平列表 `[0, 1]` 而非嵌套列表 `[[0], [1]]` 时，代码尝试对 `int` 调用 `.map()`，导致崩溃。

**错误信息：**
```
NoSuchMethodError: Class 'int' has no instance method 'map'.
Receiver: 0
Tried calling: map(Closure: (dynamic) => dynamic)
```

**修复建议：** 添加兼容处理，同时支持扁平和嵌套列表：
```dart
List<List<int>> parsedTemplates = [];
if (json['templates'] != null && json['templates'] is List) {
  var templatesList = json['templates'] as List;
  if (templatesList.isNotEmpty && templatesList.first is List) {
    parsedTemplates = List<List<int>>.from(
      templatesList.map((x) => List<int>.from(x.map((x) => x))),
    );
  } else {
    parsedTemplates = templatesList.map((e) => <int>[e as int]).toList();
  }
}
```

#### 缺陷 B：rate 字段无 null 处理

**位置：** `lib/models/deck.dart`，第 104 行

```dart
rate: json['rate'],
```

**问题：** 当 JSON 中缺少 `rate` 字段时，`json['rate']` 为 `null`，赋值给 `int rate` 会崩溃。

**错误信息：**
```
type 'Null' is not a subtype of type 'int'
```

**修复建议：**
```dart
rate: json['rate'] as int? ?? 0,
```

#### 缺陷 C：rate 字段无类型转换

**位置：** `lib/models/deck.dart`，第 104 行

**问题：** 当 API 返回 `rate` 为 `double`（如 `0.95` 或 `2.5`）时，赋值给 `int rate` 会崩溃。

**错误信息：**
```
type 'double' is not a subtype of type 'int'
```

**修复建议：**
```dart
rate: (json['rate'] as num?)?.toInt() ?? 0,
```

---

### 3. `test/screen/deck/deck_detail_screen_test.dart` — 全部 11 项失败

**失败的测试：**
- `renders without errors`
- `displays deck name in AppBar`
- `displays total cards stat`
- `displays new cards stat`
- `displays due cards stat`
- `displays learned cards stat`
- `shows start learning button when cards available`
- `shows all caught up when no cards to study`
- `start learning button is disabled when no cards`
- `start learning button is enabled when cards available`
- `displays stat icons`

**根本原因：** 与上述 `Deck.fromJson` 相同的缺陷（缺陷 A + C）。测试使用 `Deck.fromJson` 创建测试数据，传入扁平 templates `[0]` 和 double rate `2.5`，触发崩溃。

---

### 4. `test/screen/deck/deck_learn_screen_test.dart` — 全部 4 项失败

**失败的测试：**
- `renders without errors`
- `displays deck name in AppBar`
- `shows loading or completion state after init`
- `has Scaffold with AppBar`

**根本原因：** 与上述 `Deck.fromJson` 相同的缺陷（缺陷 A + C）。

---

## 失败汇总

| 缺陷 | 影响的测试数 | 严重程度 |
|---|---|---|
| `Deck.fromJson` 不支持扁平 templates | 13 项 | 高 — 运行时崩溃 |
| `Deck.fromJson` rate 无 null 处理 | 5 项 | 高 — 运行时崩溃 |
| `Deck.fromJson` rate 无类型转换 | 15 项 | 高 — 运行时崩溃 |
| `widget_test.dart` 缺少 ProviderScope | 1 项 | 低 — 模板代码未更新 |

> 注：部分测试同时受多个缺陷影响。总计 22 项失败测试。

---

## 通过的测试套件（145 项）

### 单元测试（72 项）

| 测试文件 | 测试数 | 状态 |
|---|---|---|
| `test/models/card_test.dart` | 15 | 通过 |
| `test/models/deck_test.dart` | 5（共 11，6 失败） | 部分通过 |
| `test/models/res_base_model_test.dart` | 9 | 通过 |
| `test/models/user_test.dart` | 2 | 通过 |
| `test/extensions/widget_extension_test.dart` | 11 | 通过 |
| `test/providers/deck_list_state_test.dart` | 4 | 通过 |
| `test/providers/theme_provider_test.dart` | 5 | 通过 |
| `test/routers/routers_test.dart` | 4 | 通过 |
| `test/services/api_test.dart` | 3 | 通过 |
| `test/services/storage/storage_exception_test.dart` | 4 | 通过 |
| `test/utils/debounce_util_test.dart` | 3 | 通过 |
| `test/constants_test.dart` | 1 | 通过 |

### Widget 测试（73 项通过，15 项失败）

| 测试文件 | 通过 | 失败 | 状态 |
|---|---|---|---|
| `test/screen/home/home_screen_test.dart` | 7 | 0 | 通过 |
| `test/screen/login/login_screen_test.dart` | 11 | 0 | 通过 |
| `test/screen/login/widgets/forgot_password_test.dart` | 7 | 0 | 通过 |
| `test/screen/register/register_screen_test.dart` | 9 | 0 | 通过 |
| `test/screen/profile/profile_screen_test.dart` | 10 | 0 | 通过 |
| `test/screen/deck/deck_detail_screen_test.dart` | 0 | 11 | 失败 |
| `test/screen/deck/deck_learn_screen_test.dart` | 0 | 4 | 失败 |
| `test/screen/learn/learn_screen_test.dart` | 5 | 0 | 通过 |
| `test/widgets/bottom_popup_test.dart` | 6 | 0 | 通过 |
| `test/widgets/common_refresher_test.dart` | 7 | 0 | 通过 |
