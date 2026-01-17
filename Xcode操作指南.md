# Xcode 操作指南

## ✅ 已修复的问题

### 问题：输入 hello 回复"错误：模型未加载"

**原因**：
1. `ChatMateApp.swift` 中没有调用 `initialize(modelPath:)` 
2. `ChatView` 创建了新的 ViewModel 实例，而不是使用全局的

**修复方案**：

#### 1. 在 `ChatMateApp.swift` 中初始化模型

```swift
@main
struct ChatMateApp: App {
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some Scene {
        WindowGroup {
            ChatView()
                .environmentObject(chatViewModel)
                .task {
                    let modelPath = "/Users/yinlu/Downloads/ChatMate-Models/qwen2.5-1.5b-instruct-q4_k_m.gguf"
                    
                    if FileManager.default.fileExists(atPath: modelPath) {
                        print("找到模型文件: \(modelPath)")
                        await chatViewModel.initialize(modelPath: modelPath)
                    } else {
                        print("❌ 模型文件不存在: \(modelPath)")
                    }
                }
        }
    }
}
```

#### 2. 修改 `ChatView` 使用 `@EnvironmentObject`

```swift
struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel  // 改为 @EnvironmentObject
    
    // 移除了 .task { await viewModel.initialize(modelPath: "") }
}
```

---

## 🚀 现在可以测试了

### 1. 确认模型文件存在

在终端执行：
```bash
ls -lh /Users/yinlu/Downloads/ChatMate-Models/qwen2.5-1.5b-instruct-q4_k_m.gguf
```

如果文件不存在，需要先下载模型（参考 `接下来要做的.md`）。

### 2. 编译运行

在 Xcode 中：
1. 选择模拟器：`iPhone 15 Pro`
2. 按 `⌘ + R` 运行

### 3. 查看日志

打开 Xcode 底部的控制台，应该能看到：
```
找到模型文件: /Users/yinlu/Downloads/ChatMate-Models/qwen2.5-1.5b-instruct-q4_k_m.gguf
开始加载模型: ...
模型加载成功: ...
```

### 4. 测试对话

- 输入 "hello"
- 应该能看到 AI 回复，而不是"错误：模型未加载"

---

## 📝 模型路径配置

### 当前使用的是绝对路径（测试用）

```swift
let modelPath = "/Users/yinlu/Downloads/ChatMate-Models/qwen2.5-1.5b-instruct-q4_k_m.gguf"
```

### 后续要改为 Bundle 中的路径（正式发布）

当你将模型文件添加到 Xcode 项目后：

```swift
if let modelPath = Bundle.main.path(forResource: "qwen2.5-1.5b-instruct-q4_k_m", ofType: "gguf") {
    await chatViewModel.initialize(modelPath: modelPath)
} else {
    print("❌ 模型文件未打包到 App Bundle 中")
}
```

---

## 🔧 调试技巧

### 1. 查看模型加载状态

添加日志到 `LLMService.swift`：

```swift
func loadModel(path: String) async throws {
    state = .loading
    loadProgress = 0.0
    
    print("🔄 开始加载模型: \(path)")
    print("📁 文件存在: \(FileManager.default.fileExists(atPath: path))")
    
    // ...
    
    print("✅ 模型加载成功: \(modelInfo)")
}
```

### 2. 监控 LLM 服务状态

在 `ChatView` 中添加状态显示：

```swift
.overlay(alignment: .top) {
    if case .loading = viewModel.llmService.state {
        ProgressView("加载模型中...")
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
    }
}
```

---

## ⚠️ 常见问题

### Q: 为什么使用 @EnvironmentObject？

**A**: 因为模型加载是在 App 层完成的，需要在整个应用中共享同一个 ViewModel 实例。

### Q: 模型加载需要多久？

**A**: 取决于模型大小和设备性能：
- **1.5B 模型 Q4 量化**：约 1-3 秒
- **7B 模型 Q4 量化**：约 10-30 秒

### Q: 如何判断模型加载成功？

**A**: 看控制台日志：
- ✅ "模型加载成功: ..."
- ✅ 欢迎消息自动出现

### Q: 还是显示"错误：模型未加载"？

**A**: 检查：
1. 模型文件路径是否正确
2. 控制台是否有错误信息
3. `llamaContext` 是否为 `nil`（在 `performGeneration` 中打断点）

---

## 🎯 下一步

1. **测试基本对话功能**
   - 能否正常发送消息
   - 能否流式接收回复
   
2. **测试中文对话**
   - Qwen 模型支持中文

3. **测试长对话**
   - 上下文是否正常累积

4. **优化 UI**
   - 添加加载进度条
   - 添加错误提示

---

## 📚 相关文档

- `接下来要做的.md` - 整体任务清单
- `使用预编译XCFramework.md` - llama.cpp 集成方案
- `API变更说明.md` - llama.cpp API 变更记录
