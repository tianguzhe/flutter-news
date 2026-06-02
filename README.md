# News Course

一个 Flutter 新闻示例项目，使用 Riverpod、GoRouter、Dio、Freezed 和
Talker 组织网络请求、状态管理、路由与调试日志。

## 结构

项目采用 feature-first 目录，并在每个 feature 内按 Flutter 官方架构建议拆分
数据层和展示层：

- `lib/core/`：跨功能共享的基础设施，包括路由、网络客户端、日志和全局 provider。
- `lib/features/news/data/models/`：Newsdata 接口模型与分页模型。
- `lib/features/news/data/services/`：面向远端 API 的服务封装。
- `lib/features/news/data/repositories/`：展示层依赖的数据访问边界。
- `lib/features/news/presentation/view_models/`：Riverpod view model，负责页面状态与交互。
- `lib/features/news/presentation/pages/`：页面入口。
- `lib/features/news/presentation/widgets/`：新闻功能内复用 UI 组件。

当前功能规模还不需要单独的 `domain/` 层；如果后续出现复杂业务规则、跨数据源聚合
或多个 feature 共享的实体，再引入 domain 层会更合适。

## 常用命令

```sh
dart run build_runner build
flutter analyze
flutter test
```

如果需要使用自己的 Newsdata API key：

```sh
flutter run --dart-define=NEWSDATA_API_KEY=your_api_key
```
