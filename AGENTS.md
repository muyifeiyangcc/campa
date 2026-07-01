# AGENTS.md - iOS Swift 开发规范

## 项目概述
- 项目名称：[你的项目名]
- 最低部署目标：iOS 15.0+
- 架构模式：MVVM (Model-View-ViewModel)
- 依赖管理：Swift Package Manager (SPM)
- UI 框架：UIKit

## 编码规范

### 命名规范
- 类型名（类、结构体、枚举、协议）：`UpperCamelCase`
- 变量名、函数名、枚举值：`lowerCamelCase`
- 常量：使用 `let` 优先，命名采用 `lowerCamelCase`
- 全局常量：使用 `enum` 包装，如 `enum Constants { static let maxRetryCount = 3 }`

### 代码结构
- 文件头：先 import，再声明类/结构体
- MARK: 使用 `// MARK: -` 进行代码分段，例如：`// MARK: - Lifecycle`、`// MARK: - Public Methods`、`// MARK: - Private Methods`
- 属性顺序：`@Published` / `@State` 等属性包装器优先，其次是普通属性

### Swift 特性
- 优先使用 `guard let` 进行早期返回，减少嵌套
- 对可选值使用 `if let` 进行安全解包
- 使用 Swift 原生 API（如 `map`、`compactMap`、`filter`）替代循环
- 合理使用 `actor` 进行数据隔离，避免数据竞争
- 使用 `Result` 类型处理异步操作的成功/失败

## 依赖库
- 网络请求：`Alamofire`
- 自适应布局：`SnapKit`
- 键盘自适应：`IQKeyboardManager`
- 响应式编程：`Combine` (系统原生，优先)
- 持久化：`CoreData`

## 性能与安全
- 主线程只负责 UI 渲染，耗时操作必须放在后台队列
- 使用 `Instruments` 进行内存泄漏检测
- 敏感信息（API Key、密钥）不得写在代码中，使用 `.xcconfig` 管理
- 确保所有 UI 文案支持多语言（使用 `NSLocalizedString`）

## 协同工作提示
- 如果遇到不确定的实现方案，先提出 2-3 个备选方案及优缺点再继续
- 任何网络接口变更，需要同步更新 API 文档或注释
- 代码提交前，确保通过所有单元测试和 UI 测试

## 版本与兼容性
- Swift 版本：5.9+
- Xcode 版本：15.0+
- iOS 最低版本：15.0，需注意 iOS 15/16/17 的 API 差异

##禁用
- 不要打开多个模拟器， 所有的测试都在一个模拟器中完成。
- SwiftUI
