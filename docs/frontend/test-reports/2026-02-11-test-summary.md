# 测试报告摘要

**日期：** 2026-02-11
**结果：** 89 通过，1 失败（共 90 项）

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

或者更新测试以匹配当前的应用架构（该测试是 Flutter 项目创建时的模板代码，在引入 Riverpod 后未做更新）。

---

## 通过的测试套件（89 项）

| 测试文件 | 测试数 | 状态 |
|---|---|---|
| `test/models/card_test.dart` | 15 | 通过 |
| `test/models/deck_test.dart` | 11 | 通过 |
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
