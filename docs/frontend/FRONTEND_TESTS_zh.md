# 前端测试

Wordupx Flutter 前端的黑盒测试。这些测试验证开发者编写的代码行为，且不会修改任何实现代码。如果测试未通过，开发者应修改自己的代码以满足预期行为。

## 运行测试

```bash
# 在 frontend 目录下
cd frontend
flutter test
```

### 测试报告

将测试报告保存到 `frontend/test/reports/`：

```bash
flutter test --reporter expanded 2>&1 | tee test/reports/report_$(date +%Y%m%d_%H%M%S).txt
```

输出 JSON 格式：

```bash
flutter test --reporter json > test/reports/report_$(date +%Y%m%d_%H%M%S).json
```

运行单个测试文件：

```bash
flutter test test/models/card_test.dart
flutter test test/utils/debounce_util_test.dart
```

## 测试结构

所有测试位于 `frontend/test/` 目录下：

- **models/** - 模型解析（fromJson、toJson）及属性访问器
- **utils/** - 工具类（DebounceUtil 等）
- **extensions/** - Widget 和 Context 扩展方法
- **services/** - API 常量、存储异常
- **routers/** - 路由定义
- **providers/** - 状态类和通知器
- **helpers/** - 测试辅助工具（如 InMemoryHydratedStorage）
- **reports/** - 生成的测试报告（已加入 gitignore）

## 测试理念

这些是黑盒测试：它们只针对每个单元的公共 API 和可观察行为进行断言，不会对被测实现代码做任何修改。如果测试失败，开发者应修改自己的代码以满足预期行为。
